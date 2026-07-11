# 🔐 Azure AD Group Object IDs Setup Guide

**Date:** 2026-01-30  
**Purpose:** Configure AKS cluster admin access with Azure AD groups

---

## 📋 Current Configuration

**Current Status:**
```terraform
admin_group_object_ids = []  # Empty - needs to be configured
operator_group_object_ids = []  # Empty - needs to be configured
```

---

## 🎯 What You Need

### Admin Group Object IDs
- **Purpose:** Full administrative access to AKS cluster
- **Role:** `Azure Kubernetes Service Cluster Admin Role`
- **Access:** Can manage cluster, deploy applications, manage RBAC

### Operator Group Object IDs (Optional)
- **Purpose:** Read-only access to AKS cluster
- **Role:** `Azure Kubernetes Service Cluster User Role`
- **Access:** Can view cluster resources, but cannot modify

---

## 🔍 How to Find Your Azure AD Group Object IDs

### Option 1: Using Azure CLI

```bash
# List all Azure AD groups
az ad group list --query "[].{DisplayName:displayName, ObjectId:id}" --output table

# Get specific group by name
az ad group show --group "Your-Group-Name" --query id --output tsv

# Get groups for current user
az ad user get-member-groups --id $(az ad signed-in-user show --query id -o tsv) --query "[].{DisplayName:displayName, ObjectId:id}" --output table
```

### Option 2: Using Azure Portal

1. Go to **Azure Active Directory** → **Groups**
2. Find your group
3. Click on the group
4. Copy the **Object ID** from the overview page

### Option 3: Create New Groups

If you don't have groups yet, create them:

```bash
# Create admin group
az ad group create --display-name "AKS-Cluster-Admins" --mail-nickname "AKSClusterAdmins"
# Note the Object ID from output

# Create operator group (optional)
az ad group create --display-name "AKS-Cluster-Operators" --mail-nickname "AKSClusterOperators"
# Note the Object ID from output

# Add yourself to the admin group
az ad group member add --group "AKS-Cluster-Admins" --member-id $(az ad signed-in-user show --query id -o tsv)
```

---

## ✅ Update Configuration

Once you have your Azure AD group object IDs, update `terraform.tfvars`:

```terraform
# Security Configuration
enable_azure_policy    = true
disable_local_accounts = true
enable_azure_rbac      = true

# Add Azure AD group object IDs for cluster admin access
admin_group_object_ids = [
  "YOUR-ADMIN-GROUP-OBJECT-ID-1",
  "YOUR-ADMIN-GROUP-OBJECT-ID-2"  # Optional: multiple groups
]

# Add Azure AD group object IDs for cluster operator access (read-only)
operator_group_object_ids = [
  "YOUR-OPERATOR-GROUP-OBJECT-ID"  # Optional: read-only access
]
```

---

## 🔒 Security Best Practices

### ✅ Recommended Setup

1. **Admin Group:**
   - Create dedicated group: `AKS-Cluster-Admins`
   - Add only trusted administrators
   - Use for full cluster management

2. **Operator Group (Optional):**
   - Create dedicated group: `AKS-Cluster-Operators`
   - Add developers/operators who need read access
   - Use for monitoring and troubleshooting

3. **Least Privilege:**
   - Don't add users directly to admin group
   - Use groups for easier management
   - Regular access reviews

---

## 📝 Example Configuration

```terraform
# Example with real Azure AD group object IDs
admin_group_object_ids = [
  "a1b2c3d4-e5f6-7890-abcd-ef1234567890"  # AKS-Cluster-Admins group
]

operator_group_object_ids = [
  "b2c3d4e5-f6a7-8901-bcde-f12345678901"  # AKS-Cluster-Operators group
]
```

---

## 🚀 After Configuration

Once you've updated the object IDs:

1. **Validate Configuration:**
   ```bash
   cd infra/terraform
   terraform validate
   ```

2. **Review Plan:**
   ```bash
   terraform plan -var-file="envs/dev/terraform.tfvars"
   ```

3. **Apply Changes:**
   ```bash
   terraform apply -var-file="envs/dev/terraform.tfvars"
   ```

---

## 🔍 Verify Access

After deployment, verify access:

```bash
# Get AKS credentials
az aks get-credentials --name ola-aks-dev --resource-group ola-rg-dev

# Test access (should work if you're in admin group)
kubectl get nodes
kubectl get namespaces
```

---

## ⚠️ Important Notes

1. **Azure RBAC Must Be Enabled:**
   - `enable_azure_rbac = true` (already configured ✅)

2. **Local Accounts Disabled:**
   - `disable_local_accounts = true` (already configured ✅)
   - This means ONLY Azure AD groups can access the cluster

3. **Private Cluster:**
   - If using private cluster, access via VPN/Bastion
   - Azure AD authentication still works from VNet

---

## 🎉 Next Steps

1. ✅ Find or create your Azure AD groups
2. ✅ Get the Object IDs
3. ✅ Update `terraform.tfvars` with real Object IDs
4. ✅ Validate and apply configuration
5. ✅ Test access to AKS cluster

---

## 📚 Related Documentation

- [Azure AD Integration with AKS](https://docs.microsoft.com/azure/aks/manage-azure-rbac)
- [AKS RBAC Best Practices](https://docs.microsoft.com/azure/aks/operator-best-practices-identity)
- [Azure AD Groups](https://docs.microsoft.com/azure/active-directory/fundamentals/active-directory-groups-create-azure-portal)
