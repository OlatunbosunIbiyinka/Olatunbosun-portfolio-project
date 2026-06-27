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

## 2026-06-26 — Phase 1 apply: Terraform timeout while AKS still Creating

| Problem | Fix |
|---------|-----|
| `context deadline exceeded` after 360m; AKS still `Creating` in Azure | Do **not** delete cluster. Run `.\recover-phase1-after-aks-timeout.ps1` — waits for `Succeeded`, imports cluster, completes apply |
| AKS not in terraform state after timeout | `terraform import module.aks.azurerm_kubernetes_cluster.aks <aks-resource-id>` |
| Recurring 360m timeout on this stack | Increased create timeout to `720m` in `modules/aks/main.tf` |

```powershell
cd infra/terraform
.\recover-phase1-after-aks-timeout.ps1
```

---

## 2026-06-27 — AKS Failed: NodesNotReady / Internal server error

| Problem | Fix |
|---------|-----|
| Cluster `Failed` after ~9h; system pool `NodesNotReady` | Delete failed cluster, clean TF state, retry with **simplified bootstrap** |
| K8s `1.35` (latest) + workload pool on first create | Pin `kubernetes_version = "1.31.9"`; `workload_node_pools = {}` until cluster is healthy |
| Private + Cilium + NAT/UDR fails `NodesNotReady` twice | Bootstrap with `enable_nat_gateway=false`, `network_policy=azure`, `network_dataplane=azure`; add NAT/Cilium after Succeeded |
| `-target` apply warning | After AKS succeeds, run full `terraform plan` + apply (no `-target`) |

### On ops VM — recovery

```bash
cd ~/Olatunbosun-portfolio-project/infra/terraform

# 1. Delete failed cluster in Azure
az aks delete -g ola-rg-dev -n ola-aks-dev --yes --no-wait

# 2. Wait until gone (or check portal)
az aks show -g ola-rg-dev -n ola-aks-dev 2>/dev/null || echo "AKS deleted"

# 3. Remove AKS from Terraform state (if present)
terraform state list | grep '^module\.aks\.' | while read r; do terraform state rm "$r"; done

# 4. Sync bootstrap-safe tfvars
cp envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars
# Or edit: kubernetes_version=1.31.9, workload_node_pools={}, enable_azure_policy=false

export KUBECONFIG=""

# 5. Retry AKS only (monitoring + Argo off)
terraform apply -var-file="envs/dev/terraform.tfvars" \
  -var="enable_argocd=false" \
  -var="enable_aks_monitoring_addon=false" \
  -target="module.aks" \
  -auto-approve

# 6. When cluster is Succeeded — full apply + VM RBAC
AKS_ID=$(az aks show -g ola-rg-dev -n ola-aks-dev --query id -o tsv)
terraform apply -var-file="envs/dev/terraform.tfvars" \
  -var="enable_argocd=false" \
  -var="enable_aks_monitoring_addon=false" \
  -var="jumpbox_aks_cluster_id=$AKS_ID" \
  -auto-approve

# 7. Add workload pool later (uncomment in tfvars) then apply again
```

If `NodesNotReady` persists, open Azure support ticket with Activity Id from portal — often transient Azure backend issue on private + Cilium clusters.

---

## Bootstrap vs stable platform

**Bootstrap (default in `envs/dev/terraform.tfvars.example`)** — only what is needed for a healthy private cluster:

| Feature | Bootstrap | Stable phase |
|---------|-----------|--------------|
| NAT Gateway + UDR egress | off | Phase 3 |
| Cilium network policy | off (azure) | Phase 4 |
| Azure Policy addon | off | Phase 2 |
| Workload node pool | off | Phase 1 |
| System pool taints | off | Phase 1 |
| Container Insights addon | off | Phase 5 |
| Argo CD | off | Phase 6 |
| K8s version | pinned 1.31.9 | bump when stable |

**On ops VM after bootstrap succeeds:**

```bash
cp envs/dev/terraform.tfvars.example envs/dev/terraform.tfvars   # if not already
bash scripts/enable-stable-platform.sh plan                      # see drift
# Edit tfvars — uncomment ONE phase block — then:
bash scripts/enable-stable-platform.sh apply
```

Or GitOps only: `bash scripts/phase2-on-vm.sh` (phases 5–6).
