#!/usr/bin/env bash
# Apply stable-platform phases incrementally (ops VM only).
#
#   bash scripts/stable-phase-apply.sh plan 1
#   bash scripts/stable-phase-apply.sh apply 1
#   bash scripts/stable-phase-apply.sh apply 2   # cumulative: phases 1+2
#
# Phases already live from bootstrap/phase2 (skip): Argo CD, monitoring if enabled.
# Order: 1 workload pool → 2 policy → 3 NAT → 4 Cilium → 5 monitoring addon
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${REPO_ROOT}/infra/terraform"
STABLE="${TF_DIR}/envs/dev/stable"
VAR_FILE="${TF_DIR}/envs/dev/terraform.tfvars"
RG="${RG:-ola-rg-dev}"
AKS="${AKS:-ola-aks-dev}"
ACTION="${1:-plan}"
PHASE="${2:-}"

log() { printf '[stable-phase] %s\n' "$*"; }
die() { log "ERROR: $*"; exit 1; }

[[ "$ACTION" == "plan" || "$ACTION" == "apply" ]] || die "Usage: bash scripts/stable-phase-apply.sh [plan|apply] <1-5>"
[[ "$PHASE" =~ ^[1-5]$ ]] || die "Phase must be 1-5"

export KUBECONFIG=""
cd "${TF_DIR}"

STATE=$(az aks show -g "$RG" -n "$AKS" --query provisioningState -o tsv 2>/dev/null || echo "Missing")
[[ "$STATE" == "Succeeded" ]] || die "AKS must be Succeeded (current: $STATE)"

[[ -f "$VAR_FILE" ]] || die "Missing $VAR_FILE — cp envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars"

AKS_ID=$(az aks show -g "$RG" -n "$AKS" --query id -o tsv)

PHASE_FILES=(
  "$STABLE/phase1-workload-pool.tfvars"
  "$STABLE/phase2-azure-policy.tfvars"
  "$STABLE/phase3-nat-gateway.tfvars"
  "$STABLE/phase4-cilium.tfvars"
  "$STABLE/phase5-monitoring.tfvars"
)

VAR_ARGS=(-var-file="$VAR_FILE")
for ((i = 0; i < PHASE; i++)); do
  [[ -f "${PHASE_FILES[$i]}" ]] || die "Missing ${PHASE_FILES[$i]}"
  VAR_ARGS+=(-var-file="${PHASE_FILES[$i]}")
done

# Keep live GitOps/monitoring flags unless phase files override
VAR_ARGS+=(
  -var="jumpbox_aks_cluster_id=${AKS_ID}"
  -var="enable_argocd=true"
)

log "Phase ${PHASE} — ${ACTION} (cumulative through phase ${PHASE})"
log "Var files: terraform.tfvars + stable/phase1..phase${PHASE}"

terraform init -upgrade

if [[ "$ACTION" == "plan" ]]; then
  terraform plan "${VAR_ARGS[@]}"
else
  log "Use tmux for phases 3–4 (NAT/Cilium can take 30–90+ min)"
  terraform apply "${VAR_ARGS[@]}" -auto-approve
  log "Verify:"
  log "  kubectl get nodes"
  log "  kubectl get pods -A | grep -v Running || true"
  log "  kubectl get application portfolio-app -n argocd"
fi
