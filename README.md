# Olatunbosun Portfolio — Azure Platform Engineering Project

[![CI - Build and Push](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci-build-push.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci-build-push.yml)
[![CI - Quality](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml)
[![Terraform Validation](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/terraform.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/terraform.yml)

A production-pattern **React portfolio** on **Azure Kubernetes Service (AKS)**, provisioned with **Terraform**, delivered via **GitOps (Argo CD)**, and automated through **three GitHub Actions pipelines** with enterprise security controls.

---

## Table of Contents

- [What This Project Is](#what-this-project-is)
- [Architecture](#architecture)
- [CI/CD Pipelines](#cicd-pipelines)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Multi-Environment](#multi-environment)
- [Security Model](#security-model)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)

---

## What This Project Is

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
        ├─ app/** ──► ci.yml (quality)          ── GitHub-hosted
        │             ci-build-push.yml (release) ── self-hosted runner (ops VM, VNet)
        │
        └─ infra/** ─► terraform.yml (IaC)      ── GitHub-hosted

Release path (ci-build-push.yml):
  Buildx → Trivy gate → push ola-portfolio-app:{git-sha} → ACR (private)
        → update gitops/apps/portfolio-app/deployment.yaml
        → bot commit to main
        → Argo CD syncs → AKS rolling update
        → smoke test (VM MI + kubectl + /health)

Infrastructure (manual apply from ops VM):
  Terraform → Azure (VNet, NAT, private endpoints, AKS, ACR, KV, Argo CD)
```

### Azure platform (Terraform modules)

| Module | Delivers |
|--------|----------|
| `vnet` | VNet `10.0.0.0/16`, subnets, NAT Gateway, NSGs, private DNS |
| `aks` | Private AKS, CNI Overlay + Cilium, system + workload node pools |
| `acr` | Premium ACR, private endpoint, optional geo-replication (prod) |
| `keyvault` | RBAC Key Vault, private endpoint, audit logs |
| `bastion-jumpbox` | Azure Bastion + operations VM (Trusted Execution Zone) |
| `github-oidc` | Federated credentials for GitHub Actions |
| `argocd` | Argo CD Helm release (HA) |

### Network layout

| Subnet | CIDR | Purpose |
|--------|------|---------|
| `aks-subnet` | 10.0.1.0/24 | AKS nodes; NAT Gateway egress |
| `private-endpoints` | 10.0.2.0/24 | ACR + Key Vault private endpoints |
| `AzureBastionSubnet` | 10.0.3.0/26 | Bastion |
| `operations-subnet` | 10.0.4.0/24 | Ops VM + self-hosted GitHub runner |

Outbound: **NAT Gateway + `userDefinedRouting`** when `enable_nat_gateway = true` (default in tfvars).

### State management

- Remote backend: Azure Blob (`olaportfolio001` / `tfstate`)
- Auth: Azure AD OIDC (`use_azuread_auth`, `use_oidc`)
- Per-environment keys via `backends/{dev,staging,prod}.hcl` — see [infra/terraform/envs/README.md](infra/terraform/envs/README.md)

---

## CI/CD Pipelines

Three **independent** workflows, triggered by path filters on `main` and `develop`.

### 1. CI — Quality (`.github/workflows/ci.yml`)

| | |
|--|--|
| **Trigger** | `app/**` on PR and push |
| **Runner** | `ubuntu-latest` |
| **Steps** | `npm ci` → build → tests → SonarCloud (if `SONAR_TOKEN` set) |
| **Purpose** | Shift-left quality gate before/at merge |

### 2. CI — Build and Push (`.github/workflows/ci-build-push.yml`)

| | |
|--|--|
| **Trigger** | `app/**` on push (not PR); `workflow_dispatch` |
| **Runner** | `self-hosted` (operations VM in VNet) |
| **Auth** | GitHub OIDC → ACR push; VM managed identity for smoke test |
| **Steps** | Buildx + ACR cache → **Trivy** (CRITICAL/HIGH gate) → push `{git-sha}` tag → update GitOps manifest → bot commit → **smoke test** |
| **Purpose** | Verified artifact supply + GitOps intent + runtime proof |

GitOps bot commits (`gitops/**` only) do **not** re-trigger this workflow.

### 3. Terraform Validation (`.github/workflows/terraform.yml`)

| | |
|--|--|
| **Trigger** | `infra/**` on PR and push |
| **Runner** | `ubuntu-latest` |
| **Jobs** | fmt → validate → **Checkov** → plan (push only, OIDC to state) |
| **Plan** | `-refresh=false` (private AKS API unreachable from hosted runners) |
| **Apply** | **Not in CI** — manual from ops VM |

### GitOps (Argo CD)

- Application: `gitops/apps/portfolio-app.yaml`
- Manifests: `gitops/apps/portfolio-app/deployment.yaml`
- Automated sync with prune + selfHeal; immutable image tags only (no `:latest` in CI)

See [GITOPS_ARCHITECTURE.md](GITOPS_ARCHITECTURE.md) and [docs/ADR-ACR-private-build-strategy.md](docs/ADR-ACR-private-build-strategy.md).

---

## Repository Structure

```
.
├── app/                          # React portfolio (Dockerfile → nginx:8080)
├── gitops/
│   └── apps/portfolio-app/       # Argo CD deployment manifests (primary deploy path)
├── k8s/                          # Hardened reference manifests (HPA, PDB, netpol)
├── infra/terraform/
│   ├── modules/                  # vnet, aks, acr, keyvault, github-oidc, argocd, bastion-jumpbox
│   ├── envs/
│   │   ├── dev/                  # Live dev tfvars (terraform.tfvars gitignored)
│   │   ├── staging/              # Codified, not deployed by default
│   │   └── prod/                 # Codified + ACR geo-replication (northeurope)
│   ├── backends/                 # Per-env state key overrides
│   └── enterprise-deploy.ps1     # Staged 5-phase apply
├── .github/workflows/
│   ├── ci.yml                    # Quality
│   ├── ci-build-push.yml         # Release + GitOps + smoke test
│   └── terraform.yml             # IaC validation
├── docs/
│   ├── ARCHITECTURE_AND_INTERVIEW_PRESENTATION.md
│   ├── ADR-ACR-private-build-strategy.md
│   └── OIDC_SETUP.md
└── scripts/                      # Ops helpers (vm-resume-ops.sh, validate-terraform-plan.ps1)
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Azure CLI | Latest | Authentication, AKS credentials |
| Terraform | >= 1.0 (CI pins 1.10.5) | Infrastructure |
| kubectl + kubelogin | Latest | Private AKS access |
| Docker | Latest | Local builds; required on ops VM runner |
| Helm | >= 3.0 | Argo CD, monitoring add-ons |

**Azure:** Subscription with Contributor access; ability to create AKS, ACR, Key Vault, VNet.

**GitHub:** Repository secrets — `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `RESOURCE_GROUP`; optional `SONAR_TOKEN`.

---

## Quick Start

**Fastest path:** [docs/QUICK_START.md](docs/QUICK_START.md) — two-phase bootstrap (laptop → ops VM).

### 1. Configure environment

```bash
cp infra/terraform/envs/dev/terraform.tfvars.example \
   infra/terraform/envs/dev/terraform.tfvars
# Names (acr_name, key_vault_name) are pre-set for this project; change only if taken globally
```

### 2. Phase 1 — Deploy core infra (from laptop)

```powershell
cd infra/terraform
.\bootstrap-dev.ps1
```

Applies with `enable_argocd=false` and `enable_aks_monitoring_addon=false` (~2–3 hours).

**Provisioned:** Resource Group, VNet, NAT, ACR (private), Key Vault (private), private AKS, Bastion + ops VM, GitHub OIDC.

### 3. Phase 2 — GitOps + monitoring (from ops VM via Bastion)

```bash
./scripts/phase2-on-vm.sh
```

Enables Argo CD, Container Insights, kubectl, and registers the GitOps application.

### 4. Configure GitHub secrets

```bash
cd infra/terraform
terraform output github_oidc_client_id
terraform output github_oidc_tenant_id
terraform output github_oidc_subscription_id
```

Add outputs plus `ACR_NAME` and `RESOURCE_GROUP` to GitHub Actions secrets. See [docs/OIDC_SETUP.md](docs/OIDC_SETUP.md).

### 5. Install self-hosted runner (ops VM)

```bash
# On aks-operations-vm (via Bastion)
./scripts/install-github-runner.sh
```

Required for CI builds — private ACR is unreachable from GitHub-hosted runners.

### 6. Deploy via CI (preferred)

Push a change to `app/**` on `main` — the release pipeline builds, scans, pushes to ACR, updates GitOps, and Argo CD deploys automatically.

**Manual fallback:** Update image in `gitops/apps/portfolio-app/deployment.yaml` and push — Argo syncs.

---

## Multi-Environment

| Environment | Var file | State key | Status |
|-------------|----------|-----------|--------|
| **dev** | `envs/dev/terraform.tfvars` | `terraform.tfstate` | Bootstrap via `bootstrap-dev.ps1` |
| **staging** | `envs/staging/terraform.tfvars.example` | `staging/terraform.tfstate` | Codified — ready to plan/apply |
| **prod** | `envs/prod/terraform.tfvars.example` | `prod/terraform.tfstate` | Codified — includes ACR geo-rep to `northeurope` |

```bash
# Staging
terraform init -reconfigure -backend-config=backends/staging.hcl
terraform plan -var-file="envs/staging/terraform.tfvars"

# Production
terraform init -reconfigure -backend-config=backends/prod.hcl
terraform plan -var-file="envs/prod/terraform.tfvars"
```

Full workflow: [infra/terraform/envs/README.md](infra/terraform/envs/README.md)

---

## Security Model

| Control | Implementation |
|---------|----------------|
| **No long-lived cloud secrets in CI** | GitHub OIDC federated credentials |
| **CI cannot deploy to cluster** | `enable_aks_access = false` on OIDC module |
| **Private registry** | ACR Premium, private endpoint, public access disabled |
| **Private cluster** | AKS API only in VNet; admin via Bastion + ops VM |
| **Immutable artifacts** | Image tags = full git SHA |
| **Supply chain gates** | Trivy (images), Checkov (IaC), SonarCloud (code) |
| **Secrets** | Key Vault + Workload Identity + CSI driver |
| **Network** | Cilium policies, NSGs, private endpoints, NAT egress |

---

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture & Interview Guide](docs/ARCHITECTURE_AND_INTERVIEW_PRESENTATION.md) | End-to-end architecture, CI/CD, DR, presentation script |
| [Production Environment (target state)](docs/PRODUCTION_ENVIRONMENT.md) | What would be implemented for full prod — end-to-end |
| [GitOps Architecture](GITOPS_ARCHITECTURE.md) | Argo CD workflow and principles |
| [ADR: Private ACR Build Strategy](docs/ADR-ACR-private-build-strategy.md) | Why self-hosted runner in VNet |
| [OIDC Setup](docs/OIDC_SETUP.md) | GitHub ↔ Azure federation |
| [Multi-Environment](infra/terraform/envs/README.md) | Dev / staging / prod tfvars and state |
| [Deployment Guide](DEPLOYMENT.md) | Detailed deploy and rollback |
| [Troubleshooting](TROUBLESHOOTING.md) | Common errors and recovery |
| [Production Checklist](PRODUCTION_CHECKLIST.md) | Pre-prod readiness gates |
| [Enterprise Deploy](infra/terraform/enterprise-deploy.ps1) | Staged Terraform apply |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| CI OIDC / ACR 403 | Ensure federated credential matches branch; runner on ops VM in VNet |
| `terraform plan` timeout from laptop | Use `scripts/validate-terraform-plan.ps1` (`-refresh=false`) or plan from ops VM |
| Cannot reach private AKS API | Connect via Bastion → ops VM; use `kubelogin` |
| Pods CrashLoopBackOff | Verify probes hit `/health:8080` — see `app/nginx.conf` and GitOps deployment |
| State lock | `terraform force-unlock <id>` |
| Resources deleted in portal | `infra/terraform/cleanup-after-portal-delete.ps1` |

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for full runbooks.

---

## Key Design Decisions

1. **GitOps separation** — CI supplies images; Argo CD reconciles cluster state from Git.
2. **Self-hosted runner** — Private ACR requires in-VNet build path (documented ADR).
3. **Plan-only Terraform in CI** — Apply from Trusted Execution Zone; limits blast radius.
4. **Three path-triggered pipelines** — Quality, release, and IaC run independently.
5. **Immutable SHA tags** — Auditable rollback via Git revert.

---

## Author

**Olatunbosun Ibiyinka**

- [GitHub](https://github.com/OlatunbosunIbiyinka)
- [LinkedIn](https://linkedin.com/in/yourprofile)

---

## License

MIT License.

---

*Last updated: June 2026*
