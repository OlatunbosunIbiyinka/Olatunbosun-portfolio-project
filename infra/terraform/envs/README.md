# Multi-Environment Terraform Configuration

> **Status:** Dev is **ready to bootstrap** (see [docs/QUICK_START.md](../../docs/QUICK_START.md)). Staging and prod are codified but not deployed by default.

## Layout

| Environment | Var file | State key (blob) | Deployed |
|-------------|----------|------------------|----------|
| **dev** | `dev/terraform.tfvars` | `terraform.tfstate` | Bootstrap via `bootstrap-dev.ps1` |
| **staging** | `staging/terraform.tfvars` | `staging/terraform.tfstate` | No (codified) |
| **prod** | `prod/terraform.tfvars` | `prod/terraform.tfstate` | No (codified) |

Copy `terraform.tfvars.example` → `terraform.tfvars` per environment. Local `*.tfvars` files are gitignored.

## Apply workflow

```bash
cd infra/terraform

# Development (current live stack — uses backend.tf default key)
terraform init
terraform apply -var-file="envs/dev/terraform.tfvars"

# Staging (when ready — isolated state)
terraform init -reconfigure -backend-config=backends/staging.hcl
terraform plan  -var-file="envs/staging/terraform.tfvars"

# Production (when ready — isolated state + DR settings in tfvars)
terraform init -reconfigure -backend-config=backends/prod.hcl
terraform plan  -var-file="envs/prod/terraform.tfvars"
```

Use `enterprise-deploy.ps1 -VarFile envs/<env>/terraform.tfvars` for staged applies.

## State isolation

All environments share the bootstrap storage account (`olaportfolio001` / `tfstate`) with **separate blob keys** — no state collision. For production hardening, enable **blob versioning and soft delete** on the state storage account (bootstrap, outside this stack).

## Environment differences (summary)

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| Key Vault purge protection | `false` | `true` | `true` |
| ACR geo-replication | `[]` | `[]` | `["northeurope"]` |
| Workload pool min nodes | 1 | 2 | 2 |
| Workload pool max nodes | 5 | 8 | 10 |
| GitHub OIDC subjects | `main`, `develop`, PR | `main`, `develop` | `main` + `environment:production` |
| Tags `Environment` | `development` | `staging` | `production` |

## Disaster recovery (prod tfvars)

Production tfvars enable **ACR geo-replication** to `northeurope` (Azure UK paired region). Recovery model:

1. **Platform:** Re-apply Terraform from Git + backed-up state blob (`terraform state pull`).
2. **Images:** Pull from geo-replicated ACR region if primary `uksouth` is unavailable.
3. **Secrets:** Key Vault soft delete (7-day) + purge protection prevents accidental permanent loss.
4. **Application:** Stateless SPA — GitOps manifest + immutable ACR SHA tags are the runtime source of truth.

RTO/RPO targets and multi-region AKS are documented in `docs/ARCHITECTURE_AND_INTERVIEW_PRESENTATION.md` §3.7.
