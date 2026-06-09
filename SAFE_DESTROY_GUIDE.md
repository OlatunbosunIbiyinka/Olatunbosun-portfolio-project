# 🗑️ Safe Terraform Destroy Guide

This guide ensures you can destroy your infrastructure cleanly without issues on the next `terraform apply`.

## ✅ Quick Start (Recommended Method)

**Use the safe destroy script:**

**PowerShell (Windows):**
```powershell
cd infra/terraform
.\safe-destroy.ps1
```

**Bash (Linux/Mac/Git Bash/WSL):**
```bash
cd infra/terraform
./safe-destroy.sh
```

The script automatically:
- ✅ Checks AKS cluster status
- ✅ Handles resources still being created
- ✅ Shows what will be destroyed
- ✅ Cleans up orphaned resources
- ✅ Verifies completion

## 📋 Pre-Destroy Checklist

Before running `terraform destroy`, verify:

- [ ] **No active deployments** - Check if any pods/workloads are running
- [ ] **No locked resources** - Check for deletion locks
- [ ] **Backup important data** - If needed (Key Vault secrets, etc.)
- [ ] **AKS cluster is ready** - Not in "Creating" or "Upgrading" state
- [ ] **No manual deletions** - Don't delete resources manually before destroy

## 🔧 Step-by-Step Safe Destroy Process

### Step 1: Review What Will Be Destroyed

```powershell
cd infra/terraform

# See what Terraform plans to destroy
terraform plan -destroy -var-file="envs/dev/terraform.tfvars"
```

**Review the output carefully** - Make sure you're okay with destroying these resources.

### Step 2: Check Resource Status

```powershell
# Check AKS cluster status
az aks show --resource-group ola-rg-dev --name ola-aks-dev --query "{provisioningState:provisioningState, powerState:powerState.code}" -o json

# Check if any resources are locked
az resource list --resource-group ola-rg-dev --query "[?properties.provisioningState=='Creating' || properties.provisioningState=='Updating'].{Name:name, Type:type, State:properties.provisioningState}" -o table
```

**If AKS is still creating:**
- Option 1: Cancel creation first (saves costs)
  ```powershell
  az aks delete --resource-group ola-rg-dev --name ola-aks-dev --yes
  ```
- Option 2: Wait for creation to complete, then destroy

### Step 3: Clean Up Kubernetes Resources (Optional but Recommended)

If you deployed workloads to AKS, clean them up first:

```powershell
# Get AKS credentials
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev --overwrite-existing

# Delete all workloads
kubectl delete --all --all-namespaces

# Or delete specific namespaces
kubectl delete namespace <namespace-name>
```

**Why?** This ensures AKS can be deleted cleanly without waiting for workload cleanup.

### Step 4: Run Safe Destroy

**Method 1: Using the Script (Recommended)**

**PowerShell:**
```powershell
cd infra/terraform
.\safe-destroy.ps1
```

**Bash:**
```bash
cd infra/terraform
./safe-destroy.sh
```

**Method 2: Manual Destroy**

```powershell
cd infra/terraform

# Destroy with auto-approve (after reviewing plan)
terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
```

### Step 5: Handle Common Issues

#### Issue 1: Federated Identity Credentials (404 Error)

**Error:**
```
Error: Removing Application Id Federated Identity Credential...
unexpected status 404 (404 Not Found)
```

**Fix:**
```powershell
# Remove orphaned federated credentials from state
terraform state list | Select-String "federated" | ForEach-Object { terraform state rm $_.Line }

# Continue destroy
terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
```

#### Issue 2: ContainerInsights Solution Blocking Resource Group Deletion

**Error:**
```
Error: deleting Resource Group: the Resource Group still contains Resources
* ContainerInsights(ola-rg-dev-logs)
```

**Fix:** Already handled! The configuration has `prevent_deletion_if_contains_resources = false` in `main.tf`, so this shouldn't block deletion.

If you still see this error:
```powershell
# Manually delete ContainerInsights solution
az monitor log-analytics solution delete \
  --resource-group ola-rg-dev \
  --name "ContainerInsights(ola-rg-dev-logs)"

# Retry destroy
terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
```

#### Issue 3: Resources Still Being Created

