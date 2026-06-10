# ✅ GitHub OIDC Security Fix - Contributor to Least Privilege

**Date:** 2026-01-30  
**Status:** ✅ **ENTERPRISE-GRADE SECURITY ENABLED**

---

## 🚨 Issue Identified

**Before Fix:**
```terraform
github_oidc_role_assignments = ["Contributor"]
scope = azurerm_resource_group.rg.id
```

**Problem:** ⚠️ **Contributor role is TOO BROAD and HIGH RISK**

### What Contributor Role Allows
- ❌ Create, update, delete ANY resource in resource group
- ❌ Modify network configurations
- ❌ Change security settings
- ❌ Delete resources
- ❌ Modify Key Vault secrets
- ❌ Change AKS cluster configuration
- ❌ **Too much power for CI/CD**

---

## ✅ Fix Applied

### Changes Made

1. **Replaced Contributor with Reader** (`terraform.tfvars`)
   ```terraform
   # Before:
   github_oidc_role_assignments = ["Contributor"]
   
   # After:
   github_oidc_role_assignments = ["Reader"]  # Enterprise-grade: Least privilege
   ```

2. **Added AcrPush Role** (`modules/github-oidc/main.tf`)
   ```terraform
   # New: Grant ACR push permissions for CI/CD to push images
   resource "azurerm_role_assignment" "acr_push" {
     count = var.enable_acr_push ? 1 : 0
     scope                = var.acr_id
     role_definition_name = "AcrPush"
     principal_id         = azuread_service_principal.github_actions.object_id
   }
   ```

3. **Updated Module Variables** (`modules/github-oidc/variables.tf`)
   ```terraform
   variable "enable_acr_push" {
     description = "Enable ACR push permissions for GitHub Actions to push images"
     type        = bool
     default     = false
   }
   ```

4. **Updated Main Configuration** (`main.tf`)
   ```terraform
   module "github_oidc" {
     # ... existing configuration ...
     enable_acr_access = true  # Pull images for security scans
     enable_acr_push   = true  # Push images for CI/CD (enterprise-grade: specific role)
     # ... rest of configuration ...
   }
   ```

5. **Updated Default Variable** (`variables.tf`)
   ```terraform
   variable "github_oidc_role_assignments" {
     default = ["Reader"]  # Enterprise-grade: Least privilege (was Contributor)
   }
   ```

---

## 📊 Role Comparison

| Role | Scope | Permissions | Risk Level |
|------|-------|-------------|------------|
| **Contributor** (Before) | Resource Group | Full control (create, update, delete) | ❌ **HIGH** |
| **Reader** (After) | Resource Group | Read-only | ✅ **LOW** |
| **AcrPush** (New) | ACR | Push images only | ✅ **LOW** |
| **AcrPull** (Existing) | ACR | Pull images only | ✅ **LOW** |
| **AKS Cluster User** (Existing) | AKS | Deploy to cluster | ✅ **LOW** |

---

## ✅ Final Role Assignments

### Resource Group Level
- ✅ **Reader** - Read-only access to resource group

### Service-Specific Roles
- ✅ **AcrPull** - Pull images from ACR (for security scans)
- ✅ **AcrPush** - Push images to ACR (for CI/CD)
- ✅ **AKS Cluster User Role** - Deploy to AKS cluster

---

## 🔒 Security Benefits

### Before (Contributor)
```
❌ Can delete any resource
❌ Can modify security settings
❌ Can change network configurations
❌ Can access Key Vault secrets
❌ Can modify AKS cluster
❌ High risk if compromised
❌ Blast radius: Entire resource group
```

### After (Least Privilege)
```
✅ Can only read resource group
✅ Can push/pull ACR images (specific scope)
✅ Can deploy to AKS (specific scope)
✅ Cannot delete resources
✅ Cannot modify security settings
✅ Cannot change network configurations
✅ Low risk if compromised
✅ Blast radius: Limited to specific services
```

---

## 🎯 Workflow Requirements Analysis

### CI Pipeline Needs
- ✅ **AcrPush** - Push images to ACR
- ✅ **AcrPull** - Pull images (for verification)

### Deploy Pipeline Needs
- ✅ **AKS Cluster User Role** - Deploy to AKS
- ✅ **Reader** - Read resource group info

### Security Pipeline Needs
- ✅ **AcrPull** - Pull images for scanning

**All requirements met with least privilege!** ✅

---

## 📋 Configuration Summary

### Current Configuration
```terraform
# Resource Group Level (Minimal)
github_oidc_role_assignments = ["Reader"]

# Service-Specific Roles (Granted Separately)
enable_acr_access = true   # AcrPull
enable_acr_push   = true   # AcrPush
enable_aks_access = true   # AKS Cluster User Role
```

### Result
- ✅ **Reader** on resource group (read-only)
- ✅ **AcrPush** on ACR (push images)
- ✅ **AcrPull** on ACR (pull images)
- ✅ **AKS Cluster User Role** on AKS (deploy)
- ✅ **Enterprise-Grade:** Least privilege principle

---

## ✅ Validation

### Terraform Validation
```bash
terraform validate
# ✅ Success! The configuration is valid.
```

### Security Checklist
- [x] Contributor role removed
- [x] Reader role added (least privilege)
- [x] AcrPush role added for CI/CD
- [x] AcrPull role maintained
- [x] AKS Cluster User role maintained
- [x] All workflow requirements met
- [x] Enterprise-grade security enabled

---

## 🎉 Conclusion

**Status:** ✅ **ENTERPRISE-GRADE SECURITY ENABLED**

Your GitHub OIDC configuration now follows:
- ✅ **Least Privilege Principle**
- ✅ **Specific Service Roles** (not broad roles)
- ✅ **Production-Grade Security**
- ✅ **Compliance Ready**

**The Contributor role risk has been eliminated!** 🔒

---

## 📝 Best Practices Applied

1. ✅ **Least Privilege:** Grant minimum permissions needed
2. ✅ **Specific Roles:** Use service-specific roles, not broad roles
3. ✅ **Scope Limitation:** Scope permissions to specific resources
4. ✅ **Separation of Concerns:** Different roles for different operations
5. ✅ **Security by Design:** Built-in security from the start

---

## 🔗 Related Documentation

- [Azure RBAC Best Practices](https://docs.microsoft.com/azure/role-based-access-control/best-practices)
- [Least Privilege Principle](https://docs.microsoft.com/azure/security/fundamentals/identity-management-best-practices)
- [GitHub Actions OIDC](https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
