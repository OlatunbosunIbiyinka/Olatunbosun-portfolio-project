#!/usr/bin/env bash
# Stage 2 (ops VM): bootstrap-minimal AKS + finish stack.
# Defers NAT/UDR, Cilium, policy, monitoring, Argo until stable (see tfvars example).
#
#   tmux new -s tf
#   bash scripts/bootstrap-stage2-from-vm.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/infra/terraform"
RG="${RG:-ola-rg-dev}"
AKS="${AKS:-ola-aks-dev}"
VAR_FILE="envs/dev/terraform.tfvars"
EXAMPLE="${TF_DIR}/envs/dev/terraform.tfvars.example"

log() { printf '[stage2] %s\n' "$*"; }

if [[ ! -f "$VAR_FILE" ]]; then
  log "Creating $VAR_FILE from bootstrap example..."
  cp "$EXAMPLE" "$VAR_FILE"
fi

log "Bootstrap settings (must show nat=false, policy=azure, k8s=1.31.9):"
grep -E 'kubernetes_version|enable_nat_gateway|network_policy|network_dataplane|workload_node_pools|enable_azure_policy|enable_aks_monitoring_addon|enable_argocd' "$VAR_FILE" || true

log "Installing tools..."
bash "${REPO_ROOT}/scripts/setup-phase2-tools.sh"

if ! az account show >/dev/null 2>&1; then
  log "Azure CLI not logged in — device code login..."
  az login --use-device-code
fi

export KUBECONFIG=""
cd "${TF_DIR}"
terraform init -upgrade

AKS_STATE=$(az aks show -g "$RG" -n "$AKS" --query provisioningState -o tsv 2>/dev/null || echo "Missing")
AKS_ID=$(az aks show -g "$RG" -n "$AKS" --query id -o tsv 2>/dev/null || true)

if [[ "$AKS_STATE" == "Failed" ]]; then
  log "AKS Failed — deleting and clearing Terraform state..."
  az aks delete -g "$RG" -n "$AKS" --yes --no-wait
  for _ in $(seq 1 60); do
    az aks show -g "$RG" -n "$AKS" >/dev/null 2>&1 || break
    sleep 30
  done
  terraform state list 2>/dev/null | grep '^module\.aks\.' | while read -r r; do
    terraform state rm "$r"
  done || true
  AKS_ID=""
  AKS_STATE="Missing"
fi

if [[ "$AKS_STATE" == "Creating" ]]; then
  log "AKS still Creating — waiting for Succeeded (up to 3h)..."
  for _ in $(seq 1 180); do
    AKS_STATE=$(az aks show -g "$RG" -n "$AKS" --query provisioningState -o tsv)
    [[ "$AKS_STATE" == "Succeeded" ]] && break
    [[ "$AKS_STATE" == "Failed" ]] && { log "AKS Failed during wait — re-run this script"; exit 1; }
    sleep 60
  done
  AKS_ID=$(az aks show -g "$RG" -n "$AKS" --query id -o tsv)
fi

if [[ -n "$AKS_ID" ]] && ! terraform state list 2>/dev/null | grep -q 'module.aks.azurerm_kubernetes_cluster.aks'; then
  log "Importing AKS into Terraform state..."
  terraform import -var-file="$VAR_FILE" \
    -var="enable_argocd=false" -var="enable_aks_monitoring_addon=false" \
    "module.aks.azurerm_kubernetes_cluster.aks" "$AKS_ID"
fi

APPLY_COMMON=(-var-file="$VAR_FILE" -var="enable_argocd=false" -var="enable_aks_monitoring_addon=false")

if [[ -z "$AKS_ID" ]]; then
  log "Creating AKS (bootstrap: no NAT/UDR, azure network policy, ~1–4h)..."
  terraform apply "${APPLY_COMMON[@]}" \
    -target="module.vnet" \
    -target="module.aks" \
    -target="azurerm_user_assigned_identity.workload_identity" \
    -target="azurerm_role_assignment.workload_identity_keyvault_secrets_user" \
    -auto-approve
  AKS_ID=$(az aks show -g "$RG" -n "$AKS" --query id -o tsv)
fi

log "Finishing stack (VM AKS RBAC, remaining resources)..."
terraform apply "${APPLY_COMMON[@]}" -var="jumpbox_aks_cluster_id=${AKS_ID}" -auto-approve

log "Bootstrap AKS done."
log "Verify: az aks show -g $RG -n $AKS --query provisioningState -o tsv"
log "Then enable stable features one phase at a time — see envs/dev/terraform.tfvars.example"
log "Or GitOps only: bash scripts/phase2-on-vm.sh"
