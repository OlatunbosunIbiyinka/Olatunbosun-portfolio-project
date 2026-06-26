# Bootstrap fixes (dev redeploy)

Changelog of issues encountered and fixes applied for a clean Phase 1 / Phase 2 bootstrap.

## 2026-06-26 — Clean restart after full tear-down

### Root cause: stale `terraform.tfvars`

| Problem | Fix |
|---------|-----|
| `enable_argocd = true` in live `envs/dev/terraform.tfvars` | Synced from `terraform.tfvars.example` with `enable_argocd = false` for Phase 1 |
| Missing `enable_aks_monitoring_addon = false` | Added — Container Insights Helm install timed out on previous private cluster bootstrap |
| VM custom-script extensions enabled by default | Set all `jumpbox_install_* = false`; install tools on VM via `scripts/setup-phase2-tools.sh` |

### Terraform provider / plan errors (prior session)

| Problem | Fix | File |
|---------|-----|------|
| `coalesce("", "")` when `jumpbox_ssh_public_key = ""` | Null-safe `trimspace` local | `modules/bastion-jumpbox/main.tf` |
| Kube/Helm providers depend on unknown `module.aks` outputs when `enable_argocd=false` | Placeholder provider config Phase 1; `data.azurerm_kubernetes_cluster` Phase 2 | `main.tf` |
| AKS create timeout at 240m | Increased to `360m` | `modules/aks/main.tf` |

### Azure preflight

| Problem | Fix |
|---------|-----|
| Soft-deleted Key Vault `ola-kv-dev` blocks recreate | `az keyvault purge --name ola-kv-dev --location uksouth` in `bootstrap-dev.ps1` |
| Stale Argo CD objects in state after failed run | `apply-without-argocd.ps1` removes `module.argocd[0].*` from state before apply |
| Laptop `KUBECONFIG` breaks refresh | `$env:KUBECONFIG = ""` at start of apply scripts |

### New automation

| Script | Purpose |
|--------|---------|
| `infra/terraform/bootstrap-dev.ps1` | Preflight + Phase 1 apply from laptop |
| `scripts/phase2-on-vm.sh` | Monitoring addon + Argo CD + GitOps app on ops VM |
| `docs/QUICK_START.md` | End-to-end bootstrap guide |

### Phase 1 apply flags (always use from laptop)

```powershell
terraform apply -var-file="envs/dev/terraform.tfvars" `
  -var="enable_argocd=false" `
  -var="enable_aks_monitoring_addon=false" `
  -auto-approve
```

### Phase 2 apply flags (ops VM only)

```bash
terraform apply -var-file="envs/dev/terraform.tfvars" \
  -var="enable_argocd=true" \
  -var="enable_aks_monitoring_addon=true" \
  -auto-approve
```

---

_Add new rows here when fixing issues during apply._
