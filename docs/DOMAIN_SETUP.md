# Domain setup — olatunbosun.dev

Guide to expose the portfolio on **https://olatunbosun.dev** using Porkbun DNS, NGINX Ingress, and cert-manager (Let's Encrypt).

**Domain registrar:** Porkbun  
**GitOps path:** `gitops/apps/portfolio-app/` (Ingress + network policy)  
**Cluster bootstrap:** `gitops/platform/cluster-issuer.yaml`

---

## Network context (private platform by default)

This project is **private by default**. Domain setup adds one **controlled public inbound path**; everything else stays on the private platform pattern.

| Path | How it works |
|------|----------------|
| **Cluster & workloads** | Private AKS API; app `ClusterIP`; ACR / Key Vault via **private endpoints** |
| **Outbound (internet)** | AKS subnet uses **`userDefinedRouting` + UDR** → **NAT Gateway** (predictable egress IP) |
| **Inbound (portfolio only)** | **NGINX Ingress** `LoadBalancer` gets a **public IP** — the only intended entry from the internet |
| **Operations** | Bastion → **ops VM** in the VNet (`kubectl`, Helm, Terraform phase 2) — not from a laptop to the private API |

```
                    INBOUND (public, deliberate)
Internet ──DNS──► Ingress LB (public IP) ──► portfolio-app pods

                    OUTBOUND (private platform default)
pods / nodes ──UDR──► NAT Gateway ──► Internet
                         │
                         ├── Let's Encrypt ACME API (cert-manager)
                         ├── Container registries / GitHub (where not private-endpoint)
                         └── Other external dependencies

                    NO public path
Private AKS API · ClusterIP services · ACR/KV private endpoints
```

**Implications for this guide**

- Run **all** `kubectl` / `helm` steps from the **ops VM** (or another VNet-connected host), not your home machine.
- **cert-manager** talks to Let's Encrypt **outbound via NAT**; the **HTTP-01 challenge** is answered **inbound** on the Ingress public IP (port 80).
- Do **not** switch the app Service to `LoadBalancer` — keep `ClusterIP`; only Ingress exposes the site.
- If certificates hang on `Pending`, check **both** Porkbun DNS **and** NAT/UDR egress (cert-manager must reach ACME).

See also: `docs/ARCHITECTURE_AND_INTERVIEW_PRESENTATION.md`, Terraform `outbound_type = userDefinedRouting` when NAT is enabled.

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
Internet → Porkbun DNS (A record) → Azure LB (ingress-nginx public IP)   ← controlled inbound
         → Ingress (olatunbosun.dev) → Service (ClusterIP) → pods :8080
         → TLS via cert-manager + Let's Encrypt (ACME outbound via NAT Gateway)
```

---

## Phase 1 — Install NGINX Ingress Controller (ops VM)

From the **ops VM** (Bastion session). The controller creates an Azure **public** LoadBalancer — the portfolio’s only internet-facing entry point. AKS nodes remain private; outbound from the cluster still uses **NAT Gateway + UDR**.

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

Wait for external IP:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

Record **EXTERNAL-IP** (e.g. `20.x.x.x`) — you need this for Porkbun.

---

## Phase 2 — Install cert-manager (ops VM)

cert-manager pods reach `acme-v02.api.letsencrypt.org` **outbound through the NAT Gateway** (UDR on the AKS subnet). No inbound rule is required for that.

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

- DNS must resolve to the Ingress **public** LB IP before HTTP-01 challenge succeeds (inbound on port 80)
- cert-manager must reach Let's Encrypt **outbound via NAT Gateway** — verify NAT + UDR on `aks-subnet`:

```bash
# From ops VM — NAT egress smoke test (optional)
kubectl run curl-test --rm -it --restart=Never --image=curlimages/curl -- curl -sI https://acme-v02.api.letsencrypt.org/directory
```

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

- Confirm Ingress LB has **public** IP: `kubectl get svc -n ingress-nginx`
- Confirm Porkbun A record matches that IP (not the NAT Gateway egress IP — they are different)
- NSG must allow **inbound** 80/443 to the Ingress LoadBalancer
- Outbound NAT does not replace Ingress; both are required

### Helm / image pull failures on ops VM

- Ops VM and cluster pull charts/images **outbound via NAT**; if NAT or UDR is misconfigured, Helm installs fail before Ingress exists

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
[ ] Ops VM up (Bastion) — kubectl works against private AKS
[ ] Confirm NAT Gateway + UDR on aks-subnet (Terraform default when enable_nat_gateway=true)
[ ] Install ingress-nginx on ops VM → note Ingress EXTERNAL-IP (public — not NAT IP)
[ ] Install cert-manager on ops VM
[ ] kubectl apply -f gitops/platform/cluster-issuer.yaml
[ ] Argo syncs ingress + network policy (app Service stays ClusterIP)
[ ] Porkbun A records → Ingress EXTERNAL-IP
[ ] Wait for certificate Ready (inbound HTTP-01 + outbound ACME via NAT)
[ ] Test https://olatunbosun.dev
[ ] Update CV / LinkedIn / GitHub
```