**Error:**
```
Error: cannot delete resource that is currently being created
```

**Fix:**
```powershell
# Wait for creation to complete or cancel it
az resource show --resource-group ola-rg-dev --name <resource-name> --resource-type <resource-type> --query "properties.provisioningState" -o tsv

# If stuck in "Creating", delete manually
az resource delete --resource-group ola-rg-dev --name <resource-name> --resource-type <resource-type>

# Remove from Terraform state
terraform state rm <resource-address>

# Continue destroy
terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
```

#### Issue 4: Key Vault Soft Delete

**Error:**
```
Error: cannot delete Key Vault (soft delete enabled)
```

**Fix:** Key Vault soft delete is enabled for safety. After destroy completes:

```powershell
# Purge soft-deleted Key Vault (if needed)
az keyvault purge --name ola-kv-dev
```

**Note:** The configuration has `purge_soft_delete_on_destroy = false` for safety. You can manually purge if needed.

### Step 6: Verify Cleanup

```powershell
# Check if Resource Group still exists
az group show --name ola-rg-dev

# If Resource Group exists but should be deleted
az group delete --name ola-rg-dev --yes --no-wait

# Verify Terraform state is clean
terraform state list
# Should return empty or minimal resources
```

## 🎯 Best Practices for Clean Destroy

### 1. Always Review Before Destroying

```powershell
# Always run plan first
terraform plan -destroy -var-file="envs/dev/terraform.tfvars"
```

### 2. Use Targeted Destroy for Troubleshooting

If destroy fails on specific resources:

```powershell
# Destroy specific resource
terraform destroy -target=module.aks.azurerm_kubernetes_cluster.aks -var-file="envs/dev/terraform.tfvars" -auto-approve

# Then destroy the rest
terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
```

### 3. Handle Dependencies Manually (If Needed)

If Terraform can't resolve dependencies:

```powershell
# Destroy in order:
# 1. AKS cluster (takes longest)
terraform destroy -target=module.aks -var-file="envs/dev/terraform.tfvars" -auto-approve

# 2. Operations VM and Bastion
terraform destroy -target=module.bastion_jumpbox -var-file="envs/dev/terraform.tfvars" -auto-approve

# 3. ACR and Key Vault
terraform destroy -target=module.acr -target=module.keyvault -var-file="envs/dev/terraform.tfvars" -auto-approve

# 4. Everything else
terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
```

### 4. Clean Up State After Manual Deletions

If you deleted resources manually:

```powershell
# List resources in state
terraform state list

# Remove manually deleted resources
terraform state rm <resource-address>

# Verify state is clean
terraform plan -destroy -var-file="envs/dev/terraform.tfvars"
```

### 5. Handle Interrupted Destroys

If destroy was interrupted:

```powershell
# Check what's actually deleted in Azure
az resource list --resource-group ola-rg-dev -o table

# Compare with Terraform state
terraform state list

# Remove deleted resources from state
terraform state rm <resource-address>

# Continue destroy
terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
```

## 🚨 Common Pitfalls to Avoid

### ❌ Don't Delete Resources Manually Before Destroy

**Bad:**
```powershell
# Manually deleting resources
az aks delete --resource-group ola-rg-dev --name ola-aks-dev --yes
terraform destroy  # Will fail because resource is gone but still in state
```

**Good:**
```powershell
# Let Terraform handle deletion
terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
```

### ❌ Don't Destroy While Resources Are Still Creating

**Bad:**
```powershell
# Destroying while AKS is still creating
terraform destroy  # Will fail or leave resources in bad state
```

**Good:**
```powershell
# Wait for creation to complete or cancel it first
az aks show --resource-group ola-rg-dev --name ola-aks-dev --query "provisioningState"
# Wait for "Succeeded" or cancel creation
terraform destroy
```

### ❌ Don't Skip State Cleanup After Manual Deletions

**Bad:**
```powershell
# Manually deleted resources, then ran destroy
az aks delete --resource-group ola-rg-dev --name ola-aks-dev --yes
terraform destroy  # Will fail because resource is in state but doesn't exist
```

