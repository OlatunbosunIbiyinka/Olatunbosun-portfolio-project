# 🔧 Adding Taints to Default Node Pool

**Date:** 2026-01-30  
**Purpose:** Add taints to default node pool after Terraform deployment

---

## ⚠️ Terraform Limitation

The `default_node_pool` block in `azurerm_kubernetes_cluster` **does not support** `mode` or `node_taints` arguments. These are only available for additional node pools created with `azurerm_kubernetes_cluster_node_pool`.

---

## ✅ Solution: Add Taints via kubectl

After deploying the cluster with Terraform, add taints to the default node pool nodes using `kubectl`:

### Step 1: Get AKS Credentials

```bash
az aks get-credentials --name ola-aks-dev --resource-group ola-rg-dev
```

### Step 2: Add Taint to System Pool Nodes

```bash
# Add taint to all nodes in the system pool
kubectl taint nodes -l kubernetes.azure.com/mode=system \
  CriticalAddonsOnly=true:NoSchedule \
  --overwrite
```

### Step 3: Verify Taints

```bash
# Check node taints
kubectl get nodes -l kubernetes.azure.com/mode=system \
  -o jsonpath='{.items[*].spec.taints}'

# Expected output:
# [{"effect":"NoSchedule","key":"CriticalAddonsOnly","value":"true"}]
```

---

## 🔄 Alternative: Create Dedicated System Pool

For true production-grade separation, create a dedicated system node pool as an additional pool:

### 1. Update terraform.tfvars

```terraform
# Create dedicated system pool
workload_node_pools = {
  "system" = {
    vm_size             = "Standard_D2s_v3"
    node_count          = 1
    os_disk_size_gb     = 128
    os_sku              = "Ubuntu"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    max_pods            = 30
    node_labels = {
      "kubernetes.azure.com/mode" = "system"
      "node.kubernetes.io/role"   = "system"
    }
    node_taints = ["CriticalAddonsOnly=true:NoSchedule"]
    mode        = "System"  # System mode for system pods
  }
  "workload" = {
    # ... workload pool config ...
    mode = "User"
  }
}
```

### 2. Remove Default Pool (Optional)

After creating the dedicated system pool, you can remove the default pool:

```bash
# Delete default node pool (after system pool is created)
az aks nodepool delete \
  --cluster-name ola-aks-dev \
  --resource-group ola-rg-dev \
  --name system  # or whatever the default pool name is
```

**⚠️ Warning:** Only do this if you have a dedicated system pool already created!

---

## 📝 Recommended Approach

**For Production:**
1. ✅ Keep default pool minimal (1-2 nodes, small VM size)
2. ✅ Create dedicated system pool with mode="System" and taints
3. ✅ Create workload pools with mode="User"
4. ✅ Optionally remove default pool after system pool is ready

**For Development:**
1. ✅ Use default pool with labels (no taints needed)
2. ✅ Create workload pool for applications
3. ✅ Add taints via kubectl if needed

---

## 🔍 Verify Node Pool Configuration

```bash
# List all node pools
az aks nodepool list \
  --cluster-name ola-aks-dev \
  --resource-group ola-rg-dev

# Check node labels and taints
kubectl get nodes --show-labels
kubectl describe nodes | grep -A 5 Taints
```

---

## 📚 References

- [AKS Node Pool Modes](https://docs.microsoft.com/azure/aks/use-system-pools)
- [Kubernetes Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Terraform azurerm_kubernetes_cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)
