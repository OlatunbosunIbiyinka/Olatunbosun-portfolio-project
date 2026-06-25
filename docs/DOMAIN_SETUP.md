# Domain setup — olatunbosun.dev

Guide to expose the portfolio on **https://olatunbosun.dev** using Porkbun DNS, NGINX Ingress, and cert-manager (Let's Encrypt).

**Domain registrar:** Porkbun  
**GitOps path:** `gitops/apps/portfolio-app/` (Ingress + network policy)  
**Cluster bootstrap:** `gitops/platform/cluster-issuer.yaml`

---

## Before you start

| Requirement | Notes |
|-------------|--------|
| Ops VM running | Bastion → ops VM with `kubectl` and cluster access |
| App deployed | Argo CD synced `portfolio-app` (pods healthy) |
| Git pushed | Ingress manifests committed to `main` (see commit guide in repo README or team docs) |
| Porkbun account | Domain **olatunbosun.dev** registered |

**VM not up yet?** You can still commit GitOps manifests and buy/configure the domain. Wait to point Porkbun DNS until Ingress has a public IP.

---

## Overview

```
Internet → Porkbun DNS (A record) → Azure LB (ingress-nginx)
         → Ingress (olatunbosun.dev) → Service ola-portfolio-app:80 → pods :8080
         → TLS via cert-manager + Let's Encrypt
```

---

## Phase 1 — Install NGINX Ingress Controller (ops VM)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

Wait for external IP:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

Record **EXTERNAL-IP** (e.g. `20.x.x.x`) — you need this for Porkbun.

---

## Phase 2 — Install cert-manager (ops VM)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

Verify:

```bash
kubectl get pods -n cert-manager
```

---

## Phase 3 — Create Let's Encrypt ClusterIssuer (ops VM)

From the repo root on the ops VM:

```bash
kubectl apply -f gitops/platform/cluster-issuer.yaml
kubectl get clusterissuer letsencrypt-prod
```

Expected: `READY=True` (may take a minute).

---

## Phase 4 — Deploy Ingress via GitOps

Ensure `gitops/apps/portfolio-app/ingress.yaml` and `networkpolicy-ingress.yaml` are on `main`.

Argo CD should sync automatically. Or manually:

```bash
kubectl apply -f gitops/apps/portfolio-app/ingress.yaml
kubectl apply -f gitops/apps/portfolio-app/networkpolicy-ingress.yaml
```

Check:

```bash
kubectl get ingress -n portfolio-app
kubectl describe ingress ola-portfolio-app-ingress -n portfolio-app
kubectl get certificate -n portfolio-app
```

Certificate `olatunbosun-dev-tls` should become `Ready=True` after DNS points to the cluster (Phase 5).

---

## Phase 5 — Porkbun DNS

1. Log in to [porkbun.com](https://porkbun.com) → **Domain Management** → **olatunbosun.dev**
2. Open **DNS Records**
3. Add:

| Type | Host | Answer | TTL |
|------|------|--------|-----|
| **A** | `@` (root / blank) | `<EXTERNAL-IP from Phase 1>` | 300 |
| **A** | `www` | `<same EXTERNAL-IP>` | 300 |

4. Remove conflicting A/CNAME records for `@` or `www` if present
5. Wait 5–30 minutes for propagation

Check DNS from your laptop:

```bash
nslookup olatunbosun.dev
dig olatunbosun.dev +short
```

---

## Phase 6 — Verify HTTPS

```bash
curl -I https://olatunbosun.dev
curl -I https://olatunbosun.dev/health
```

Browser: open **https://olatunbosun.dev**

Update public links:

- LinkedIn website field
- GitHub repo **About** → Website
- CV portfolio URL

---

## Troubleshooting

### Certificate stuck on `Pending`

- DNS must resolve to the Ingress LB IP before HTTP-01 challenge succeeds
- Check cert-manager logs:

```bash
kubectl logs -n cert-manager -l app=cert-manager --tail=50
kubectl describe certificate olatunbosun-dev-tls -n portfolio-app
```

### 502 / 503 from Ingress

- Pods healthy: `kubectl get pods -n portfolio-app`
- Service endpoints: `kubectl get endpoints ola-portfolio-app -n portfolio-app`
- Network policy: ensure `allow-ingress-to-portfolio` exists

### Connection timeout

- Confirm LB has public IP: `kubectl get svc -n ingress-nginx`
- Confirm Porkbun A record matches that IP
- NSG / Azure firewall must allow 80 and 443 to the LB (default for public LB)

### `.dev` requires HTTPS

Browsers enforce HSTS on `.dev` TLD. HTTP-only will not work — TLS must be valid.

---

## Files in this repo

| File | Purpose |
|------|---------|
| `gitops/apps/portfolio-app/ingress.yaml` | Host rules + TLS for olatunbosun.dev |
| `gitops/apps/portfolio-app/networkpolicy-ingress.yaml` | Allow ingress-nginx → app pods |
| `gitops/platform/cluster-issuer.yaml` | Let's Encrypt production issuer |
| `app/public/index.html` | `og:url` → https://olatunbosun.dev |

---

## Order of operations (checklist)

```
[ ] Commit and push GitOps + app changes to main
[ ] CI builds and deploys latest image via Argo CD
[ ] Ops VM up — kubectl works
[ ] Install ingress-nginx → note EXTERNAL-IP
[ ] Install cert-manager
[ ] kubectl apply -f gitops/platform/cluster-issuer.yaml
[ ] Argo syncs ingress + network policy (or kubectl apply)
[ ] Porkbun A records → EXTERNAL-IP
[ ] Wait for certificate Ready
[ ] Test https://olatunbosun.dev
[ ] Update CV / LinkedIn / GitHub
```
