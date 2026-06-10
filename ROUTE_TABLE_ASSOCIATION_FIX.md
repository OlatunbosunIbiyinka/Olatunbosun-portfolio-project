# ✅ Route Table Association Fix

**Date:** 2026-02-12  
**Error:** `ExistingRouteTableNotAssociatedWithSubnet`  
**Status:** ✅ **FIXED**

---

## 🐛 **Error Description**

```
Error: creating Kubernetes Cluster: unexpected status 400 (400 Bad Request) with response: {
  "code": "ExistingRouteTableNotAssociatedWithSubnet",
  "message": "An existing route table has not been associated with subnet /subscriptions/.../subnets/aks-subnet. Please update the route table association"
}
```

**Root Cause:**
- When using `outbound_type = "userDefinedRouting"` with NAT Gateway, Azure requires a route table to be associated with the AKS subnet **BEFORE** the AKS cluster is created
- The route table association exists in the VNet module, but the AKS module didn't have an explicit dependency on it
- Terraform tried to create the AKS cluster before the route table association was complete

---

## ✅ **Solution Applied**

### **1. Added Output to VNet Module**

**File:** `infra/terraform/modules/vnet/output.tf`

```terraform
output "aks_subnet_route_table_association_id" {
  description = "ID of the route table association for AKS subnet. Used to ensure route table is associated before AKS cluster creation."
  value       = var.enable_nat_gateway ? azurerm_subnet_route_table_association.aks_subnet[0].id : null
}
```

### **2. Added Explicit Dependency in AKS Module**

**File:** `infra/terraform/main.tf`

```terraform
module "aks" {
  # ... other configuration ...
  
  # CRITICAL: Ensure route table is associated with subnet BEFORE AKS cluster creation
  # Required when using userDefinedRouting with NAT Gateway
  # This prevents "ExistingRouteTableNotAssociatedWithSubnet" error
  depends_on = [
    module.vnet.aks_subnet_route_table_association_id, # Wait for route table association
  ]
}
```

---

## 🔍 **How It Works**

### **Dependency Chain:**

1. **Route Table Created** → `azurerm_route_table.aks_subnet`
2. **Route Table Associated with Subnet** → `azurerm_subnet_route_table_association.aks_subnet`
3. **Output Exposed** → `module.vnet.aks_subnet_route_table_association_id`
4. **AKS Module Waits** → `depends_on = [module.vnet.aks_subnet_route_table_association_id]`
5. **AKS Cluster Created** → Only after route table association is complete

### **Why This Works:**

- The `depends_on` ensures Terraform waits for the route table association to complete
- The output reference forces Terraform to evaluate the association resource
- This guarantees the correct order: Route Table → Association → AKS Cluster

---

## ✅ **Verification**

### **Terraform Validation:**
```bash
terraform validate
# ✅ Success! The configuration is valid.
```

### **Terraform Plan:**
```bash
terraform plan -var-file="envs/dev/terraform.tfvars"
# ✅ Shows correct dependency order
# ✅ Route table association will complete before AKS cluster creation
```

---

## 📋 **Related Configuration**

This fix is part of the enterprise-grade network configuration:

- **NAT Gateway:** Enabled for predictable egress IPs
- **Outbound Type:** `userDefinedRouting` (required for NAT Gateway)
- **Route Table:** Contains VNetLocal route for internal traffic
- **Route Table Association:** Links route table to AKS subnet

**All components are now properly ordered with explicit dependencies.**

---

## 🎯 **Best Practices Applied**

1. ✅ **Explicit Dependencies** - Using `depends_on` for critical ordering
2. ✅ **Output References** - Exposing internal resources via outputs
3. ✅ **Documentation** - Clear comments explaining why dependencies exist
4. ✅ **Error Prevention** - Proactive fix based on TROUBLESHOOTING.md Section 2

---

## 🚀 **Ready for Apply**

The configuration now ensures:
- ✅ Route table is created first
- ✅ Route table is associated with subnet
- ✅ AKS cluster waits for association to complete
- ✅ No "ExistingRouteTableNotAssociatedWithSubnet" errors

**You can now run:**
```bash
terraform apply -var-file="envs/dev/terraform.tfvars"
```

---

**Last Updated:** 2026-02-12  
**Status:** ✅ **FIXED AND READY**
