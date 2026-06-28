#!/usr/bin/env bash
# Phase 2 — run on aks-operations-vm (via Bastion) after Phase 1 succeeds.
# Enables Container Insights, Argo CD, kubectl access, and registers the GitOps app.
#
# Usage:
#   ./scripts/phase2-on-vm.sh
#   SKIP_ARGOCD_APP=true ./scripts/phase2-on-vm.sh   # only terraform phase 2

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/infra/terraform"
RG="${RG:-ola-rg-dev}"
AKS="${AKS:-ola-aks-dev}"
SKIP_ARGOCD_APP="${SKIP_ARGOCD_APP:-false}"

log() { printf '[phase2] %s\n' "$*"; }

log "Installing ops tools (idempotent)..."
bash "${REPO_ROOT}/scripts/setup-phase2-tools.sh"

log "Azure login (use your account or VM identity)"
if ! az account show >/dev/null 2>&1; then
  az login
fi

export KUBECONFIG="${KUBECONFIG:-}"
unset KUBECONFIG

log "Terraform Phase 2: monitoring addon + Argo CD"
cd "${TF_DIR}"
terraform init -upgrade
terraform apply \
  -var-file="envs/dev/terraform.tfvars" \
  -var="enable_argocd=true" \
  -var="enable_aks_monitoring_addon=true" \
  -auto-approve

log "kubectl credentials"
az aks get-credentials --resource-group "${RG}" --name "${AKS}" --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

log "Cluster health"
kubectl get nodes
kubectl -n argocd wait --for=condition=available deployment/argocd-server --timeout=600s 2>/dev/null || true

if [[ "${SKIP_ARGOCD_APP}" != "true" ]]; then
  log "Register Argo CD application"
  kubectl apply -f "${REPO_ROOT}/gitops/apps/portfolio-app.yaml"
  kubectl apply -f "${REPO_ROOT}/gitops/platform/cluster-issuer.yaml" 2>/dev/null || true
fi

log "Phase 2 complete."
log "Next:"
log "  1. terraform output github_oidc_client_id  → GitHub secret AZURE_CLIENT_ID"
log "  2. Install self-hosted runner: ./scripts/install-github-runner.sh"
log "  3. Push app/ change to trigger CI build → ACR → GitOps deploy"
log "  4. Point olatunbosun.dev DNS after Ingress LB IP (see docs/DOMAIN_SETUP.md)"
