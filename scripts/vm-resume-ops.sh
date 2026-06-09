#!/usr/bin/env bash
# Resume ops on the jumpbox VM after Bastion reconnect.
# Fixes kubectl Forbidden by aligning Azure CLI identity with kubeconfig.
set -euo pipefail

RG="${RG:-ola-rg-dev}"
AKS="${AKS:-ola-aks-dev}"
ACR="${ACR:-olaacr01dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEBUG_LOG="${DEBUG_LOG:-$REPO_ROOT/debug-917d56.log}"

log_evidence() {
  local hypothesis_id="$1"
  local message="$2"
  local data="$3"
  printf '{"sessionId":"917d56","hypothesisId":"%s","location":"vm-resume-ops.sh","message":"%s","data":%s,"timestamp":%s}\n' \
    "$hypothesis_id" "$message" "$data" "$(date +%s%3N)" >>"$DEBUG_LOG" 2>/dev/null || true
}

echo "=== VM ops resume ==="

CLIENT_ID=""
if curl -sf -H Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" \
  >/tmp/vm-mi-token.json 2>/dev/null; then
  CLIENT_ID=$(jq -r .client_id /tmp/vm-mi-token.json 2>/dev/null || true)
fi

CURRENT_OID=$(az account show --query user.oid -o tsv 2>/dev/null || echo "none")
CURRENT_TYPE=$(az account show --query user.type -o tsv 2>/dev/null || echo "none")
CURRENT_NAME=$(az account show --query user.name -o tsv 2>/dev/null || echo "none")

log_evidence "H1" "azure_cli_identity_before" \
  "$(jq -nc --arg oid "$CURRENT_OID" --arg type "$CURRENT_TYPE" --arg name "$CURRENT_NAME" '{oid:$oid,type:$type,name:$name}')"

echo "Current Azure CLI identity: name=$CURRENT_NAME type=$CURRENT_TYPE oid=$CURRENT_OID"

# Personal user OID from reproduced Forbidden errors — needs AKS Cluster Admin OR must not be used for kubectl
PERSONAL_OID="aada61c4-06b0-49b6-a843-8ff9140fc8a2"

if [[ "$CURRENT_OID" == "$PERSONAL_OID" ]]; then
  echo ""
  echo "WARN: kubectl will use your personal account (no AKS RBAC)."
  echo "FIX (run once from laptop/Cloud Shell):"
  echo "  az role assignment create \\"
  echo "    --assignee \"$PERSONAL_OID\" \\"
  echo "    --role \"Azure Kubernetes Service Cluster Admin Role\" \\"
  echo "    --scope \$(az aks show -g $RG -n $AKS --query id -o tsv)"
  echo ""
  echo "Then on this VM: az login && az aks get-credentials -g $RG -n $AKS --overwrite-existing"
  log_evidence "H2" "personal_user_detected_needs_rbac" "{\"oid\":\"$PERSONAL_OID\"}"
else
  if [[ -n "$CLIENT_ID" && "$CLIENT_ID" != "null" ]]; then
    echo "Switching to VM managed identity..."
    az logout 2>/dev/null || true
    az login --identity --client-id "$CLIENT_ID"
    log_evidence "H3" "managed_identity_login" "{\"client_id\":\"$CLIENT_ID\"}"
  fi
fi

rm -rf "${HOME}/.kube/cache" 2>/dev/null || true
az aks get-credentials --resource-group "$RG" --name "$AKS" --overwrite-existing

KUBECTL_RC=0
kubectl get nodes >/tmp/vm-kubectl-nodes.txt 2>&1 || KUBECTL_RC=$?
KUBECTL_HEAD=$(head -3 /tmp/vm-kubectl-nodes.txt | tr '\n' ' ')

log_evidence "H4" "kubectl_get_nodes_result" \
  "$(jq -nc --argjson rc "$KUBECTL_RC" --arg out "$KUBECTL_HEAD" '{exit_code:$rc,output:$out}')"

echo ""
echo "=== kubectl get nodes ==="
cat /tmp/vm-kubectl-nodes.txt

echo ""
echo "=== Argo CD ==="
kubectl get application -n argocd 2>/dev/null || true

echo ""
echo "=== portfolio-app pods ==="
kubectl get pods -n portfolio-app 2>/dev/null || true

echo ""
echo "=== ACR tags ==="
az acr repository show-tags --name "$ACR" --repository ola-portfolio-app -o table 2>/dev/null || echo "No image in ACR yet"

if [[ "$KUBECTL_RC" -ne 0 ]]; then
  echo ""
  echo "kubectl still failing — grant Cluster Admin to $PERSONAL_OID (command above), wait 5 min, az login, re-run this script."
  exit 1
fi

echo ""
echo "OK — VM ops ready."
