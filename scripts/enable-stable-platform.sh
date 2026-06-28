#!/usr/bin/env bash
# Re-enable deferred enterprise features after bootstrap AKS is Succeeded.
# Edit envs/dev/terraform.tfvars per phase (see comments in terraform.tfvars.example),
# then run: bash scripts/enable-stable-platform.sh [phase]
#
# Phases: 1=workload-pool  2=azure-policy  3=nat  4=cilium  5=monitoring  6=argocd  all=plan-only
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/infra/terraform"
RG="${RG:-ola-rg-dev}"
AKS="${AKS:-ola-aks-dev}"
VAR_FILE="${TF_DIR}/envs/dev/terraform.tfvars"
PHASE="${1:-plan}"

log() { printf '[stable] %s\n' "$*"; }

export KUBECONFIG=""
cd "${TF_DIR}"

STATE=$(az aks show -g "$RG" -n "$AKS" --query provisioningState -o tsv 2>/dev/null || echo "Missing")
if [[ "$STATE" != "Succeeded" ]]; then
  log "AKS must be Succeeded (current: $STATE). Finish bootstrap first."
  exit 1
fi

AKS_ID=$(az aks show -g "$RG" -n "$AKS" --query id -o tsv)
APPLY=(terraform apply -var-file="$VAR_FILE" -var="jumpbox_aks_cluster_id=$AKS_ID")

case "$PHASE" in
  plan)
    log "Dry run — showing pending changes. Uncomment ONE phase block in $VAR_FILE, then:"
    log "  bash scripts/enable-stable-platform.sh apply"
    terraform plan -var-file="$VAR_FILE" -var="jumpbox_aks_cluster_id=$AKS_ID"
    ;;
  apply)
    log "Applying stable-platform changes from $VAR_FILE ..."
    "${APPLY[@]}" -auto-approve
    log "Verify: kubectl get nodes (from ops VM after az aks get-credentials)"
    ;;
  6|argocd)
    log "Enabling Argo CD + monitoring via phase2 script..."
    bash "${REPO_ROOT}/scripts/phase2-on-vm.sh"
    ;;
  *)
    log "Usage: bash scripts/enable-stable-platform.sh [plan|apply|6|argocd]"
    log "Phases 1–5: edit terraform.tfvars, then run with 'apply'"
    exit 1
    ;;
esac
