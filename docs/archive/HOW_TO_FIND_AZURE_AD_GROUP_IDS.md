# 🔍 How to Find Your Azure AD Group Object IDs

## Quick Methods

### Method 1: Azure Portal (Easiest)
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **Groups**
3. Find your group (or create one if needed)
4. Click on the group name
5. Copy the **Object ID** from the overview page

### Method 2: Azure CLI
```bash
# List all groups
az ad group list --query "[].{Name:displayName, ObjectId:id}" --output table

# Get specific group by name
az ad group show --group "Your-Group-Name" --query id --output tsv

# Create a new group if needed
az ad group create --display-name "AKS-Cluster-Admins" --mail-nickname "AKSClusterAdmins"
# Copy the "id" from the output
```

### Method 3: PowerShell
```powershell
# List all groups
Get-AzADGroup | Select-Object DisplayName, Id | Format-Table

# Get specific group
Get-AzADGroup -DisplayName "Your-Group-Name" | Select-Object Id
```

---

## 📝 Update terraform.tfvars

Once you have your Object IDs, update line 34 in `infra/terraform/envs/dev/terraform.tfvars`:

**Replace:**
```terraform
admin_group_object_ids = [] # Example: ["00000000-0000-0000-0000-000000000000"]
```

**With:**
```terraform
admin_group_object_ids = ["YOUR-ACTUAL-OBJECT-ID-HERE"]
```

**Example:**
```terraform
admin_group_object_ids = ["a1b2c3d4-e5f6-7890-abcd-ef1234567890"]
```

---

## 🆕 Create New Groups (If Needed)

If you don't have groups yet, create them:

```bash
# Create admin group
az ad group create --display-name "AKS-Cluster-Admins" --mail-nickname "AKSClusterAdmins"

# Add yourself to the group
az ad group member add --group "AKS-Cluster-Admins" --member-id $(az ad signed-in-user show --query id -o tsv)

# Get the Object ID
az ad group show --group "AKS-Cluster-Admins" --query id --output tsv
```

---

## ✅ After Updating

1. Save the file
2. Run: `terraform validate`
3. Run: `terraform plan` to verify
4. Apply when ready
