#!/usr/bin/env bash
# Install and register a GitHub Actions self-hosted runner on the ops VM (VNet).
# The runner executes CI jobs that need private ACR access; jobs still use GitHub OIDC for Azure.
#
# Prerequisites:
#   - Ubuntu ops VM with outbound HTTPS to github.com
#   - Docker installed (./scripts/setup-phase2-tools.sh with INSTALL_DOCKER=true)
#   - Registration token from GitHub: Repo → Settings → Actions → Runners → New self-hosted runner
#
# Usage:
#   export GITHUB_RUNNER_TOKEN='paste-one-time-token'
#   ./scripts/install-github-runner.sh
#
# Optional:
#   GITHUB_REPO_URL=https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project
#   RUNNER_NAME=aks-operations-vm
#   RUNNER_LABELS=self-hosted,linux,vnet,aks-ops
#   RUNNER_VERSION=v2.323.0

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITHUB_REPO_URL="${GITHUB_REPO_URL:-https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project}"
RUNNER_USER="${RUNNER_USER:-$(whoami)}"
RUNNER_NAME="${RUNNER_NAME:-aks-operations-vm}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,vnet,aks-ops}"
RUNNER_VERSION="${RUNNER_VERSION:-v2.323.0}"
RUNNER_DIR="${RUNNER_DIR:-/home/${RUNNER_USER}/actions-runner}"

log() { printf '[github-runner] %s\n' "$*"; }
die() { printf '[github-runner][ERROR] %s\n' "$*" >&2; exit 1; }

[[ -n "${GITHUB_RUNNER_TOKEN:-}" ]] || die "Set GITHUB_RUNNER_TOKEN (one-time token from GitHub repo settings)."

command -v docker >/dev/null 2>&1 || die "Docker not found. Run: INSTALL_DOCKER=true ./scripts/setup-phase2-tools.sh"

if ! docker ps >/dev/null 2>&1; then
  die "Docker not usable by ${RUNNER_USER}. Add user to docker group and re-login, or fix docker.service."
fi

VERSION_NO_V="${RUNNER_VERSION#v}"
ARCH="x64"
OS="linux"
TARBALL="actions-runner-${OS}-${ARCH}-${VERSION_NO_V}.tar.gz"

log "Installing runner for ${GITHUB_REPO_URL}"
log "Runner user: ${RUNNER_USER}"
log "Runner dir:  ${RUNNER_DIR}"

sudo mkdir -p "${RUNNER_DIR}"
sudo chown "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

if [[ ! -f ./config.sh ]]; then
  curl -fsSL -o "${TARBALL}" \
    "https://github.com/actions/runner/releases/download/${RUNNER_VERSION}/${TARBALL}"
  tar xzf "${TARBALL}"
  rm -f "${TARBALL}"
fi

./config.sh \
  --url "${GITHUB_REPO_URL}" \
  --token "${GITHUB_RUNNER_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --unattended \
  --replace

sudo ./svc.sh install "${RUNNER_USER}"
sudo ./svc.sh start
sudo ./svc.sh status || true

log "Runner installed. Verify in GitHub: Settings → Actions → Runners (should show '${RUNNER_NAME}')."
log "Workflow uses: runs-on: self-hosted"
log "CI jobs authenticate to Azure via GitHub OIDC (azure/login@v2), not VM managed identity."