**Good:**
```powershell
# Clean up state first
az aks delete --resource-group ola-rg-dev --name ola-aks-dev --yes
terraform state rm module.aks.azurerm_kubernetes_cluster.aks
terraform destroy
```

## 🔄 After Destroy: Prepare for Next Apply

### 1. Verify State is Clean

```powershell
terraform state list
# Should be empty or only contain backend resources
```

### 2. Clean Up Any Orphaned Resources

```powershell
# Check for orphaned resources
az resource list --resource-group ola-rg-dev -o table

# Delete orphaned resources if any
az resource delete --ids <resource-id>
```

### 3. Verify Backend is Ready

```powershell
# Check Terraform backend
terraform init

# Should show: "Terraform has been successfully initialized!"
```

### 4. Ready for Next Apply

```powershell
# Now you can safely apply again
terraform plan -var-file="envs/dev/terraform.tfvars"
terraform apply -var-file="envs/dev/terraform.tfvars"
```

## 📝 Destroy Order (What Terraform Does Automatically)

Terraform automatically destroys resources in dependency order:

1. **Kubernetes workloads** (if deployed)
2. **AKS cluster** (takes ~10-15 minutes)
3. **Operations VM and extensions**
4. **Azure Bastion**
5. **ACR and Key Vault**
6. **Private endpoints**
7. **VNet and subnets**
8. **Resource Group** (if empty)

**Total time:** ~15-20 minutes for dev environment

## 🛠️ Troubleshooting Script

If you encounter issues, use this troubleshooting script:

```powershell
# Save as: infra/terraform/troubleshoot-destroy.ps1

Write-Host "🔍 Troubleshooting Destroy Issues..." -ForegroundColor Cyan

$resourceGroup = "ola-rg-dev"

# Check AKS status
Write-Host "`n1. Checking AKS Cluster..." -ForegroundColor Yellow
az aks show --resource-group $resourceGroup --name ola-aks-dev --query "{provisioningState:provisioningState, powerState:powerState.code}" -o json 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ✅ AKS cluster doesn't exist" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  AKS cluster exists - check status above" -ForegroundColor Yellow
}

# Check for resources still being created
Write-Host "`n2. Checking for resources in 'Creating' state..." -ForegroundColor Yellow
$creating = az resource list --resource-group $resourceGroup --query "[?properties.provisioningState=='Creating'].{Name:name, Type:type}" -o table
if ($creating) {
    Write-Host "   ⚠️  Found resources still being created:" -ForegroundColor Yellow
    Write-Host $creating
} else {
    Write-Host "   ✅ No resources in 'Creating' state" -ForegroundColor Green
}

# Check Terraform state
Write-Host "`n3. Checking Terraform State..." -ForegroundColor Yellow
cd $PSScriptRoot
$stateCount = (terraform state list 2>&1 | Measure-Object -Line).Lines
Write-Host "   Found $stateCount resources in state" -ForegroundColor Gray

# Check for orphaned federated credentials
Write-Host "`n4. Checking for orphaned federated credentials..." -ForegroundColor Yellow
$federated = terraform state list 2>&1 | Select-String "federated"
if ($federated) {
    Write-Host "   ⚠️  Found federated credentials in state:" -ForegroundColor Yellow
    $federated | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
    Write-Host "`n   To fix: terraform state rm <resource-address>" -ForegroundColor Cyan
} else {
    Write-Host "   ✅ No orphaned federated credentials" -ForegroundColor Green
}

# Check Resource Group
Write-Host "`n5. Checking Resource Group..." -ForegroundColor Yellow
$rg = az group show --name $resourceGroup --query "properties.provisioningState" -o tsv 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Resource Group exists: $rg" -ForegroundColor Gray
} else {
    Write-Host "   ✅ Resource Group doesn't exist" -ForegroundColor Green
}

Write-Host "`n✅ Troubleshooting complete!" -ForegroundColor Green
```

## 📚 Additional Resources

- **TROUBLESHOOTING.md** - Section 8 (Federated Identity Credentials) and Section 9 (ContainerInsights Solution)
- **DEPLOYMENT.md** - Cleanup section
- **Azure CLI Reference**: https://learn.microsoft.com/cli/azure/

---

**Remember:** Always review the destroy plan before executing. When in doubt, use the `safe-destroy.ps1` script!
