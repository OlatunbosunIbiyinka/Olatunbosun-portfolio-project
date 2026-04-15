#!/usr/bin/env bash

# Idempotent Phase 2 tool bootstrap for Operations VM
# Installs/verifies: az, kubectl, kubelogin, helm, terraform, docker, jq, unzip, git
# Safe defaults: only installs missing tools; does not remove existing configuration.
#
# Usage:
#   ./scripts/setup-phase2-tools.sh
#   INSTALL_DOCKER=false ./scripts/setup-phase2-tools.sh

set -euo pipefail

INSTALL_AZ_CLI="${INSTALL_AZ_CLI:-true}"
INSTALL_KUBECTL="${INSTALL_KUBECTL:-true}"
INSTALL_KUBELOGIN="${INSTALL_KUBELOGIN:-true}"
INSTALL_HELM="${INSTALL_HELM:-true}"
INSTALL_TERRAFORM="${INSTALL_TERRAFORM:-true}"
INSTALL_DOCKER="${INSTALL_DOCKER:-true}"

TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.8.5}"
KUBELOGIN_VERSION="${KUBELOGIN_VERSION:-v0.1.4}"
DOCKER_CHANNEL="${DOCKER_CHANNEL:-stable}"

log() { printf '[phase2-setup] %s\n' "$*"; }
warn() { printf '[phase2-setup][WARN] %s\n' "$*" >&2; }

require_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    echo "Unsupported OS: /etc/os-release not found." >&2
    exit 1
  fi
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "Unsupported distro: ${ID:-unknown}. This script currently supports Ubuntu only." >&2
    exit 1
  fi
}

wait_for_apt_lock() {
  local timeout=180
  local elapsed=0
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
        sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    if (( elapsed >= timeout )); then
      echo "Timed out waiting for apt locks." >&2
      exit 1
    fi
    sleep 3
    elapsed=$((elapsed + 3))
  done
}

apt_update_once() {
  if [[ "${_APT_UPDATED:-false}" != "true" ]]; then
    wait_for_apt_lock
    sudo apt-get update -y
    _APT_UPDATED=true
  fi
}

ensure_pkg() {
  local pkg="$1"
  if dpkg -s "${pkg}" >/dev/null 2>&1; then
    return 0
  fi
  apt_update_once
  wait_for_apt_lock
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkg}"
}

ensure_base_packages() {
  log "Ensuring base packages..."
  ensure_pkg ca-certificates
  ensure_pkg curl
  ensure_pkg gnupg
  ensure_pkg lsb-release
  ensure_pkg unzip
  ensure_pkg jq
  ensure_pkg git
  ensure_pkg apt-transport-https
}

install_az_cli() {
  if command -v az >/dev/null 2>&1; then
    log "Azure CLI already installed: $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo unknown)"
    return
  fi
  log "Installing Azure CLI..."
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  log "Azure CLI installed."
}

install_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null || echo unknown)"
    return
  fi
  log "Installing kubectl..."
  local version
  version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
  log "kubectl installed (${version})."
}

install_kubelogin() {
  if command -v kubelogin >/dev/null 2>&1; then
    log "kubelogin already installed: $(kubelogin --version 2>/dev/null || echo unknown)"
    return
  fi
  log "Installing kubelogin ${KUBELOGIN_VERSION}..."
  local zip="/tmp/kubelogin.zip"
  local extract_dir="/tmp/kubelogin-extract"
  rm -rf "${extract_dir}" "${zip}"
  curl -fsSLo "${zip}" "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip"
  unzip -q "${zip}" -d "${extract_dir}"
  sudo install -o root -g root -m 0755 "${extract_dir}/bin/linux_amd64/kubelogin" /usr/local/bin/kubelogin
  rm -rf "${extract_dir}" "${zip}"
  log "kubelogin installed."
}

install_helm() {
  if command -v helm >/dev/null 2>&1; then
    log "Helm already installed: $(helm version --short 2>/dev/null || echo unknown)"
    return
  fi
  log "Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  log "Helm installed."
}

install_terraform() {
  if command -v terraform >/dev/null 2>&1; then
    log "Terraform already installed: $(terraform version -json 2>/dev/null | jq -r .terraform_version 2>/dev/null || terraform version | head -n1)"
    return
  fi
  log "Installing Terraform ${TERRAFORM_VERSION}..."
  local zip="/tmp/terraform.zip"
  curl -fsSLo "${zip}" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
  sudo unzip -o "${zip}" -d /usr/local/bin >/dev/null
  rm -f "${zip}"
  log "Terraform installed."
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
  else
    log "Installing Docker..."
    ensure_base_packages
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    # shellcheck disable=SC1091
    source /etc/os-release
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} ${DOCKER_CHANNEL}" \
      | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt_update_once
    wait_for_apt_lock
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    log "Docker installed."
  fi

  log "Ensuring Docker service/socket are enabled..."
  sudo systemctl enable docker.socket >/dev/null 2>&1 || true
  sudo systemctl enable docker >/dev/null 2>&1 || true
  sudo systemctl start docker.socket || true
  sudo systemctl start docker || true

  if ! groups "$USER" | grep -q '\bdocker\b'; then
    sudo usermod -aG docker "$USER" || true
    warn "Added $USER to docker group. Re-login is required for docker (non-sudo) commands."
  fi
}

print_summary() {
  echo
  log "Summary:"
  command -v az >/dev/null 2>&1 && log "  az:        $(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo installed)"
  command -v kubectl >/dev/null 2>&1 && log "  kubectl:   $(kubectl version --client --short 2>/dev/null || echo installed)"
  command -v kubelogin >/dev/null 2>&1 && log "  kubelogin: $(kubelogin --version 2>/dev/null || echo installed)"
  command -v helm >/dev/null 2>&1 && log "  helm:      $(helm version --short 2>/dev/null || echo installed)"
  command -v terraform >/dev/null 2>&1 && log "  terraform: $(terraform version | head -n1)"
  command -v docker >/dev/null 2>&1 && log "  docker:    $(docker --version 2>/dev/null || echo installed)"
  echo
  log "Next steps:"
  log "  1) Re-login if docker group was newly added."
  log "  2) Run: az login"
  log "  3) Run: git pull"
}

main() {
  require_ubuntu
  ensure_base_packages

  [[ "${INSTALL_AZ_CLI}" == "true" ]] && install_az_cli
  [[ "${INSTALL_KUBECTL}" == "true" ]] && install_kubectl
  [[ "${INSTALL_KUBELOGIN}" == "true" ]] && install_kubelogin
  [[ "${INSTALL_HELM}" == "true" ]] && install_helm
  [[ "${INSTALL_TERRAFORM}" == "true" ]] && install_terraform
  [[ "${INSTALL_DOCKER}" == "true" ]] && install_docker

  print_summary
}

main "$@"
