# Helm Provider Cache Error - Fix Applied

## Error Message (Resolved)
```
Error: Error locating chart argo-cd: no cached repo found. (try 'helm repo update'): open
C:\Users\...\Temp\helm\repository\prometheus-community-index.yaml: The system cannot find the file specified.
```

## Fix Applied

1. **Helm CLI** - Install via `winget install Helm.Helm`
2. **fix-helm-cache.ps1** - Prepares cache and sets `HELM_CACHE_HOME` so Terraform uses it
3. **ArgoCD module** - Uses `argoproj/argo-cd` chart with `data.external` to prepare cache during plan

## How to Run Terraform

```powershell
cd infra/terraform

# Option 1: Use the fix script (runs terraform with correct env)
.\fix-helm-cache.ps1 plan
.\fix-helm-cache.ps1 apply -auto-approve

# Option 2: Dot-source then run terraform in same session
. .\fix-helm-cache.ps1
terraform plan -var-file="envs/dev/terraform.tfvars"
```

## Disable ArgoCD

Set `enable_argocd = false` in `terraform.tfvars` if you don't need GitOps.

---

## Private AKS: "no such host" When Applying from Laptop

If AKS uses a **private API endpoint** (`*.privatelink.uksouth.azmk8s.io`), that hostname only resolves from inside the VNet. Terraform runs from your laptop cannot reach it, so the apply fails when creating the ArgoCD namespace/Helm release.

**Fix: two-phase apply**

### Phase 1 – From your laptop (create everything except ArgoCD)

```powershell
cd infra/terraform
.\fix-helm-cache.ps1 plan -out=tfplan
# Apply WITHOUT ArgoCD so VM and cluster are created first
terraform apply -var-file="envs/dev/terraform.tfvars" -var="enable_argocd=false" -auto-approve
```

Or use the helper script:

```powershell
.\apply-without-argocd.ps1
```

This creates the VNet, AKS, bastion, jumpbox VM, etc. ArgoCD is skipped because the Kubernetes provider cannot reach the private API from the laptop.

### Phase 2 – From the jumpbox VM (create ArgoCD only)

**Important:** Use `-target=module.argocd` so Terraform only creates ArgoCD and does not change or destroy any other resources. That avoids accidental destroys if the VM’s code doesn’t exactly match the state.

1. Connect to the jumpbox via Azure Bastion (RDP/SSH).
2. Ensure the VM has the **same** Terraform code as the laptop (same `main.tf`, modules, `backend.tf`). If you only added `argocd.tf`, the rest of the repo must match what was used in Phase 1, or Terraform may plan to destroy resources that exist in state but are missing from the VM’s config.
3. Run **targeted apply** (ArgoCD only):

```bash
cd ~/Olatunbosun-portfolio-project/infra/terraform
terraform init
helm repo add argoproj https://argoproj.github.io/argo-helm 2>/dev/null
helm repo update 2>/dev/null
export HELM_CACHE_HOME="${HOME}/.cache/helm"
terraform apply -var-file="envs/dev/terraform.tfvars" -var="enable_argocd=true" -target=module.argocd -auto-approve
```

Using `-target=module.argocd` means only the ArgoCD namespace and Helm release are created; no other resources are added, changed, or destroyed.

**If you see "variable enable_argocd was assigned... root module does not declare":** Create `argocd.tf` on the VM with the three variables (see repo or the “Without commit/push” section below).

**Why it worked before:** Earlier you may have had a public AKS endpoint, or you ran the apply that touches the cluster from a host inside the VNet (e.g. the jumpbox).

---

### What if Phase 2 planned to destroy ~50 resources?

That happens when the **config on the VM does not match the state**. For example:

- The VM had an older clone (or only `argocd.tf`) so `main.tf` / modules were different.
- Terraform then saw resources in state (e.g. bastion, jumpbox, monitoring) that were not in the VM’s config and planned to destroy them.


**Prevention:** Use **targeted apply** so only ArgoCD is applied:

```bash
terraform apply -var-file="envs/dev/terraform.tfvars" -var="enable_argocd=true" -target=module.argocd -auto-approve
```

**If you already applied and resources were deleted:** From your **laptop** (with the full, correct repo), run:

```powershell
cd infra/terraform
terraform init
terraform apply -var-file="envs/dev/terraform.tfvars" -var="enable_argocd=false" -auto-approve
```

That will re-create any missing resources that are in your config. Then use Phase 2 on the VM with `-target=module.argocd` only.

---

### Phase 2 without git push (same code as laptop)

If you don’t push yet, copy the **entire** `infra/terraform` folder from your laptop to the VM (e.g. SCP or shared folder) so the VM’s config matches the state. Then on the VM run only the targeted apply above. Do not rely on an old clone plus a single `argocd.tf` file.
