# 🔧 Cleanup Orphan AKS Cluster

**Issue:** Terraform destroy failed because subnet `aks-subnet` is in use by an orphaned AKS cluster.

**Root Cause:**
- AKS cluster `ola-aks-dev` exists in Azure but is NOT in Terraform state (orphaned)
- Cluster is in "Failed" state
- Cluster's API server private endpoint network interface is blocking subnet deletion
- Node resource group: `MC_ola-rg-dev_ola-aks-dev_uksouth`

---

## ✅ Solution: Delete Orphan AKS Cluster

### Step 1: Delete AKS Cluster

```bash
# Delete the AKS cluster (this will also delete the node resource group)
az aks delete --resource-group ola-rg-dev --name ola-aks-dev --yes --no-wait
```

**What This Does:**
- Deletes the AKS cluster
- Automatically deletes the node resource group (`MC_ola-rg-dev_ola-aks-dev_uksouth`)
- Removes all network interfaces and resources blocking subnet deletion
- Takes 20-40 minutes (cluster deletion is long-running)

### Step 2: Monitor Deletion Progress

```bash
# Check cluster deletion status
az aks show --resource-group ola-rg-dev --name ola-aks-dev --query "provisioningState" -o tsv 2>&1

# Check node resource group (should be deleted automatically)
az group show --name MC_ola-rg-dev_ola-aks-dev_uksouth --query "properties.provisioningState" -o tsv 2>&1
```

**Expected Output:**
- First command: Error (cluster doesn't exist) or "Deleting"
- Second command: Error (resource group doesn't exist)

### Step 3: Verify Resources Are Deleted

```bash
# Verify AKS cluster is gone
az aks list --resource-group ola-rg-dev --query "[?name=='ola-aks-dev']" -o table

# Verify node resource group is gone
az group list --query "[?name=='MC_ola-rg-dev_ola-aks-dev_uksouth']" -o table

# Check subnet status (should be deletable now)
az network vnet subnet show \
  --resource-group ola-rg-dev \
  --vnet-name ola-rg-dev-vnet \
  --name aks-subnet \
  --query "{name:name, ipConfigurations:ipConfigurations}" -o json
```

### Step 4: Retry Terraform Destroy

Once the AKS cluster is deleted, retry the destroy:

```bash
cd infra/terraform
terraform destroy -var-file="envs/dev/terraform.tfvars"
```

---

## 🔍 Alternative: If Cluster Deletion Fails

If `az aks delete` fails or gets stuck, you can manually delete the node resource group:

```bash
# Delete the node resource group directly (this will delete all AKS resources)
az group delete --name MC_ola-rg-dev_ola-aks-dev_uksouth --yes --no-wait

# Then delete the AKS cluster resource (if it still exists)
az aks delete --resource-group ola-rg-dev --name ola-aks-dev --yes --no-wait
```

**⚠️ Warning:** Only use this if the normal deletion process fails. Deleting the node resource group directly can leave the AKS cluster resource in a bad state.

---

## 📋 Why This Happened

**Possible Causes:**
1. Previous `terraform apply` failed after creating the cluster but before updating state
2. Cluster was created manually outside of Terraform
3. Terraform state was lost or corrupted
4. Cluster creation succeeded but state save failed (see TROUBLESHOOTING.md Section 15)

**Prevention:**
- Always verify `terraform apply` completes successfully
- Check state after apply: `terraform state list | grep aks`
- If apply fails, check Azure Portal to see what was created
- Use `terraform import` if resources exist but aren't in state

---

## ✅ Verification Checklist

After cleanup, verify:

- [ ] AKS cluster is deleted: `az aks show --resource-group ola-rg-dev --name ola-aks-dev` returns error
- [ ] Node resource group is deleted: `az group show --name MC_ola-rg-dev_ola-aks-dev_uksouth` returns error
- [ ] Subnet is deletable: No network interfaces blocking deletion
- [ ] Terraform destroy can proceed: No "InUseSubnetCannotBeDeleted" errors

---

## 🚀 Next Steps After Cleanup

Once the orphan cluster is deleted and `terraform destroy` completes:

1. **Verify all resources are deleted:**
   ```bash
   az group show --name ola-rg-dev --query "properties.provisioningState" -o tsv
   ```

2. **If you want to redeploy:**
   ```bash
   cd infra/terraform
   terraform apply -var-file="envs/dev/terraform.tfvars"
   ```

3. **Monitor the new cluster creation:**
   - Initial creation takes 120-180+ minutes
   - Timeout is set to 240 minutes (sufficient)
   - All remedies are integrated (see APPLY_STATUS_REPORT.md)

---

**Last Updated:** 2026-02-12  
**Status:** ✅ Cleanup in progress
