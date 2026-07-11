# Olatunbosun Portfolio — Azure Platform Engineering Project

[![CI - Build and Push](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci-build-push.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci-build-push.yml)
[![CI - Quality](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml)
[![Terraform Validation](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/terraform.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/terraform.yml)

**Live site:** [https://olatunbosun.dev](https://olatunbosun.dev)

A production-pattern **React portfolio** on **private Azure Kubernetes Service (AKS)**, provisioned with **Terraform**, delivered via **GitOps (Argo CD)**, and automated through **GitHub Actions** with OIDC — CI builds images; Argo CD deploys.

---

## Live vs designed

| Capability | Live (dev) | Designed / phased |
|------------|------------|-------------------|
| Private AKS + Ingress + TLS | Yes — [olatunbosun.dev](https://olatunbosun.dev) | — |
| Outbound | **`loadBalancer`** | Phase 3: **`userAssignedNATGateway`** (NAT on subnet, **no UDR**) |
| Workload node pool | Yes | `envs/dev/stable/phase1-*.tfvars` |
| Azure Policy | Yes | `stable/phase2-*.tfvars` |
| Cilium dataplane / Hubble | Not required on current cluster | Phase 4 |
| Observability | Azure Monitor / Container Insights (optional) | Prometheus/Grafana optional — not claimed as live |
| Front Door / WAF | No | Prod target only |
| Ops VM + self-hosted runner | Yes (for private ACR builds) | — |
| Staging / prod Azure stacks | Codified only | `envs/staging`, `envs/prod` |

Classic **UDR + NAT** was evaluated and abandoned (broke node bootstrap). Prefer AKS-native `userAssignedNATGateway` when predictable egress is needed.

---

## What this project is

| Layer | Technology | Role |
|-------|------------|------|
| **Application** | React 18 + nginx (port 8080) | Static portfolio SPA |
| **Infrastructure** | Terraform 1.10.5 on Azure | VNet, private AKS, ACR, Key Vault, Bastion, Argo CD |
| **Supply chain** | GitHub Actions (self-hosted runner) | Build, Trivy scan, push immutable images to private ACR |
| **Runtime** | Argo CD (in-cluster) | Reconcile cluster state from Git — CI never deploys directly |

**Design principle:** CI builds and records deploy intent in Git. Argo CD deploys. CI OIDC identity has **no AKS cluster access**.

---

## Architecture

```
Developer push (app/ or infra/)
        │
        ├─ app/** ──► ci.yml (quality)            ── GitHub-hosted
        │             ci-build-push.yml (release) ── self-hosted runner (ops VM, VNet)
        │
        └─ infra/** ─► terraform.yml (IaC)        ── GitHub-hosted

Release path (ci-build-push.yml):
  Buildx → Trivy gate → push ola-portfolio-app:{git-sha} → ACR (private)
        → update gitops/apps/portfolio-app/deployment.yaml
        → bot commit to main
        → Argo CD syncs → AKS rolling update
        → smoke test (VM MI + kubectl + /health)

Infrastructure (manual apply from ops VM / Bastion path):
  Terraform → Azure (VNet, private endpoints, AKS, ACR, KV, Bastion, Argo CD)
```

### Azure platform (Terraform modules)

| Module | Delivers |
|--------|----------|
| `vnet` | VNet `10.0.0.0/16`, subnets, optional user-assigned NAT, NSGs, private DNS |
| `aks` | Private AKS, CNI Overlay; network policy azure (bootstrap) or Cilium (phase 4) |
| `acr` | Premium ACR, private endpoint, optional geo-replication (prod tfvars) |
| `keyvault` | RBAC Key Vault, private endpoint, audit logs |
| `bastion-jumpbox` | Azure Bastion + operations VM (Trusted Execution Zone) |
| `github-oidc` | Federated credentials for GitHub Actions |
| `argocd` | Argo CD Helm release |

### Network layout

| Subnet | CIDR | Purpose |
|--------|------|---------|
| `aks-subnet` | 10.0.1.0/24 | AKS nodes; outbound via `loadBalancer` (or user-assigned NAT when enabled) |
| `private-endpoints` | 10.0.2.0/24 | ACR + Key Vault private endpoints |
| `AzureBastionSubnet` | 10.0.3.0/26 | Bastion |
| `operations-subnet` | 10.0.4.0/24 | Ops VM + self-hosted GitHub runner |

### State management

- Remote backend: Azure Blob (`olaportfolio001` / `tfstate`)
- Auth: Azure AD OIDC (`use_azuread_auth`, `use_oidc`)
- Per-environment keys via `backends/{dev,staging,prod}.hcl` — see [infra/terraform/envs/README.md](infra/terraform/envs/README.md)

---

## CI/CD pipelines

Three **independent** workflows, triggered by path filters on `main` and `develop`.

### 1. CI — Quality (`.github/workflows/ci.yml`)

| | |
|--|--|
| **Trigger** | `app/**` on PR and push |
| **Runner** | `ubuntu-latest` |
| **Steps** | `npm ci` → build → tests → SonarCloud (if `SONAR_TOKEN` set) |

### 2. CI — Build and Push (`.github/workflows/ci-build-push.yml`)

| | |
|--|--|
| **Trigger** | `app/**` on push; `workflow_dispatch` |
| **Runner** | `self-hosted` (operations VM in VNet) |
| **Auth** | GitHub OIDC → ACR push; VM managed identity for smoke test |
| **Steps** | Buildx → **Trivy** → push `{git-sha}` → update GitOps → bot commit → smoke test |

### 3. Terraform Validation (`.github/workflows/terraform.yml`)

| | |
|--|--|
| **Trigger** | `infra/**` on PR and push |
| **Jobs** | fmt → validate → **Checkov** → plan (push only) |
| **Apply** | **Not in CI** — from ops VM |

### GitOps (Argo CD)

- Application: `gitops/apps/portfolio-app.yaml`
- Manifests: `gitops/apps/portfolio-app/`
- Automated sync; immutable image tags only

See [gitops/README.md](gitops/README.md) and [docs/ADR-ACR-private-build-strategy.md](docs/ADR-ACR-private-build-strategy.md).

---

## Repository structure

```
.
├── app/                          # React portfolio (Dockerfile → nginx:8080)
├── gitops/                       # Argo CD app + platform manifests
├── infra/terraform/              # Modules, envs, backends
├── .github/workflows/            # Quality, release, Terraform validation
├── docs/                         # Architecture, ADR, quick start, domain
│   └── archive/                  # Historical upgrade notes (not current truth)
└── scripts/                      # Ops helpers (bootstrap, runner, stable phases)
```

---

## Quick start

**Fastest path:** [docs/QUICK_START.md](docs/QUICK_START.md) — laptop bootstrap → ops VM GitOps.

```powershell
cd infra/terraform
.\bootstrap-dev.ps1          # Phase 1 (laptop): core infra, Argo off
```

```bash
# Phase 2 (ops VM via Bastion)
bash scripts/phase2-on-vm.sh
bash scripts/install-github-runner.sh   # needs GITHUB_RUNNER_TOKEN
```

Stable hardening (ops VM, one phase at a time): `bash scripts/stable-phase-apply.sh apply <1-5>`

---

## Multi-environment

| Environment | Status |
|-------------|--------|
| **dev** | Live bootstrap / demo |
| **staging** | Codified in `envs/staging/` — not deployed by default |
| **prod** | Codified in `envs/prod/` — includes ACR geo-rep target |

---

## Security model

| Control | Implementation |
|---------|----------------|
| No long-lived cloud secrets in CI | GitHub OIDC |
| CI cannot deploy to cluster | OIDC has no AKS access |
| Private registry | ACR private endpoint |
| Private cluster | AKS API in VNet; Bastion + ops VM |
| Immutable artifacts | Image tags = git SHA |
| Supply chain gates | Trivy, Checkov, SonarCloud (optional) |
| Secrets | Key Vault + Workload Identity + CSI |
| Network | Private endpoints, NSGs; Azure NPM today / Cilium phased |

---

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture & interview guide](docs/ARCHITECTURE_AND_INTERVIEW_PRESENTATION.md) | Walkthrough + presentation notes |
| [Production environment (target)](docs/PRODUCTION_ENVIRONMENT.md) | Prod patterns — not all live on dev |
| [ADR: Private ACR build](docs/ADR-ACR-private-build-strategy.md) | Why self-hosted runner in VNet |
| [Quick start](docs/QUICK_START.md) | Clean bootstrap |
| [Domain setup](docs/DOMAIN_SETUP.md) | Ingress + cert-manager + DNS |
| [OIDC setup](docs/OIDC_SETUP.md) | GitHub ↔ Azure federation |
| [Multi-environment](infra/terraform/envs/README.md) | Dev / staging / prod |
| [Archive](docs/archive/README.md) | Historical notes — not current truth |

---

## Key design decisions

1. **GitOps separation** — CI supplies images; Argo CD reconciles from Git.
2. **Self-hosted runner** — Private ACR needs an in-VNet build path (ADR).
3. **Plan-only Terraform in CI** — Apply from the Trusted Execution Zone.
4. **Phased hardening** — Bootstrap stable first; NAT / Cilium / policy in controlled phases.
5. **Immutable SHA tags** — Auditable rollback via Git.

---

## Author

**Olatunbosun Ibiyinka** — Platform / DevOps Engineer

- Live: [olatunbosun.dev](https://olatunbosun.dev)
- [GitHub](https://github.com/OlatunbosunIbiyinka)
- [LinkedIn](https://www.linkedin.com/in/olatunbosun-ibiyinka)

---

## License

MIT License — see repository license settings / add a `LICENSE` file if redistributing.

---

*Last updated: July 2026*
