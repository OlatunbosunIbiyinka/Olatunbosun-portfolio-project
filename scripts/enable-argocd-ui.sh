#!/usr/bin/env bash
# Expose Argo CD UI at https://argocd.olatunbosun.dev with IP allowlisting (ops VM).
# Prereqs: ingress-nginx, cert-manager, ClusterIssuer, Argo CD installed.
#
# Usage (from your laptop, find your public IP first):
#   curl -s ifconfig.me
# Then on the ops VM:
#   bash scripts/enable-argocd-ui.sh 203.0.113.50
#   bash scripts/enable-argocd-ui.sh 203.0.113.50 198.51.100.10   # multiple IPs
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INGRESS_NAME="argocd-server-ingress"
NAMESPACE="argocd"
CERT_NAME="argocd-olatunbosun-dev-tls"
WHITELIST_ANNOTATION="nginx.ingress.kubernetes.io/whitelist-source-range"

usage() {
  echo "Usage: $0 <your-public-ip> [more-ips...]"
  echo ""
  echo "Find your public IP from your laptop (not the VM):"
  echo "  curl -s ifconfig.me"
  exit 1
}

validate_ipv4() {
  local ip="$1"
  if [[ ! "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
    echo "Error: invalid IPv4 address: $ip" >&2
    exit 1
  fi
}

build_cidr_list() {
  local cidr="" ip
  for ip in "$@"; do
    validate_ipv4 "$ip"
    if [[ -n "$cidr" ]]; then
      cidr+=","
    fi
    cidr+="${ip}/32"
  done
  echo "$cidr"
}

[[ $# -ge 1 ]] || usage
ALLOWED_CIDR="$(build_cidr_list "$@")"

echo "==> Enabling server.insecure (TLS terminates at ingress)"
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment/argocd-server -n argocd --timeout=180s

echo "==> Applying Argo CD ingress (no IP lock yet — Let's Encrypt HTTP-01 needs open access)"
kubectl apply -f "${REPO_ROOT}/gitops/platform/argocd-ingress.yaml"

echo "==> Waiting for TLS certificate (required before IP allowlist)"
if ! kubectl wait --for=condition=Ready "certificate/${CERT_NAME}" -n "${NAMESPACE}" --timeout=600s 2>/dev/null; then
  echo "Certificate not Ready yet. Check:"
  echo "  kubectl describe certificate ${CERT_NAME} -n ${NAMESPACE}"
  echo "  kubectl get challenges -A"
  exit 1
fi

echo "==> Locking UI to allowed IPs: ${ALLOWED_CIDR}"
kubectl annotate ingress "${INGRESS_NAME}" -n "${NAMESPACE}" \
  "${WHITELIST_ANNOTATION}=${ALLOWED_CIDR}" --overwrite

INGRESS_IP="$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
echo ""
echo "==> Porkbun DNS A record (if not already set)"
echo "    Host: argocd"
echo "    Answer: ${INGRESS_IP:-<kubectl get svc -n ingress-nginx ingress-nginx-controller>}"
echo ""
echo "==> Allowed client IPs: $*"
echo "    Others receive HTTP 403 from ingress-nginx."
echo ""
echo "==> Admin password"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "(secret not found)"
echo ""
kubectl get ingress,certificate -n argocd
