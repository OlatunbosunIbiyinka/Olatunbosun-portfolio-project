#!/usr/bin/env bash
# Stage 2 (ops VM): AKS + VM cluster RBAC. Run via Bastion after stage 1.
#
# Run with (do NOT rely on ./ if you see "Permission denied"):
#   bash scripts/bootstrap-stage2-from-vm.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/infra/terraform"
RG="${RG:-ola-rg-dev}"
AKS="${AKS:-ola-aks-dev}"
VAR_FILE="envs/dev/terraform.tfvars"

log() { printf '[stage2] %s\n' "$*"; }

log "Installing tools (uses sudo — you may be prompted once)..."
bash "${REPO_ROOT}/scripts/setup-phase2-tools.sh"

if ! az account show >/dev/null 2>&1; then
  log "Azure CLI not logged in — run device login..."
  az login --use-device-code
fi

export KUBECONFIG=""
cd "${TF_DIR}"

log "Terraform init (remote state via Azure AD)..."
terraform init -upgrade

AKS_ID=$(az aks show -g "$RG" -n "$AKS" --query id -o tsv 2>/dev/null || true)
AKS_STATE=$(az aks show -g "$RG" -n "$AKS" --query provisioningState -o tsv 2>/dev/null || true)

if [[ -n "$AKS_ID" && "$AKS_STATE" == "Creating" ]]; then
  log "AKS still Creating in Azure — waiting for Succeeded (up to 3h)..."
  for _ in $(seq 1 180); do
    AKS_STATE=$(az aks show -g "$RG" -n "$AKS" --query provisioningState -o tsv)
    [[ "$AKS_STATE" == "Succeeded" ]] && break
    [[ "$AKS_STATE" == "Failed" ]] && { log "AKS Failed — delete in Portal and re-run"; exit 1; }
    sleep 60
  done
fi

if [[ -n "$AKS_ID" ]] && ! terraform state list 2>/dev/null | grep -q 'module.aks.azurerm_kubernetes_cluster.aks'; then
  log "Importing existing AKS into Terraform state..."
  terraform import -var-file="$VAR_FILE" \
    -var="enable_argocd=false" -var="enable_aks_monitoring_addon=false" \
    "module.aks.azurerm_kubernetes_cluster.aks" "$AKS_ID"
fi

if [[ -z "$AKS_ID" ]]; then
  log "Creating AKS (expect 2–6h on ops VM)..."
  terraform apply -var-file="$VAR_FILE" \
    -var="enable_argocd=false" -var="enable_aks_monitoring_addon=false" \
    -target="module.aks" \
    -target="azurerm_user_assigned_identity.workload_identity" \
    -target="azurerm_role_assignment.workload_identity_keyvault_secrets_user" \
    -auto-approve
  AKS_ID=$(az aks show -g "$RG" -n "$AKS" --query id -o tsv)
fi

log "Finishing stack (VM AKS RBAC, node pool, federated identity)..."
terraform apply \
  -var-file="$VAR_FILE" \
  -var="enable_argocd=false" \
  -var="enable_aks_monitoring_addon=false" \
  -var="jumpbox_aks_cluster_id=${AKS_ID}" \
  -auto-approve

log "Stage 2 done. Next: bash scripts/phase2-on-vm.sh"
