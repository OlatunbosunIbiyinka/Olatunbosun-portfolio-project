# 🔒 GitHub OIDC Security Analysis - Contributor Role Risk

**Date:** 2026-01-30  
**Status:** ⚠️ **HIGH RISK - NEEDS FIX**

---

## 🚨 Current Configuration (HIGH RISK)

### Current Setup
```terraform
github_oidc_role_assignments = ["Contributor"]
scope = azurerm_resource_group.rg.id
```

**Problem:** ⚠️ **Contributor role is TOO BROAD**

### What Contributor Role Allows
- ✅ Create, update, delete ANY resource in the resource group
- ✅ Modify network configurations
- ✅ Change security settings
- ✅ Delete resources
- ✅ Modify Key Vault secrets
- ✅ Change AKS cluster configuration
- ❌ **Too much power for CI/CD**

### Security Risk
- ❌ **Over-privileged:** Can modify/delete any resource
- ❌ **Blast radius:** If compromised, entire resource group at risk
- ❌ **Not production-grade:** Violates least privilege principle
- ❌ **Compliance risk:** Fails security audits

---

## ✅ Production-Grade Solution (Least Privilege)

### What GitHub Actions Actually Needs

Based on typical CI/CD workflows:

1. **ACR Operations:**
   - Push images: `AcrPush` role on ACR
   - Pull images: `AcrPull` role on ACR (already configured)

2. **AKS Operations:**
   - Deploy to cluster: `Azure Kubernetes Service Cluster User Role` (already configured)
   - Read cluster info: `Reader` role on AKS

3. **Terraform State (if using Storage Account):**
   - Read/write state: `Storage Blob Data Contributor` on storage account

4. **Key Vault (if needed):**
   - Read secrets: `Key Vault Secrets User` (if needed for deployments)

5. **Resource Group:**
   - Read resources: `Reader` role (minimal)

### Recommended Role Assignments

**Option 1: Minimal (Recommended for Production)**
```terraform
github_oidc_role_assignments = [
  "Reader"  # Read-only access to resource group
]
# Plus specific service-level roles:
# - AcrPush on ACR (for pushing images)
# - Already have: AcrPull, AKS Cluster User
```

**Option 2: Custom Roles (Most Secure)**
Create custom roles with only needed permissions:
- Terraform deployment permissions
- ACR push permissions
- AKS deployment permissions

---

## 📊 Role Comparison

| Role | Scope | Permissions | Risk Level |
|------|-------|-------------|------------|
| **Contributor** | Resource Group | Full control (create, update, delete) | ❌ **HIGH** |
| **Reader** | Resource Group | Read-only | ✅ **LOW** |
| **AcrPush** | ACR | Push images only | ✅ **LOW** |
| **AcrPull** | ACR | Pull images only | ✅ **LOW** |
| **AKS Cluster User** | AKS | Deploy to cluster | ✅ **LOW** |
| **Storage Blob Data Contributor** | Storage | Read/write blobs | ⚠️ **MEDIUM** |

---

## 🔧 Implementation Plan

### Step 1: Update Role Assignments

Replace `Contributor` with minimal roles:

```terraform
# In terraform.tfvars
github_oidc_role_assignments = [
  "Reader"  # Read-only access to resource group
]
```

### Step 2: Add ACR Push Role

The module already has `enable_acr_access` which grants `AcrPull`. We need to add `AcrPush` for pushing images.

### Step 3: Verify Workflow Requirements

Check what your GitHub Actions workflows actually do:
- Do they push to ACR? → Need `AcrPush`
- Do they deploy to AKS? → Already have `AKS Cluster User`
- Do they read Key Vault? → May need `Key Vault Secrets User`
- Do they use Terraform? → Need storage account access for state

---

## 🎯 Recommended Configuration

### For CI/CD Workflows

```terraform
# Minimal role assignments
github_oidc_role_assignments = [
  "Reader"  # Read-only access to resource group
]

# Service-specific roles (handled by module):
# - AcrPull: Already configured via enable_acr_access
# - AcrPush: Need to add for pushing images
# - AKS Cluster User: Already configured via enable_aks_access
```

### Module Enhancement Needed

The GitHub OIDC module should support:
1. ✅ AcrPull (already supported)
2. ❌ AcrPush (needs to be added)
3. ✅ AKS Cluster User (already supported)
4. ❌ Storage account access (if using Terraform state in storage)

---

## ✅ Security Benefits

### Before (Contributor)
- ❌ Can delete any resource
- ❌ Can modify security settings
- ❌ Can change network configurations
- ❌ Can access Key Vault secrets
- ❌ High risk if compromised

### After (Least Privilege)
- ✅ Can only read resource group
- ✅ Can push/pull ACR images (specific scope)
- ✅ Can deploy to AKS (specific scope)
- ✅ Cannot delete resources
- ✅ Cannot modify security settings
- ✅ Low risk if compromised

---

## 🚀 Next Steps

1. ✅ Update `github_oidc_role_assignments` to use `Reader` instead of `Contributor`
2. ✅ Add `AcrPush` role assignment to GitHub OIDC module
3. ✅ Verify workflow requirements
4. ✅ Test CI/CD pipeline with new permissions
5. ✅ Document required permissions

---

## 📝 Compliance & Best Practices

### Least Privilege Principle
- ✅ Grant minimum permissions needed
- ✅ Use specific service roles, not broad roles
- ✅ Scope permissions to specific resources
- ✅ Regular access reviews

### Security Standards
- ✅ Follow Azure RBAC best practices
- ✅ Align with enterprise security policies
- ✅ Pass security audits
- ✅ Reduce attack surface

---

## 🎉 Conclusion

**Current Status:** ⚠️ **HIGH RISK - Contributor role is too broad**

**Recommended Action:** ✅ **Replace with Reader + specific service roles**

This follows the principle of least privilege and is production-grade secure.
