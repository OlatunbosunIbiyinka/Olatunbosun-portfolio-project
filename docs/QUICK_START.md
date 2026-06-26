# Quick Start — Clean dev bootstrap

Fastest path to a working private AKS + GitOps portfolio. **Two phases** — Phase 1 from your laptop, Phase 2 from the ops VM.

## Prerequisites

- Azure CLI logged in: `az login`
- Terraform >= 1.0, Helm (laptop optional for Phase 1)
- Contributor on subscription; `tfstate-rg` / `olaportfolio001` already exist (bootstrap backend)

## Phase 1 — Laptop (~2–3 hours)

```powershell
cd infra/terraform
.\bootstrap-dev.ps1
```

This script:

1. Purges soft-deleted Key Vault `ola-kv-dev` if present
2. Validates Terraform
3. Applies with **safe bootstrap flags**:
   - `enable_argocd = false` (private API unreachable from laptop)
   - `enable_aks_monitoring_addon = false` (avoids Container Insights timeout)
   - VM tool extensions off (install tools on VM in Phase 2)

**Creates:** `ola-rg-dev`, VNet, NAT, private ACR/KV, private AKS, Bastion, ops VM, GitHub OIDC.

**Does not create:** Argo CD, Container Insights addon, GitHub runner.

### If Phase 1 fails

| Symptom | Fix |
|---------|-----|
| Key Vault name taken | `az keyvault purge --name ola-kv-dev --location uksouth` |
| Terraform state drift | `.\start-fresh.ps1` then re-run bootstrap |
| AKS timeout | Wait — create timeout is 720m. If TF fails while Azure still `Creating`, run `.\recover-phase1-after-aks-timeout.ps1` |

## Phase 2 — Ops VM (~30–45 min)

1. Azure Portal → **Bastion** → connect to `aks-operations-vm` (Azure AD login)
2. Clone repo and run:

```bash
git clone https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project.git
cd Olatunbosun-portfolio-project
chmod +x scripts/phase2-on-vm.sh
./scripts/phase2-on-vm.sh
```

This enables monitoring + Argo CD, configures kubectl, and registers the GitOps app.

## Phase 3 — CI + live site (~15 min after runner)

1. **GitHub secrets** (from ops VM):

```bash
cd infra/terraform
terraform output github_oidc_client_id
terraform output github_oidc_tenant_id
terraform output github_oidc_subscription_id
```

Set `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `RESOURCE_GROUP` in GitHub.

2. **Self-hosted runner** (required for private ACR):

```bash
./scripts/install-github-runner.sh
```

3. **Deploy app:** push any change under `app/` to `main` — CI builds, pushes to ACR, updates GitOps, Argo CD syncs.

4. **Public URL:** after Ingress controller is live, point `olatunbosun.dev` at the Ingress LB IP — see [DOMAIN_SETUP.md](DOMAIN_SETUP.md).

## Config reference (`envs/dev/terraform.tfvars`)

| Setting | Phase 1 | Phase 2 |
|---------|---------|---------|
| `enable_argocd` | `false` | `true` |
| `enable_aks_monitoring_addon` | `false` | `true` |
| `jumpbox_install_*` | all `false` | install via `setup-phase2-tools.sh` |

Copy from `terraform.tfvars.example` if starting fresh:

```powershell
Copy-Item envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars
```

## Tear down

```powershell
cd infra/terraform
.\safe-destroy.ps1
```

State backend (`tfstate-rg`) is kept unless you delete it manually.
