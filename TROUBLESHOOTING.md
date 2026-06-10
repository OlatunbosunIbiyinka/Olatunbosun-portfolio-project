# 🔧 Troubleshooting Guide

This document contains common errors encountered during Terraform deployment and their solutions. Each entry includes:
- **Error Message**: The exact error you'll see
- **Why It Happens**: Explanation of the root cause
- **How to Fix**: Step-by-step solution
- **Prevention**: How to avoid this issue in the future

---

## Table of Contents

1. [Service CIDR Overlap with Subnet CIDR](#1-service-cidr-overlap-with-subnet-cidr)
2. [Route Table Not Associated with Subnet](#2-route-table-not-associated-with-subnet)
3. [Invalid Node Label Key (Reserved Prefix)](#3-invalid-node-label-key-reserved-prefix)
4. [Autoscaling Configuration Error](#4-autoscaling-configuration-error)
5. [ACR Network Rule Bypass Configuration](#5-acr-network-rule-bypass-configuration)
6. [Cilium Network Policy Requires Cilium Dataplane](#6-cilium-network-policy-requires-cilium-dataplane)
7. [kubelogin Not Found (Azure AD RBAC)](#7-kubelogin-not-found-azure-ad-rbac)
8. [404 Error During Terraform Destroy (Federated Identity Credential)](#8-404-error-during-terraform-destroy-federated-identity-credential)
9. [Resource Group Deletion Blocked by ContainerInsights Solution](#9-resource-group-deletion-blocked-by-containerinsights-solution)
10. [AKS Node Pool Update Timeout (Context Deadline Exceeded)](#10-aks-node-pool-update-timeout-context-deadline-exceeded)
11. [Cannot Connect to Private AKS Cluster (DNS Resolution Failure)](#11-cannot-connect-to-private-aks-cluster-dns-resolution-failure)
12. [Jumpbox VM Extension Script Failure (unzip/kubelogin path)](#12-jumpbox-vm-extension-script-failure-unzipkubelogin-path)
13. [Resource Already Exists (Import into State)](#13-resource-already-exists-import-into-state)
14. [AKS Node Pool Operation Conflict (409 - Operation In Progress)](#14-aks-node-pool-operation-conflict-409---operation-in-progress)
15. [Terraform State Save Failure (DNS Resolution Error)](#15-terraform-state-save-failure-dns-resolution-error)
16. [Starting Fresh After Manual Resource Deletion](#16-starting-fresh-after-manual-resource-deletion)

---

## 1. Service CIDR Overlap with Subnet CIDR

### Error Message
```
Error: creating Kubernetes Cluster: unexpected status 400 (400 Bad Request) with response: {
  "code": "ServiceCidrOverlapExistingSubnetsCidr",
  "message": "The specified service CIDR 10.0.0.0/16 is conflicted with an existing subnet CIDR 10.0.2.0/24. Please see https://aka.ms/aks/servicecidroverlap for how to fix the error.",
  "target": "networkProfile.serviceCIDR"
}
```

### Why It Happens

**Root Cause:**
- The Kubernetes service CIDR (used for ClusterIP services) overlaps with your VNet subnet CIDR ranges
- In this case: `service_cidr = "10.0.0.0/16"` overlaps with the private endpoints subnet `10.0.2.0/24`
- Since `10.0.2.0/24` is within the `10.0.0.0/16` range, Azure rejects the configuration

**Why This Matters:**
- Kubernetes services need their own IP address space that doesn't conflict with:
  - VNet address space
  - Subnet CIDRs (AKS subnet, private endpoints subnet, etc.)
  - Pod CIDR (for overlay mode)
- If there's overlap, Kubernetes can't properly route traffic to services

**Common Scenario:**
- VNet: `10.0.0.0/16`
- AKS Subnet: `10.0.1.0/24`
- Private Endpoints Subnet: `10.0.2.0/24`
- Service CIDR: `10.0.0.0/16` ❌ **OVERLAPS!**

### How to Fix

**Step 1: Identify Your Current CIDR Ranges**
```bash
# Check your VNet and subnet configurations
grep -r "address_space\|address_prefixes\|service_cidr" infra/terraform/
```

**Step 2: Choose a Non-Overlapping Service CIDR**
- VNet: `10.0.0.0/16` (covers 10.0.0.0 - 10.0.255.255)
- Service CIDR must be outside this range
- **Recommended:** `10.1.0.0/16` or `172.16.0.0/16`

**Step 3: Update the Configuration**

**File:** `infra/terraform/modules/aks/variables.tf`
```terraform
variable "service_cidr" {
  description = "CIDR for Kubernetes services. Must NOT overlap with VNet subnets."
  type        = string
  default     = "10.1.0.0/16"  # Changed from 10.0.0.0/16
}
```

**Step 4: Update DNS Service IP**
The DNS service IP must be within the new service CIDR:

**File:** `infra/terraform/modules/aks/variables.tf`
```terraform
variable "dns_service_ip" {
  description = "DNS service IP (must be within service CIDR)"
  type        = string
  default     = "10.1.0.10"  # Updated to match new service_cidr
}
```

**Step 5: Validate and Apply**
```bash
cd infra/terraform
terraform validate
terraform plan -var-file="envs/dev/terraform.tfvars"
terraform apply
```

### Prevention

**Best Practices:**
1. **Plan Your IP Address Space:**
   ```
   VNet:           10.0.0.0/16     (65,536 IPs)
   ├─ AKS Subnet:  10.0.1.0/24     (256 IPs)
   ├─ PE Subnet:   10.0.2.0/24     (256 IPs)
   ├─ Service CIDR: 10.1.0.0/16    (65,536 IPs) ✅ Non-overlapping
   └─ Pod CIDR:    10.244.0.0/16   (65,536 IPs) ✅ Non-overlapping
   ```

2. **Use Different IP Ranges:**
   - VNet: `10.0.0.0/16`
   - Service CIDR: `10.1.0.0/16` or `172.16.0.0/16`
   - Pod CIDR: `10.244.0.0/16` (standard for overlay mode)

3. **Document Your IP Plan:**
   - Keep a spreadsheet or document with all IP ranges
   - Include: VNet, subnets, service CIDR, pod CIDR, DNS service IP

4. **Validate Before Deploying:**
   ```bash
   # Use a CIDR calculator to verify no overlaps
   # Online tool: https://www.subnet-calculator.com/
   ```

---

## 2. Route Table Not Associated with Subnet

### Error Message
```
Error: creating Kubernetes Cluster: unexpected status 400 (400 Bad Request) with response: {
  "code": "ExistingRouteTableNotAssociatedWithSubnet",
  "message": "An existing route table has not been associated with subnet /subscriptions/.../subnets/aks-subnet. Please update the route table association"
}
```

### Why It Happens

**Root Cause:**
- When using `outbound_type = "userDefinedRouting"` (required for NAT Gateway), Azure requires a route table to be associated with the AKS subnet
- The route table must be associated **before** the AKS cluster is created
- If the route table exists but isn't associated, or if the association happens after cluster creation, this error occurs

**Why This Matters:**
- `userDefinedRouting` tells AKS to use custom routing instead of the default load balancer
- Azure needs to know how to route outbound traffic (via NAT Gateway)
- Without a route table association, Azure can't configure the routing properly

**Common Scenario:**
- NAT Gateway is configured
- `outbound_type = "userDefinedRouting"` is set
- Route table exists but isn't associated with the subnet
- AKS cluster creation fails

### How to Fix

**Step 1: Create Route Table**

**File:** `infra/terraform/modules/vnet/main.tf`
```terraform
# Route Table for AKS subnet (required for userDefinedRouting)
resource "azurerm_route_table" "aks_subnet" {
  count               = var.enable_nat_gateway ? 1 : 0
  name                = "${var.aks_subnet_name}-route-table"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}
```

**Step 2: Associate Route Table with Subnet**

**File:** `infra/terraform/modules/vnet/main.tf`
```terraform
# Associate Route Table with AKS subnet
# Required for userDefinedRouting outbound type
# This must be done BEFORE NAT Gateway association
resource "azurerm_subnet_route_table_association" "aks_subnet" {
  count          = var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.aks_subnet.id
  route_table_id = azurerm_route_table.aks_subnet[0].id
  
  depends_on = [azurerm_route_table.aks_subnet]
}
```

**Step 3: Ensure Proper Dependency Ordering**

**File:** `infra/terraform/modules/vnet/main.tf`
```terraform
# Associate NAT Gateway with AKS subnet
# Must be done AFTER route table association
resource "azurerm_subnet_nat_gateway_association" "aks_subnet" {
  count          = var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.aks_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[0].id
  
  # Ensure route table is associated first
  depends_on = [azurerm_subnet_route_table_association.aks_subnet]
}
```

**Step 4: Apply Changes**
```bash
cd infra/terraform
terraform plan -var-file="envs/dev/terraform.tfvars"
terraform apply
```

### Prevention

**Best Practices:**
1. **Always create route table when using NAT Gateway:**
   - If `enable_nat_gateway = true` and `outbound_type = "userDefinedRouting"`, create route table

2. **Follow Correct Order:**
   - Create route table
   - Associate route table with subnet
   - Associate NAT Gateway with subnet

3. **Use Dependencies:**
   - Use `depends_on` to ensure proper resource ordering
   - Terraform will handle the sequence automatically

---

## 3. Invalid Node Label Key (Reserved Prefix)

### Error Message
```
Error: creating Kubernetes Cluster: unexpected status 400 (400 Bad Request) with response: {
  "code": "BadRequest",
  "message": "Invalid node label key kubernetes.azure.com/mode. The 'kubernetes.azure.com' prefix is preserved by aks system labels"
}
```

### Why It Happens

**Root Cause:**
- Azure Kubernetes Service (AKS) reserves the `kubernetes.azure.com/*` prefix for system labels
- You cannot use custom labels with this prefix
- Common mistake: trying to use `kubernetes.azure.com/mode` to identify system vs user node pools

**Why This Matters:**
- AKS uses these reserved labels internally for cluster management
- Using reserved prefixes can cause conflicts and unpredictable behavior
- Custom labels must use different prefixes

**Common Scenario:**
- Trying to label nodes as system vs user pools
- Using `kubernetes.azure.com/mode = "system"` or `kubernetes.azure.com/mode = "user"`
- AKS rejects the configuration

### How to Fix

**Step 1: Identify Reserved Prefixes**
- `kubernetes.azure.com/*` - Reserved by AKS
- `kubernetes.io/*` - Reserved by Kubernetes (but some are allowed)
- `node.kubernetes.io/*` - Some are allowed, some reserved

**Step 2: Use Custom Labels Instead**

**File:** `infra/terraform/modules/aks/main.tf`
```terraform
# ❌ WRONG - Reserved prefix
node_labels = {
  "kubernetes.azure.com/mode" = "system"  # ❌ ERROR!
}

# ✅ CORRECT - Custom labels
node_labels = {
  "node.kubernetes.io/role" = "system"     # ✅ Allowed
  "pool.type"               = "system"      # ✅ Custom label
  "workload.type"           = "system"      # ✅ Custom label
}
```

**Step 3: Update All Node Pool Configurations**

**Default Node Pool:**
```terraform
node_labels = merge(
  {
    "node.kubernetes.io/role" = "system"
    "pool.type"               = "system"
    "workload.type"           = "system"
  },
  var.node_labels
)
```

**Workload Node Pools:**
```terraform
node_labels = {
  "node.kubernetes.io/role" = "workload"
  "pool.type"               = "user"
  "workload.type"           = "application"
  "workload"                = "application"
}
```

**Step 4: Update terraform.tfvars**

**File:** `infra/terraform/envs/dev/terraform.tfvars`
```terraform
workload_node_pools = {
  "workload" = {
    # ... other config ...
    node_labels = {
      "node.kubernetes.io/role" = "workload"
      "pool.type"               = "user"        # ✅ Custom label
      "workload.type"           = "application" # ✅ Custom label
    }
  }
}
```

### Prevention

**Best Practices:**
1. **Never Use Reserved Prefixes:**
   - ❌ `kubernetes.azure.com/*`
   - ✅ `pool.type`, `workload.type`, `environment`, etc.

2. **Use Standard Kubernetes Labels When Possible:**
   - ✅ `node.kubernetes.io/role` (allowed)
   - ✅ `kubernetes.io/arch` (allowed)
   - ❌ `kubernetes.io/hostname` (reserved)

3. **Document Your Labeling Strategy:**
   - Create a label naming convention document
   - Use consistent prefixes: `pool.*`, `workload.*`, `team.*`

4. **Validate Labels Before Deployment:**
   ```bash
   # Check for reserved prefixes
   grep -r "kubernetes.azure.com" infra/terraform/
   ```

---

## 4. Autoscaling Configuration Error

### Error Message
```
Error: expanding `default_node_pool`: `max_count`(3) and `min_count`(1) must be set to `null` when `auto_scaling_enabled` is set to `false`
```

### Why It Happens

**Root Cause:**
- When `auto_scaling_enabled = false`, you must use `node_count` (fixed count)
- When `auto_scaling_enabled = true`, you must use `min_count` and `max_count` (and `node_count = null`)
- The configuration had both `node_count` and `min_count`/`max_count` set, or had the wrong combination

**Why This Matters:**
- Azure enforces strict rules for node pool configuration
- You can't mix fixed count with autoscaling settings
- The configuration must be mutually exclusive

**Common Scenario:**
- `auto_scaling_enabled = true` but `node_count` is also set
- Or `auto_scaling_enabled = false` but `min_count`/`max_count` are set

### How to Fix

**Step 1: Add Explicit `auto_scaling_enabled` Field**

**File:** `infra/terraform/modules/aks/main.tf`
```terraform
default_node_pool {
  name                 = var.default_node_pool_name
  auto_scaling_enabled = var.enable_auto_scaling  # ✅ Explicit field
  
  # When autoscaling is enabled: node_count must be null, min_count and max_count must be set
  # When autoscaling is disabled: node_count must be set, min_count and max_count must be null
  node_count = var.enable_auto_scaling ? null : var.default_node_pool_node_count
  min_count  = var.enable_auto_scaling ? var.min_node_count : null
  max_count  = var.enable_auto_scaling ? var.max_node_count : null
}
```

**Step 2: Apply Same Logic to Additional Node Pools**

**File:** `infra/terraform/modules/aks/main.tf`
```terraform
resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  for_each = var.additional_node_pools

  auto_scaling_enabled = each.value.enable_auto_scaling  # ✅ Explicit field
  
  # Conditional configuration
  node_count = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count  = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count  = each.value.enable_auto_scaling ? each.value.max_count : null
}
```

**Step 3: Verify Configuration**

**When Autoscaling Enabled:**
```terraform
enable_auto_scaling = true
node_count          = null      # ✅ Must be null
min_count           = 1         # ✅ Must be set
max_count           = 3         # ✅ Must be set
```

**When Autoscaling Disabled:**
```terraform
enable_auto_scaling = false
node_count          = 2         # ✅ Must be set
min_count           = null      # ✅ Must be null
max_count           = null      # ✅ Must be null
```

### Prevention

**Best Practices:**
1. **Always Use Conditional Logic:**
   ```terraform
   node_count = var.enable_auto_scaling ? null : var.node_count
   min_count  = var.enable_auto_scaling ? var.min_count : null
   max_count  = var.enable_auto_scaling ? var.max_count : null
   ```

2. **Explicitly Set `auto_scaling_enabled`:**
   - Don't rely on implicit behavior
   - Always set the field explicitly

3. **Validate Configuration:**
   ```bash
   terraform validate
   terraform plan  # Check the plan output
   ```

---

## 5. ACR Network Rule Bypass Configuration

### Error Message
```
Error: Unsupported argument. An argument named "network_rule_bypass" is not expected here.
```

### Why It Happens

**Root Cause:**
- The `network_rule_bypass_option` argument is a top-level property of `azurerm_container_registry`, not within the `network_rule_set` block
- It was incorrectly placed inside the `network_rule_set` block

**Why This Matters:**
- `network_rule_bypass_option` controls whether Azure services can bypass network rules
- For enterprise-grade security, this should be set to `"None"` to enforce strict network isolation
- The argument must be at the correct level in the resource block

### How to Fix

**Step 1: Move `network_rule_bypass_option` to Top Level**

**File:** `infra/terraform/modules/acr/main.tf`
```terraform
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  
  # ✅ CORRECT: Top-level property
  network_rule_bypass_option = var.network_rule_bypass
  
  # Network rules (separate block)
  dynamic "network_rule_set" {
    for_each = var.public_network_access_enabled && length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      default_action = "Deny"
      # ... ip rules ...
    }
  }
}
```

**Step 2: Add Variable**

**File:** `infra/terraform/modules/acr/variables.tf`
```terraform
variable "network_rule_bypass" {
  description = "Network rule bypass option. Enterprise-grade: 'None' prevents Azure services from bypassing network rules"
  type        = string
  default     = "None"
  validation {
    condition     = contains(["AzureServices", "None"], var.network_rule_bypass)
    error_message = "network_rule_bypass must be 'AzureServices' or 'None'."
  }
}
```

### Prevention

**Best Practices:**
1. **Read Terraform Provider Documentation:**
   - Check the exact location of arguments
   - Use `terraform fmt` to catch formatting issues

2. **Use `terraform validate`:**
   ```bash
   terraform validate  # Catches syntax errors
   ```

3. **Check Resource Schema:**
   ```bash
   terraform providers schema -json | jq '.provider_schemas."registry.terraform.io/hashicorp/azurerm".resource_schemas."azurerm_container_registry".block.attributes'
   ```

---

## 6. Cilium Network Policy Requires Cilium Dataplane

### Error Message
```
Error: creating Agent Pool: unexpected status 400 (400 Bad Request) with response: {
  "code": "NetworkPolicyNotSupported",
  "message": "NetworkPolicy cilium requires NetworkDataplane cilium",
  "subcode": "NetworkPolicyCiliumRequiresCiliumDataplane",
  "target": "networkProfile.networkPolicy"
}
```

### Why It Happens

**Root Cause:**
- When using Cilium as the network policy engine (`network_policy = "cilium"`), Azure requires that the network dataplane also be set to Cilium (`network_dataplane = "cilium"`)
- The `network_dataplane` field was missing from the `network_profile` block
- Azure enforces this requirement because Cilium network policies require the Cilium dataplane to function properly

**Why This Matters:**
- Cilium is an eBPF-based networking and security solution that provides:
  - Advanced network policies (Layer 7 policies, DNS-based policies)
  - Network observability (Hubble)
  - Service mesh capabilities
- The network dataplane controls how packets are processed and routed
- Cilium network policies can only be enforced by the Cilium dataplane
- Using Azure's default dataplane with Cilium policies would cause conflicts

**Common Scenario:**
- `network_policy = "cilium"` is set (for advanced network policies)
- `network_dataplane` is missing or set to `"azure"` (default)
- Azure rejects the configuration because Cilium policies require Cilium dataplane

### How to Fix

**Step 1: Add `network_dataplane` Variable**

**File:** `infra/terraform/modules/aks/variables.tf`
```terraform
variable "network_dataplane" {
  description = "Network dataplane. REQUIRED: Must be 'cilium' when network_policy = 'cilium'. Enterprise-grade: Use 'cilium' for Cilium dataplane."
  type        = string
  default     = "cilium"
  validation {
    condition     = contains(["azure", "cilium"], var.network_dataplane)
    error_message = "network_dataplane must be 'azure' or 'cilium'."
  }
}
```

**Step 2: Add `network_dataplane` to Network Profile**

**File:** `infra/terraform/modules/aks/main.tf`
```terraform
network_profile {
  network_plugin      = var.network_plugin
  network_plugin_mode = var.network_plugin_mode
  network_policy      = var.network_policy      # "cilium"
  network_data_plane  = var.network_dataplane   # REQUIRED: "cilium" when network_policy = "cilium" (note: underscore in attribute name)
  load_balancer_sku   = var.load_balancer_sku
  outbound_type       = var.outbound_type
  service_cidr        = var.service_cidr
  dns_service_ip      = var.dns_service_ip
  pod_cidr            = var.pod_cidr
}
```

**Important Note:** The Terraform attribute name is `network_data_plane` (with underscore), not `network_dataplane`. The variable name can be `network_dataplane` (without underscore) for consistency, but the resource attribute must use the underscore.

**Step 3: Add Variable to Root Variables**

**File:** `infra/terraform/variables.tf`
```terraform
variable "network_dataplane" {
  description = "Network dataplane. REQUIRED: Must be 'cilium' when network_policy = 'cilium'."
  type        = string
  default     = "cilium"
  validation {
    condition     = contains(["azure", "cilium"], var.network_dataplane)
    error_message = "network_dataplane must be 'azure' or 'cilium'."
  }
}
```

**Step 4: Pass Variable to AKS Module**

**File:** `infra/terraform/main.tf`
```terraform
module "aks" {
  # ... other variables ...
  network_plugin_mode = var.network_plugin_mode
  pod_cidr            = var.pod_cidr
  network_dataplane   = var.network_dataplane  # ✅ Add this
  # ... other variables ...
}
```

**Step 5: Set in terraform.tfvars (Optional)**

**File:** `infra/terraform/envs/dev/terraform.tfvars`
```terraform
network_plugin_mode = "overlay"
network_policy      = "cilium"
network_dataplane   = "cilium"  # ✅ REQUIRED when network_policy = "cilium"
pod_cidr            = "10.244.0.0/16"
```

**Step 6: Validate and Apply**
```bash
cd infra/terraform
terraform validate
terraform plan -var-file="envs/dev/terraform.tfvars"
terraform apply
```

### Prevention

**Best Practices:**
1. **Always Set `network_dataplane` When Using Cilium:**
   - If `network_policy = "cilium"`, then `network_dataplane = "cilium"` is REQUIRED
   - Don't rely on defaults - be explicit

2. **Use Consistent Network Configuration:**
   ```terraform
   # ✅ CORRECT: Cilium policy + Cilium dataplane
   network_policy    = "cilium"
   network_dataplane = "cilium"
   
   # ❌ WRONG: Cilium policy + Azure dataplane
   network_policy    = "cilium"
   network_dataplane = "azure"  # ❌ ERROR!
   ```

3. **Document Network Requirements:**
   - Create a network configuration matrix
   - Document which combinations are valid:
     - `network_policy = "azure"` → `network_dataplane = "azure"` (default)
     - `network_policy = "calico"` → `network_dataplane = "azure"` (default)
     - `network_policy = "cilium"` → `network_dataplane = "cilium"` (REQUIRED)

4. **Validate Configuration:**
   ```bash
   # Check for missing network_dataplane when using Cilium
   if grep -q 'network_policy.*cilium' terraform.tfvars; then
     if ! grep -q 'network_dataplane.*cilium' terraform.tfvars; then
       echo "ERROR: network_dataplane must be 'cilium' when network_policy = 'cilium'"
     fi
   fi
   ```

5. **Use Terraform Validation:**
   - Add validation rules to ensure `network_dataplane = "cilium"` when `network_policy = "cilium"`
   - Example:
     ```terraform
     variable "network_dataplane" {
       # ... validation ...
     }
     
     # In locals or validation block
     validation {
       condition = var.network_policy != "cilium" || var.network_dataplane == "cilium"
       error_message = "network_dataplane must be 'cilium' when network_policy is 'cilium'."
     }
     ```

---

## 7. kubelogin Not Found (Azure AD RBAC)

### Error Message
```
Unable to connect to the server: getting credentials: exec: executable kubelogin not found

It looks like you are trying to use a client-go credential plugin that is not installed.

kubelogin is not installed which is required to connect to AAD enabled cluster.

To learn more, please go to https://aka.ms/aks/kubelogin
```

### Why It Happens

**Root Cause:**
- Your AKS cluster has Azure AD (Azure Active Directory) integration enabled with Azure RBAC (`azure_rbac_enabled = true`)
- When Azure RBAC is enabled, kubectl requires the `kubelogin` plugin to authenticate with Azure AD
- The `kubelogin` executable is not installed on your local machine
- kubectl tries to use `kubelogin` as a credential plugin but can't find it

**Why This Matters:**
- **Azure RBAC** provides enterprise-grade access control using Azure AD identities
- Instead of managing Kubernetes RBAC directly, you use Azure AD groups and roles
- This requires authentication through Azure AD, which `kubelogin` handles
- Without `kubelogin`, kubectl cannot authenticate to Azure AD-enabled clusters

**Common Scenario:**
- AKS cluster configured with `azure_rbac_enabled = true` (enterprise-grade security)
- Developer tries to run `kubectl get nodes` or other kubectl commands
- kubectl attempts to authenticate but can't find `kubelogin` plugin
- Connection fails with "executable kubelogin not found" error

**When You'll See This:**
- After deploying a new AKS cluster with Azure RBAC enabled
- When setting up a new development machine
- After updating kubectl without installing kubelogin
- When using Azure AD authentication for the first time

### How to Fix

**Step 1: Install kubelogin**

**Windows (PowerShell):**

**Option A: Using winget (Recommended)**
```powershell
winget install Microsoft.Azure.Kubelogin
```

**Option B: Using Chocolatey**
```powershell
choco install kubelogin
```

**Option C: Manual Installation**
1. Download from GitHub: https://github.com/Azure/kubelogin/releases
2. Download `kubelogin-windows-amd64.zip` (or appropriate architecture)
3. Extract `kubelogin.exe` to a directory in your PATH (e.g., `C:\Windows\System32`)
4. Or add the extracted directory to your PATH environment variable

**Linux/macOS:**
```bash
# Using Homebrew (macOS)
brew install Azure/kubelogin/kubelogin

# Using direct download (Linux/macOS)
# Download from: https://github.com/Azure/kubelogin/releases
# Make executable and add to PATH
```

**Step 2: Verify Installation**
```powershell
# Windows
kubelogin --version

# Should output something like:
# kubelogin version v0.0.31
```

**Step 3: Get AKS Credentials**
```powershell
# Get credentials for your AKS cluster
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>

# Example:
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
```

**Step 4: Test Connection**
```powershell
# Test kubectl connection
kubectl get nodes

# If successful, you should see your cluster nodes listed
```

**Step 5: Authenticate with Azure AD (if needed)**
```powershell
# Login to Azure (if not already logged in)
az login

# Or use device code flow (for non-interactive environments)
az login --use-device-code
```

**Troubleshooting Authentication:**

If you still get authentication errors after installing kubelogin:

1. **Check Azure Login:**
   ```powershell
   az account show
   # Should show your current Azure subscription
   ```

2. **Verify Cluster Access:**
   ```powershell
   # Check if you have access to the cluster
   az aks show --resource-group <resource-group-name> --name <cluster-name> --query "azureRbac.enabled"
   # Should return: true
   ```

3. **Check Azure AD Group Membership:**
   - Ensure your Azure AD user is a member of the admin group specified in `admin_group_object_ids`
   - Verify group membership in Azure Portal or using Azure CLI:
     ```powershell
     az ad group member list --group <admin-group-object-id>
     ```

4. **Re-authenticate:**
   ```powershell
   # Clear existing credentials
   kubectl config delete-context <cluster-context>
   
   # Get credentials again
   az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
   ```

### Prevention

**Best Practices:**

1. **Document Prerequisites:**
   - Add kubelogin installation to your setup documentation
   - Include it in your onboarding checklist
   - Document in README.md or setup guide

2. **Automate Installation:**
   - Add kubelogin installation to your setup scripts
   - Example PowerShell script:
     ```powershell
     # Check if kubelogin is installed
     if (-not (Get-Command kubelogin -ErrorAction SilentlyContinue)) {
         Write-Host "Installing kubelogin..."
         winget install Microsoft.Azure.Kubelogin
     }
     ```

3. **Verify Before Use:**
   - Check kubelogin installation before running kubectl commands
   - Add verification to CI/CD pipelines if using Azure AD authentication

4. **Alternative: Use Azure Cloud Shell:**
   - Azure Cloud Shell has kubelogin pre-installed
   - Use for quick access without local installation
   - Access via: https://shell.azure.com

5. **Document Cluster Configuration:**
   - Clearly document when Azure RBAC is enabled
   - Include kubelogin requirement in cluster documentation
   - Add to troubleshooting runbook

**Setup Script Example:**

Create a `setup-kubectl.ps1` script:
```powershell
# Install kubectl (if not installed)
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Installing kubectl..."
    winget install Kubernetes.kubectl
}

# Install kubelogin (if not installed)
if (-not (Get-Command kubelogin -ErrorAction SilentlyContinue)) {
    Write-Host "Installing kubelogin..."
    winget install Microsoft.Azure.Kubelogin
}

# Verify installations
Write-Host "kubectl version:"
kubectl version --client

Write-Host "`nkubelogin version:"
kubelogin --version

Write-Host "`n✅ Setup complete! You can now connect to Azure AD-enabled AKS clusters."
```

**README.md Addition:**

Add to your project README:
```markdown
## Prerequisites

- Azure CLI installed and configured
- kubectl installed
- **kubelogin installed** (required for Azure AD-enabled clusters)
  - Install via: `winget install Microsoft.Azure.Kubelogin`
  - Or: `choco install kubelogin`
```

### Additional Notes

**When kubelogin is NOT Required:**
- If `azure_rbac_enabled = false` (using Kubernetes RBAC instead)
- If using service accounts with static tokens
- If using managed identity authentication (different flow)

**kubelogin vs az aks get-credentials:**
- `az aks get-credentials` downloads the kubeconfig file
- kubelogin is the plugin that handles Azure AD authentication
- Both are required for Azure AD-enabled clusters

**Private Cluster Considerations:**
- If your cluster is private (`aks_private_cluster_enabled = true`), you need network access to the cluster
- Use VPN, ExpressRoute, or Azure Bastion to access private clusters
- kubelogin still required for authentication, but network connectivity is also needed

---

## 8. 404 Error During Terraform Destroy (Federated Identity Credential)

### Error Message
```
Error: Removing Application Id Federated Identity Credential (Application: "3f28b0ee-0b72-4fe9-930e-daf1307988d3"
Federated Identity Credential: "b23c7af0-6b33-48d4-b6f3-2ea2e42d7bcb")

unexpected status 404 (404 Not Found) with error: Request_ResourceNotFound: Resource
'Application_3f28b0ee-0b72-4fe9-930e-daf1307988d3' does not exist or one of its queried
reference-property objects are not present.
```

### Why It Happens

**Root Cause:**
- Terraform is trying to delete a Federated Identity Credential from an Azure AD Application
- The Azure AD Application was already deleted (either manually, in a previous destroy operation, or due to dependency ordering)
- When the parent application doesn't exist, Azure returns a 404 error
- Terraform can't delete a child resource when the parent is already gone

**Why This Matters:**
- **Dependency Ordering**: Terraform destroys resources in dependency order
- **Azure AD Behavior**: When an Azure AD Application is deleted, its federated credentials are automatically deleted by Azure
- **State Mismatch**: Terraform's state still thinks the credential exists, but Azure has already removed it
- This is a common issue during `terraform destroy` operations

**Common Scenario:**
- Running `terraform destroy` to clean up infrastructure
- Azure AD Application gets deleted first (or was already deleted)
- Terraform tries to delete federated credentials that no longer exist
- 404 error occurs because the parent application is gone

**When You'll See This:**
- During `terraform destroy` operations
- After manually deleting Azure AD applications
- When destroy operations are interrupted and resumed
- When there are dependency ordering issues

### How to Fix

**Step 1: Remove Resource from Terraform State**

The resource is already deleted in Azure, but Terraform still has it in state. Remove it from state:

```bash
# Find the resource address in your state
terraform state list | grep federated

# Remove the federated credential from state
terraform state rm 'module.github_oidc.azuread_application_federated_identity_credential.github_actions_main'
terraform state rm 'module.github_oidc.azuread_application_federated_identity_credential.github_actions_additional["<subject>"]'

# Or remove all federated credentials at once
terraform state list | grep federated | ForEach-Object { terraform state rm $_ }
```

**Step 2: Continue Destroy Operation**

After removing from state, continue the destroy:

```bash
terraform destroy
```

**Alternative: Remove All GitHub OIDC Resources from State**

If the entire GitHub OIDC module resources are already deleted:

```bash
# List all GitHub OIDC resources
terraform state list | grep github_oidc

# Remove all GitHub OIDC resources from state
terraform state list | grep github_oidc | ForEach-Object { terraform state rm $_ }
```

**Step 3: Verify State is Clean**

```bash
# Check if resources are removed
terraform state list | grep github_oidc

# Should return nothing if all resources are removed
```

**Step 4: Complete Destroy (if needed)**

```bash
# Continue destroy operation
terraform destroy -auto-approve
```

### Prevention

**Best Practices:**

1. **Let Terraform Handle Dependencies:**
   - Don't manually delete Azure AD applications while Terraform manages them
   - Let Terraform destroy resources in the correct order

2. **Use Targeted Destroy for Troubleshooting:**
   ```bash
   # Destroy specific resources in order
   terraform destroy -target=module.github_oidc.azuread_application_federated_identity_credential.github_actions_main
   terraform destroy -target=module.github_oidc.azuread_application.github_actions
   ```

3. **Check State Before Destroy:**
   ```bash
   # Review what will be destroyed
   terraform plan -destroy
   
   # Check for potential issues
   terraform state list
   ```

4. **Handle Interrupted Destroys:**
   - If destroy is interrupted, check Azure Portal to see what's actually deleted
   - Remove deleted resources from Terraform state before retrying

5. **Use Lifecycle Rules (Already Added):**
   - The module now includes lifecycle blocks to handle dependency ordering
   - This helps prevent some ordering issues

**Script to Clean Up State:**

Create a cleanup script `cleanup-state.ps1`:

```powershell
# Cleanup script for Terraform state after interrupted destroy
Write-Host "Checking for orphaned federated credentials in state..."

$federatedResources = terraform state list | Select-String "federated"

if ($federatedResources) {
    Write-Host "Found federated credentials in state:"
    $federatedResources | ForEach-Object { Write-Host "  $_" }
    
    Write-Host "`nRemoving from state..."
    $federatedResources | ForEach-Object { 
        terraform state rm $_.Line
    }
    
    Write-Host "`n✅ Cleanup complete!"
} else {
    Write-Host "No federated credentials found in state."
}
```

**Manual Cleanup in Azure Portal:**

If Terraform state cleanup doesn't work:

1. Go to Azure Portal → Azure Active Directory → App registrations
2. Search for your application (if it still exists)
3. Check if federated credentials are already deleted
4. If application is gone, credentials are automatically deleted
5. Remove resources from Terraform state as shown above

### Additional Notes

**Why This Happens:**
- Azure AD automatically deletes federated credentials when the parent application is deleted
- Terraform doesn't know this happened if the application was deleted outside of Terraform
- The state file still references resources that no longer exist in Azure

**Safe to Ignore:**
- If you're destroying everything, this error is usually safe to ignore
- The resources are already deleted in Azure
- You just need to clean up Terraform state

**Prevention in Future:**
- Always use `terraform destroy` instead of manual deletion
- If you must delete manually, also remove from Terraform state
- Consider using `terraform destroy -target` for complex dependencies

---

## 9. Resource Group Deletion Blocked by ContainerInsights Solution

### Error Message
```
Error: deleting Resource Group "ola-rg-dev": the Resource Group still contains Resources.

Terraform is configured to check for Resources within the Resource Group when deleting the Resource Group - and
raise an error if nested Resources still exist to avoid unintentionally deleting these Resources.

Terraform has detected that the following Resources still exist within the Resource Group:

* `/subscriptions/.../resourceGroups/ola-rg-dev/providers/Microsoft.OperationsManagement/solutions/ContainerInsights(ola-rg-dev-logs)`
```

### Why It Happens

**Root Cause:**
- When you enable Log Analytics for AKS (`enable_log_analytics = true`), Azure automatically creates a ContainerInsights solution
- This solution is created outside of Terraform's management (by Azure's monitoring service)
- Terraform's safety check prevents Resource Group deletion if it contains any resources
- The ContainerInsights solution is not tracked in Terraform state, so Terraform can't delete it directly

**Why This Matters:**
- **Safety Feature**: Terraform's default behavior prevents accidental deletion of resources
- **Auto-Created Resources**: Some Azure services create resources automatically that Terraform doesn't manage
- **Dev Environment**: For development environments, you often want easy cleanup without manual intervention
- **Production Consideration**: In production, you might want to keep this safety check enabled

**Common Scenario:**
- AKS cluster with Log Analytics enabled
- Running `terraform destroy` to clean up dev environment
- ContainerInsights solution still exists in the Resource Group
- Terraform blocks Resource Group deletion to prevent accidental data loss

**When You'll See This:**
- After enabling Log Analytics for AKS
- During `terraform destroy` operations
- When trying to delete Resource Groups that contain auto-created monitoring resources
- In environments where Azure creates resources automatically

### How to Fix

**Option 1: Disable Safety Check (Recommended for Dev)**

Add the feature flag to allow Resource Group deletion even if it contains resources:

**File:** `infra/terraform/main.tf`
```terraform
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # Allow resource group deletion even if it contains resources (e.g., ContainerInsights solution)
      # This is safe for dev environments where we want easy cleanup
      # For production, consider setting this to true and manually cleaning up resources first
      prevent_deletion_if_contains_resources = false
    }
  }
  use_oidc = true
}
```

**Then retry destroy:**
```bash
terraform destroy
```

**Option 2: Manually Delete ContainerInsights Solution**

If you prefer to keep the safety check enabled:

**Step 1: Delete via Azure CLI**
```bash
# Get the solution name
az monitor log-analytics solution list --resource-group ola-rg-dev --query "[?contains(name, 'ContainerInsights')].name" -o tsv

# Delete the solution
az monitor log-analytics solution delete \
  --resource-group ola-rg-dev \
  --name ContainerInsights(ola-rg-dev-logs)
```

**Step 2: Retry Terraform Destroy**
```bash
terraform destroy
```

**Option 3: Delete via Azure Portal**

1. Go to Azure Portal → Resource Groups → `ola-rg-dev`
2. Find the ContainerInsights solution
3. Click Delete
4. Retry `terraform destroy`

### Prevention

**Best Practices:**

1. **Environment-Specific Configuration:**
   - **Dev/Test**: Set `prevent_deletion_if_contains_resources = false` for easy cleanup
   - **Production**: Keep `prevent_deletion_if_contains_resources = true` (default) for safety

2. **Conditional Feature Flag:**
   ```terraform
   provider "azurerm" {
     features {
       resource_group {
         prevent_deletion_if_contains_resources = var.environment == "production" ? true : false
       }
     }
   }
   ```

3. **Document Auto-Created Resources:**
   - Document which Azure services create resources automatically
   - Include cleanup steps in your runbook
   - Example: Log Analytics → ContainerInsights solution

4. **Use Terraform to Manage Resources:**
   - If possible, manage ContainerInsights solution in Terraform
   - This gives you full control over the resource lifecycle
   - Example:
     ```terraform
     resource "azurerm_log_analytics_solution" "container_insights" {
       solution_name         = "ContainerInsights"
       location             = var.location
       resource_group_name  = azurerm_resource_group.rg.name
       workspace_resource_id = azurerm_log_analytics_workspace.monitoring[0].id
       workspace_name       = azurerm_log_analytics_workspace.monitoring[0].name
     }
     ```

5. **Cleanup Script:**
   Create a cleanup script `cleanup-rg.ps1`:
   ```powershell
   # Cleanup script for Resource Group with auto-created resources
   param(
       [string]$ResourceGroupName = "ola-rg-dev"
   )
   
   Write-Host "Checking for ContainerInsights solution..."
   $solutions = az monitor log-analytics solution list --resource-group $ResourceGroupName --query "[?contains(name, 'ContainerInsights')]" -o json | ConvertFrom-Json
   
   if ($solutions) {
       Write-Host "Found ContainerInsights solution. Deleting..."
       foreach ($solution in $solutions) {
           $solutionName = $solution.name
           az monitor log-analytics solution delete --resource-group $ResourceGroupName --name $solutionName --yes
           Write-Host "Deleted: $solutionName"
       }
   } else {
       Write-Host "No ContainerInsights solution found."
   }
   
   Write-Host "`n✅ Cleanup complete! You can now run terraform destroy."
   ```

### Additional Notes

**Why ContainerInsights is Auto-Created:**
- When you enable Log Analytics for AKS, Azure automatically sets up ContainerInsights
- ContainerInsights provides container monitoring, metrics, and logs
- It's created as a solution in your Log Analytics workspace
- This happens automatically and isn't always tracked in Terraform

**Safety Considerations:**
- **Dev/Test**: Disabling the safety check is acceptable for easier cleanup
- **Production**: Keep the safety check enabled and manually verify resources before deletion
- **Compliance**: Some organizations require explicit resource deletion for audit trails

**Alternative: Disable Log Analytics**
- If you don't need monitoring in dev, set `enable_log_analytics = false`
- This prevents ContainerInsights from being created
- Resource Group deletion will work without issues

---

## General Troubleshooting Tips

### 1. Always Validate First
```bash
cd infra/terraform
terraform validate
terraform fmt -check
```

### 2. Use Plan to Preview Changes
```bash
terraform plan -var-file="envs/dev/terraform.tfvars" > plan.txt
# Review plan.txt before applying
```

### 3. Check Azure Documentation
- Error codes often link to Azure documentation
- Example: `https://aka.ms/aks/servicecidroverlap`

### 4. Use Terraform State Inspection
```bash
terraform state list
terraform state show <resource>
```

### 5. Enable Debug Logging
```bash
export TF_LOG=DEBUG
terraform apply
```

### 6. Check Resource Dependencies
- Use `depends_on` for explicit dependencies
- Terraform usually handles implicit dependencies, but explicit is clearer

### 7. Review Error Messages Carefully
- Error messages often contain the exact field causing the issue
- Look for error codes and subcodes
- Check the `target` field to identify the problematic resource

---

## Contributing to This Guide

When you encounter a new error:

1. **Document the Error:**
   - Copy the exact error message
   - Note the Terraform resource and line number

2. **Research the Root Cause:**
   - Why does this error occur?
   - What configuration causes it?

3. **Document the Solution:**
   - Step-by-step fix
   - Code examples
   - Prevention tips

4. **Add to This File:**
   - Follow the existing format
   - Include all sections: Error, Why, How to Fix, Prevention

---

## 10. AKS Node Pool Update Timeout (Context Deadline Exceeded)

### Error Message
```
Error: updating Default Node Pool Agent Pool (Subscription: "..."
│ Resource Group Name: "ola-rg-dev"
│ Managed Cluster Name: "ola-aks-dev"
│ Agent Pool Name: "system") polling after CreateOrUpdate: context deadline exceeded
│
│   with module.aks.azurerm_kubernetes_cluster.aks,
│   on modules\aks\main.tf line 2, in resource "azurerm_kubernetes_cluster" "aks":
│    2: resource "azurerm_kubernetes_cluster" "aks" {
```

### Why It Happens

**Root Cause:**
- Terraform's default timeout for AKS operations is **30 minutes**.
- Node pool updates can take longer, especially when:
  - Nodes are trying to connect to the API server (network connectivity issues)
  - The cluster is being updated with new network configuration
  - Nodes are provisioning or updating their configuration
  - There are network routing issues (e.g., with `userDefinedRouting` and NAT Gateway)
- When the operation exceeds the timeout, Terraform cancels it and reports "context deadline exceeded".

**Why This Matters:**
- **Network Connectivity**: If nodes can't reach the API server (common with private clusters + `userDefinedRouting`), the update hangs.
- **Long Operations**: **Default node pool updates can legitimately take 90-120+ minutes**, especially:
  - During initial cluster creation
  - When updating network configuration (route tables, NAT Gateway, private clusters)
  - When nodes need to be recreated
  - With private clusters using `userDefinedRouting` and NAT Gateway
- **Resource State**: The operation might still be running in Azure, but Terraform has given up waiting.
- **Why It Keeps Happening**: The default node pool is embedded in the AKS cluster resource, so **every cluster update triggers a default node pool update**, which is inherently slower than additional node pool updates.

**Common Scenario:**
- You update the AKS cluster configuration (e.g., route table, network settings, tags, etc.).
- Terraform tries to update the cluster, which **requires** updating the default node pool.
- Default node pool update takes 90-120+ minutes (normal for complex network configurations).
- Terraform times out after 60 minutes (if not increased).
- The error message shows "context deadline exceeded", but the operation may still be running in Azure.

### How to Fix

**Step 1: Ignore upgrade_settings Changes (Recommended Fix)**

AKS automatically manages `upgrade_settings` for node pools, which can cause Terraform to detect drift and trigger unnecessary updates that timeout. Ignore these changes:

```terraform
# In infra/terraform/modules/aks/main.tf
resource "azurerm_kubernetes_cluster" "aks" {
  # ... existing configuration ...

  # Lifecycle: Ignore upgrade_settings changes to prevent automatic upgrade conflicts
  lifecycle {
    ignore_changes = [
      default_node_pool[0].upgrade_settings,
    ]
  }
}

# For additional node pools
resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  # ... existing configuration ...

  # Lifecycle: Ignore upgrade_settings changes
  lifecycle {
    ignore_changes = [
      upgrade_settings,
    ]
  }
}
```

**Step 2: Increase Terraform Timeout (Critical Fix)**

**Why 60m isn't enough:**
- Default node pool updates are part of the AKS cluster resource update
- These updates can legitimately take **90-120+ minutes**, especially with:
  - Private clusters with `userDefinedRouting` and NAT Gateway
  - Network configuration changes (route tables, subnets)
  - Node provisioning and API server connectivity establishment
  - Complex network routing scenarios

Add `timeouts` block to the AKS resource with significantly increased values:

```terraform
# In infra/terraform/modules/aks/main.tf
resource "azurerm_kubernetes_cluster" "aks" {
  # ... existing configuration ...

  # Timeout configuration for long-running operations
  # Significantly increased timeout for default node pool updates
  timeouts {
    create = "120m" # Increased for initial cluster creation with network setup
    update = "180m" # CRITICAL: Significantly increased for default node pool updates
                    # Default node pool updates can take 90-120+ minutes
    delete = "90m"  # Increased for cluster deletion
    read   = "5m"   # Standard read timeout
  }
}
```

**Why This Keeps Happening:**
- The default node pool is **embedded** in the AKS cluster resource (not a separate resource)
- When Terraform updates the cluster, it **must** update the default node pool
- Default node pool updates are **inherently slower** than additional node pool updates because:
  - They require cluster-level coordination
  - They affect critical system components (CoreDNS, metrics-server, etc.)
  - Network connectivity must be established before nodes can join
- With private clusters + `userDefinedRouting`, the process is even slower due to:
  - Route table propagation delays
  - NAT Gateway routing establishment
  - API server private endpoint connectivity

**Step 3: Fix Underlying Network Connectivity Issue (If Still Timing Out)**

If the timeout is caused by network connectivity issues (nodes can't reach API server):

1. **Ensure Route Table is Configured Correctly:**
   ```terraform
   # In infra/terraform/modules/vnet/main.tf
   resource "azurerm_route_table" "aks_subnet" {
     # ... existing configuration ...
     
     # Route for VNet traffic (allows AKS nodes to reach API server)
     route {
       name           = "VNetLocal"
       address_prefix = var.address_space[0] # VNet address space
       next_hop_type  = "VnetLocal"
     }
   }
   ```

2. **Apply Route Table Fix First:**
   ```bash
   terraform apply -var-file="envs/dev/terraform.tfvars" -target="module.vnet.azurerm_route_table.aks_subnet[0]"
   ```

3. **Then Retry AKS Update:**
   ```bash
   terraform apply -var-file="envs/dev/terraform.tfvars"
   ```

**Step 4: Check Operation Status (If Timeout Still Occurs)**

If Terraform times out even with increased timeout, check if the operation is still running in Azure:

**Option A: Azure Portal**
1. Go to **Azure Portal** -> **Kubernetes services** -> Your cluster
2. Check **Activity log** for ongoing operations
3. Look for operations with status "In Progress" or "Running"
4. If operation is still running, wait for it to complete before retrying Terraform

**Option B: Azure CLI**
```bash
# Check cluster status
az aks show --resource-group ola-rg-dev --name ola-aks-dev --query "provisioningState"

# Check for ongoing operations on default node pool
az aks nodepool show \
  --resource-group ola-rg-dev \
  --cluster-name ola-aks-dev \
  --nodepool-name system \
  --query "provisioningState"

# List recent operations
az monitor activity-log list \
  --resource-group ola-rg-dev \
  --resource-id /subscriptions/.../managedClusters/ola-aks-dev \
  --max-events 10 \
  --query "[?status.value=='InProgress']"
```

**If Operation is Still Running:**
- **DO NOT** run `terraform apply` again - it will conflict with the ongoing operation
- Wait for the operation to complete (can take 90-120+ minutes)
- Monitor in Azure Portal or via CLI
- Once complete, refresh Terraform state: `terraform refresh -var-file="envs/dev/terraform.tfvars"`

**If Operation Failed in Azure:**
- Check the error message in Azure Portal Activity log
- Fix the underlying issue (usually network connectivity)
- Retry `terraform apply` after fixing the issue

**Step 5: Force Refresh State (If Operation Completed)**

If the operation completed in Azure but Terraform state is out of sync:

```bash
# Refresh Terraform state
terraform refresh -var-file="envs/dev/terraform.tfvars"

# Check if state matches reality
terraform plan -var-file="envs/dev/terraform.tfvars"
```

### Prevention

**1. Set Appropriate Timeouts (CRITICAL - Primary Prevention):**

**This is the most important fix.** Always set timeouts to accommodate long-running default node pool updates:

```terraform
resource "azurerm_kubernetes_cluster" "aks" {
  # ... configuration ...

  timeouts {
    create = "120m" # For initial cluster creation with network setup
    update = "180m" # CRITICAL: Default node pool updates can take 90-120+ minutes
                    # This is especially important for private clusters with userDefinedRouting
    delete = "90m"  # For cluster deletion
    read   = "5m"   # Standard read timeout
  }
}
```

**Why This Prevents Recurring Errors:**
- Default node pool updates are **inherently slow** (90-120+ minutes is normal)
- With private clusters + `userDefinedRouting` + NAT Gateway, updates are even slower
- The default 30-minute timeout is **insufficient** for production-grade configurations
- Setting `update = "180m"` provides a safety margin for legitimate long-running operations

**2. Ignore upgrade_settings Changes (Secondary Prevention):**

Always ignore `upgrade_settings` changes to prevent AKS automatic upgrade conflicts:

```terraform
resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  # ... configuration ...
  
  lifecycle {
    ignore_changes = [
      upgrade_settings,
    ]
  }
}
```

**Note:** Terraform doesn't support ignoring nested block attributes like `default_node_pool[0].upgrade_settings` directly, but the timeout increase above handles legitimate long-running operations.

**3. Fix Network Configuration Before Cluster Updates:**

- Ensure route tables and NAT Gateway are configured correctly **before** updating the cluster.
- Apply network changes first, then update the cluster.

**4. Monitor Long-Running Operations:**

- Use Azure Portal to monitor cluster operations.
- Check activity logs for stuck operations.
- Consider using Azure CLI to check operation status:
  ```bash
  az aks show --resource-group <rg> --name <cluster> --query "provisioningState"
  ```

**5. Use Targeted Applies for Network Fixes:**

When fixing network issues, apply changes incrementally:

```bash
# Step 1: Fix route table
terraform apply -target="module.vnet.azurerm_route_table.aks_subnet[0]"

# Step 2: Wait for route table to be applied

# Step 3: Update AKS cluster
terraform apply -var-file="envs/dev/terraform.tfvars"
```

**6. Document Expected Operation Times:**

Create a reference for your team:

```markdown
## Expected AKS Operation Times

- **Cluster Creation**: 15-30 minutes (can take up to 90 minutes with network setup)
- **Node Pool Update**: 10-30 minutes (can take up to 60 minutes with network fixes)
- **Node Pool Scale**: 5-15 minutes
- **Cluster Deletion**: 20-40 minutes
```

**7. Use Terraform Workspaces for Testing:**

Test timeout configurations in a dev workspace before applying to production:

```bash
terraform workspace new test-timeouts
terraform apply -var-file="envs/dev/terraform.tfvars"
```

---

## 11. Cannot Connect to Private AKS Cluster (DNS Resolution Failure)

### Error Message
```
Unable to connect to the server: dial tcp: lookup ola-aks-dev-dns-xxxxx.xxxxx.privatelink.uksouth.azmk8s.io: no such host

E0210 22:02:30.851209     268 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://ola-aks-dev-dns-xxxxx.xxxxx.privatelink.uksouth.azmk8s.io:443/api?timeout=32s\": context deadline exceeded (Client.Timeout exceeded while awaiting headers)"

Error: failed to authenticate: DeviceCodeCredential: context canceled
```

### Why It Happens

**Root Cause:**
- Your AKS cluster is configured as a **private cluster** (`aks_private_cluster_enabled = true`).
- Private clusters have their API server accessible **only from within the VNet**.
- The API server uses a **private link endpoint** with a DNS name like `*.privatelink.uksouth.azmk8s.io`.
- This DNS name can **only be resolved from within the VNet** or from a connected network.
- When you try to connect from your local machine (outside the VNet), DNS resolution fails.

**Why This Matters:**
- **Security Feature**: Private clusters provide enterprise-grade security by isolating the API server.
- **Network Isolation**: The API server is not exposed to the public internet.
- **Access Control**: Only resources within the VNet (or connected networks) can access the cluster.

**Common Scenario:**
- You deploy a private AKS cluster for security.
- You try to run `kubectl get nodes` from your local machine.
- DNS resolution fails because your machine is not in the VNet.
- Authentication may also fail if Azure AD authentication times out.

### How to Fix

**Option 1: Use Azure Bastion + Jumpbox (Recommended for Production - Built-in Solution)**

If you've enabled Azure Bastion + Jumpbox in your Terraform configuration (`enable_bastion = true`), this is the **recommended production-grade solution**:

1. **Enable Bastion in Terraform (if not already enabled):**
   ```terraform
   # In terraform.tfvars
   enable_bastion = true
   bastion_subnet_address_prefixes = ["10.0.3.0/26"]
   jumpbox_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC..."  # Your SSH public key
   bastion_sku = "Standard"  # Recommended for production
   ```

2. **Apply Terraform changes:**
   ```bash
   terraform apply
   ```

3. **Connect to Jumpbox via Azure Bastion:**
   - Go to **Azure Portal** -> **Virtual Machines** -> Find your jumpbox VM (e.g., `aks-jumpbox`)
   - Click **"Connect"** -> Select **"Bastion"**
   - Enter your **username** (default: `azureuser`)
   - If using SSH key: Paste your **SSH private key** or select from your key file
   - If using password: Enter your password
   - Click **"Connect"**

4. **Once connected to the jumpbox, tools are pre-installed:**
   ```bash
   # Verify tools are installed
   kubectl version --client
   az --version
   kubelogin --version
   
   # Authenticate with Azure (if needed)
   az login
   
   # Get AKS credentials
   az aks get-credentials --resource-group <resource-group> --name <aks-name> --overwrite-existing
   
   # Test connection
   kubectl get nodes
   kubectl get namespaces
   ```

**Benefits of Azure Bastion + Jumpbox:**
- ✅ **No public IPs** - Jumpbox VM has no public IP, fully private
- ✅ **No VPN required** - Access directly from Azure Portal
- ✅ **Pre-configured tools** - kubectl, Azure CLI, kubelogin, Helm installed automatically
- ✅ **Secure by default** - All traffic encrypted, no open ports
- ✅ **Audit trail** - All access logged in Azure Monitor
- ✅ **Enterprise-grade** - Fits perfectly with private AKS architecture

**Alternative: Connect via VPN**

If you prefer VPN access:

1. **Set up VPN connection to Azure VNet:**
   - Use Azure VPN Gateway (Point-to-Site or Site-to-Site)
   - Or use ExpressRoute for enterprise connectivity

2. **Once connected to VNet, get credentials:**
   ```bash
   az aks get-credentials --resource-group <resource-group> --name <aks-name> --overwrite-existing
   ```

3. **Test connection:**
   ```bash
   kubectl get nodes
   ```

**Option 2: Use Admin Credentials (Dev/Test Only)**

If you need quick access for development/testing, you can use admin credentials (bypasses Azure RBAC):

```bash
az aks get-credentials --resource-group <resource-group> --name <aks-name> --admin --overwrite-existing
```

**Note:** This only works if:
- The cluster is not fully private (has some public access)
- Or you're connecting from within the VNet
- Admin credentials bypass Azure RBAC, so use with caution

**Option 3: Temporarily Enable Public Access with Authorized IPs (Dev/Test Only)**

For development environments, you can temporarily allow public access from your IP:

1. **Get your public IP:**
   ```bash
   # Windows PowerShell
   (Invoke-WebRequest -Uri "https://api.ipify.org").Content
   
   # Linux/Mac
   curl https://api.ipify.org
   ```

2. **Update Terraform configuration:**
   ```terraform
   # In terraform.tfvars (dev environment only)
   aks_private_cluster_enabled = false
   aks_api_server_authorized_ip_ranges = ["<your-public-ip>/32"]
   ```

3. **Apply changes:**
   ```bash
   terraform apply
   ```

4. **Get credentials:**
   ```bash
   az aks get-credentials --resource-group <resource-group> --name <aks-name> --overwrite-existing
   ```

**Option 4: Use Azure Cloud Shell (Quick Test)**

Azure Cloud Shell is connected to Azure's network and can access private endpoints:

1. **Open Azure Cloud Shell:**
   - Go to https://shell.azure.com
   - Or use Azure Portal -> Cloud Shell icon

2. **Get AKS credentials:**
   ```bash
   az aks get-credentials --resource-group <resource-group> --name <aks-name> --overwrite-existing
   ```

3. **Test connection:**
   ```bash
   kubectl get nodes
   ```

**Option 5: Manual Jump Box VM (If Bastion Not Available)**

If Azure Bastion is not available, you can manually create a jump box VM (not recommended - use Option 1 instead):

1. **Create a VM in the VNet:**
   ```bash
   az vm create \
     --resource-group <resource-group> \
     --name aks-jumpbox \
     --image UbuntuLTS \
     --size Standard_B2s \
     --vnet-name <vnet-name> \
     --subnet <subnet-name> \
     --admin-username azureuser \
     --generate-ssh-keys
   ```

2. **Connect to the VM (requires public IP or VPN):**
   ```bash
   ssh azureuser@<vm-public-ip>
   ```

3. **Install kubectl and Azure CLI on the VM:**
   ```bash
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   
   # Install Azure CLI (if not already installed)
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Install kubelogin (required for Azure AD RBAC)
   curl -LO https://github.com/Azure/kubelogin/releases/download/v0.0.29/kubelogin-linux-amd64.zip
   unzip kubelogin-linux-amd64.zip
   sudo mv kubelogin /usr/local/bin/
   ```

4. **Get AKS credentials from the VM:**
   ```bash
   az aks get-credentials --resource-group <resource-group> --name <aks-name> --overwrite-existing
   kubectl get nodes
   ```

**Note:** This approach requires exposing the VM to the internet (public IP) or VPN access. **Azure Bastion + Jumpbox (Option 1) is the recommended enterprise solution** as it provides secure access without public IPs.

### Prevention

**1. Document Access Requirements:**

- Clearly document that private clusters require VNet connectivity.
- Provide setup instructions for VPN/Bastion access.
- Include Azure Cloud Shell as a quick access option.

**2. Environment-Specific Configuration:**

- **Development:** Consider allowing authorized IPs for easier access during development.
- **Production:** Always use private clusters with VPN/Bastion access.

**3. Access Documentation:**

Create a quick reference guide for your team:

```markdown
## Accessing Private AKS Cluster

### Option 1: Azure Bastion + Jumpbox (Recommended - Production-Grade)
1. Enable in Terraform: `enable_bastion = true`
2. Apply: `terraform apply`
3. Azure Portal -> Virtual Machines -> <jumpbox-name> -> Connect -> Bastion
4. Enter credentials and connect
5. Run: `az aks get-credentials --resource-group <rg> --name <cluster>`
6. Run: `kubectl get nodes`

### Option 2: Azure Cloud Shell (Quick Test)
1. Open https://shell.azure.com
2. Run: `az aks get-credentials --resource-group <rg> --name <cluster>`
3. Run: `kubectl get nodes`

### Option 3: VPN Connection
1. Connect to Azure VPN
2. Run: `az aks get-credentials --resource-group <rg> --name <cluster>`
3. Run: `kubectl get nodes`
```

**4. CI/CD Pipeline Access:**

- Ensure your CI/CD pipelines (GitHub Actions, Azure DevOps) can access the cluster.
- Use OIDC authentication for secure, credential-free access.
- Pipelines running in Azure can access private endpoints automatically.

---

---

## 14. AKS Node Pool Operation Conflict (409 - Operation In Progress)

### Error Message
```
Error: updating Default Node Pool Agent Pool (Subscription: "..."
│ Resource Group Name: "ola-rg-dev"
│ Managed Cluster Name: "ola-aks-dev"
│ Agent Pool Name: "system") performing CreateOrUpdate: unexpected status 409 (409 Conflict) with response: {
│   "code": "OperationNotAllowed",
│   "details": null,
│   "message": "Operation is not allowed because there's an in progress update node pool operation (operation ID: 84d90bcb-c52c-40f5-8180-28f22ccf0832) on the agent pool system started on UTC 2026-02-12T03:41:29Z. Please wait for it to finish before starting a new operation. You can also use 'az aks nodepool operation-abort ...' to abort the ongoing operation.",
│   "subcode": ""
│  }
```

### Why It Happens

**Root Cause:**
- A previous Terraform apply operation was **interrupted or timed out** while updating a node pool
- Azure is still processing the node pool update operation in the background
- When Terraform tries to start a new operation, Azure detects the existing in-progress operation and returns a 409 Conflict
- Azure only allows **one node pool operation at a time** per node pool

**Why This Matters:**
- **Operation Locking**: Azure locks node pools during updates to prevent conflicting operations
- **Timeout Scenarios**: If Terraform times out, the Azure operation may still be running
- **State Mismatch**: Terraform state may not reflect the actual Azure resource state
- **Cascading Issues**: This often happens after timeout errors (see Section 10)

**Common Scenario:**
- Terraform apply times out while updating a node pool (e.g., "context deadline exceeded")
- The Azure operation continues running in the background
- You retry `terraform apply` immediately
- Azure returns 409 Conflict because the previous operation is still in progress

**When You'll See This:**
- After a Terraform timeout error
- When retrying `terraform apply` too quickly after a timeout
- After interrupting a Terraform apply operation (Ctrl+C)
- When multiple Terraform runs are executed simultaneously

### How to Fix

**Step 1: Check Node Pool Status**

Check if the node pool is still updating:

```bash
az aks nodepool show \
  --resource-group ola-rg-dev \
  --cluster-name ola-aks-dev \
  --name system \
  --query "provisioningState" \
  -o tsv
```

**Expected Outputs:**
- `Updating` - Operation is still in progress (wait or abort)
- `Succeeded` - Operation completed (safe to retry Terraform)
- `Failed` - Operation failed (abort and retry)
- `Canceled` - Operation was canceled (safe to retry Terraform)

**Step 2: Choose Resolution Strategy**

**Option A: Wait for Operation to Complete (Recommended if Recent)**

If the operation started recently and might complete soon:

1. **Monitor the operation:**
   ```bash
   # Check status every 30 seconds
   watch -n 30 'az aks nodepool show --resource-group ola-rg-dev --cluster-name ola-aks-dev --name system --query "provisioningState" -o tsv'
   ```

2. **Wait for status to change to `Succeeded` or `Failed`**

3. **Then retry Terraform:**
   ```bash
   terraform apply -var-file="envs/dev/terraform.tfvars"
   ```

**Option B: Abort the Stuck Operation (Recommended if Stuck)**

If the operation has been running for a long time or appears stuck:

1. **Abort the operation:**
   ```bash
   az aks nodepool operation-abort \
     --resource-group ola-rg-dev \
     --cluster-name ola-aks-dev \
     --nodepool-name system
   ```

2. **Wait for abort to complete (usually 1-2 minutes):**
   ```bash
   az aks nodepool show \
     --resource-group ola-rg-dev \
     --cluster-name ola-aks-dev \
     --name system \
     --query "provisioningState" \
     -o tsv
   ```

3. **Verify status is `Canceled` or `Succeeded`**

4. **Refresh Terraform state:**
   ```bash
   terraform refresh -var-file="envs/dev/terraform.tfvars"
   ```

5. **Retry Terraform apply:**
   ```bash
   terraform apply -var-file="envs/dev/terraform.tfvars"
   ```

**Step 3: Verify Fix**

After resolving the conflict:

1. **Check node pool is in a stable state:**
   ```bash
   az aks nodepool show \
     --resource-group ola-rg-dev \
     --cluster-name ola-aks-dev \
     --name system \
     --query "{name:name, provisioningState:provisioningState, powerState:powerState.code}" \
     -o json
   ```

2. **Verify Terraform plan shows no conflicts:**
   ```bash
   terraform plan -var-file="envs/dev/terraform.tfvars"
   ```

### Prevention

**1. Increase Terraform Timeouts (Primary Prevention):**

Always set appropriate timeouts to prevent operations from timing out:

```terraform
resource "azurerm_kubernetes_cluster" "aks" {
  # ... configuration ...
  
  timeouts {
    create = "90m"  # Allow 90 minutes for cluster creation
    update = "60m"  # Allow 60 minutes for updates
    delete = "60m"  # Allow 60 minutes for deletion
  }
}
```

**2. Ignore upgrade_settings Changes:**

Prevent AKS automatic upgrade conflicts by ignoring `upgrade_settings`:

```terraform
resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  # ... configuration ...
  
  lifecycle {
    ignore_changes = [
      upgrade_settings,
    ]
  }
}
```

**3. Check Operation Status Before Retrying:**

Always check if an operation is in progress before retrying:

```bash
# Quick status check
az aks nodepool show \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --name <nodepool> \
  --query "provisioningState" \
  -o tsv
```

**4. Use Terraform Refresh After Timeouts:**

After a timeout, refresh state before retrying:

```bash
terraform refresh -var-file="envs/dev/terraform.tfvars"
terraform plan -var-file="envs/dev/terraform.tfvars"
```

**5. Wait Between Operations:**

If an operation times out, wait at least 5-10 minutes before retrying to allow Azure to complete or fail the operation.

**6. Monitor Long-Running Operations:**

Use Azure Portal or CLI to monitor operations:

```bash
# Monitor node pool operations
az aks nodepool list \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --query "[].{name:name, state:provisioningState, power:powerState.code}" \
  -o table
```

**7. Use Targeted Applies:**

When fixing specific issues, use targeted applies to avoid conflicts:

```bash
# Apply only specific resources
terraform apply -target="module.aks.azurerm_kubernetes_cluster.aks" -var-file="envs/dev/terraform.tfvars"
```

### Additional Notes

**Why Operations Get Stuck:**
- Network connectivity issues (nodes can't reach API server)
- Resource constraints (insufficient quota or capacity)
- Azure service issues (temporary Azure platform problems)
- Configuration conflicts (incompatible settings)

**When to Abort vs. Wait:**
- **Abort if**: Operation has been running > 30 minutes, appears stuck, or you need immediate resolution
- **Wait if**: Operation started recently (< 10 minutes), or you're not in a hurry

**Impact of Aborting:**
- Aborting an operation may leave the node pool in an intermediate state
- You may need to manually fix the node pool configuration
- In rare cases, you might need to delete and recreate the node pool

---

## 15. Terraform State Save Failure (DNS Resolution Error)

### Error Message
```
Error: Failed to save state

Error saving state: executing request: authorizing request: running Azure CLI: exit status
0xc0020043: ERROR: The command failed with an unexpected error. Here is the traceback:
ERROR: HTTPSConnectionPool(host='login.microsoftonline.com', port=443): Max retries exceeded with     
url: /5ee10fdc-b731-4ee9-9181-0dad7378a345/oauth2/v2.0/token (Caused by
NameResolutionError("<urllib3.connection.HTTPSConnection object at 0x0000016D60012330>: Failed to     
resolve 'login.microsoftonline.com' ([Errno 11001] getaddrinfo failed)"))

Error: Failed to persist state to backend

The error shown above has prevented Terraform from writing the updated state to the configured        
backend. To allow for recovery, the state has been written to the file "errored.tfstate" in the       
current working directory.

Running "terraform apply" again at this point will create a forked state, making it harder to
recover.

To retry writing this state, use the following command:
    terraform state push errored.tfstate
```

### Why It Happens

**Root Cause:**
- **Network Connectivity Issue**: Your machine cannot resolve DNS for `login.microsoftonline.com`
- Terraform successfully applied changes to Azure resources
- When Terraform tries to save state to the backend (Azure Storage), it needs to authenticate via Azure CLI
- Azure CLI fails to authenticate because it can't reach Microsoft's authentication endpoint
- Terraform saves a recovery file `errored.tfstate` locally to prevent state loss

**Why This Matters:**
- **State Consistency**: The state file contains the current state of your infrastructure
- **Forked State Risk**: If you run `terraform apply` again without recovering state, Terraform will think resources don't exist and try to create them again
- **Network Dependency**: Terraform backend operations require internet connectivity for authentication
- **Temporary Issue**: This is usually a temporary network/DNS issue that resolves itself

**Common Scenario:**
- Terraform apply completes successfully (resources are updated in Azure)
- Network connectivity is lost or DNS resolution fails temporarily
- Terraform tries to save state to Azure Storage backend
- Azure CLI authentication fails due to DNS resolution error
- Terraform saves `errored.tfstate` as a recovery mechanism
- You see the error message about failed state save

**When You'll See This:**
- Temporary network connectivity issues
- DNS resolution problems
- Corporate firewall/proxy blocking `login.microsoftonline.com`
- VPN connection issues
- Internet connectivity interruptions during Terraform operations

### How to Fix

**Step 1: Verify Network Connectivity**

Check if DNS resolution is working:

```bash
# Windows
nslookup login.microsoftonline.com
ping login.microsoftonline.com

# Linux/Mac
dig login.microsoftonline.com
ping login.microsoftonline.com
```

**Step 2: Recover State from errored.tfstate**

Terraform automatically saves state to `errored.tfstate` when backend save fails. Recover it:

```bash
cd infra/terraform

# Push the recovered state to backend
terraform state push errored.tfstate
```

**Step 3: Verify State Recovery**

Check that state was recovered successfully:

```bash
# List resources in state
terraform state list

# Check specific resource
terraform state show module.aks.azurerm_kubernetes_cluster.aks
```

**Step 4: Verify Azure Resources Match State**

Since the apply completed before the state save failed, verify resources exist:

```bash
# Check AKS cluster exists
az aks show --resource-group ola-rg-dev --name ola-aks-dev --query "provisioningState" -o tsv

# Check node pool status
az aks nodepool show --resource-group ola-rg-dev --cluster-name ola-aks-dev --name system --query "provisioningState" -o tsv
```

**Step 5: Clean Up Recovery File (After Successful Recovery)**

Once state is recovered, you can remove the recovery file:

```bash
# Verify state is correct first
terraform plan -var-file="envs/dev/terraform.tfvars"

# If plan shows no unexpected changes, remove recovery file
rm errored.tfstate  # Linux/Mac
Remove-Item errored.tfstate  # Windows PowerShell
```

**Step 6: Retry if Network Issue Persists**

If DNS resolution is still failing:

1. **Check Internet Connection:**
   ```bash
   ping 8.8.8.8  # Test basic connectivity
   ```

2. **Check DNS Settings:**
   ```bash
   # Windows
   ipconfig /all | findstr "DNS"
   
   # Linux/Mac
   cat /etc/resolv.conf
   ```

3. **Try Different DNS Server:**
   ```bash
   # Windows - Use Google DNS temporarily
   nslookup login.microsoftonline.com 8.8.8.8
   ```

4. **Check Firewall/Proxy:**
   - Ensure `login.microsoftonline.com` is not blocked
   - Check corporate firewall rules
   - Verify proxy settings if using a proxy

### Prevention

**1. Verify Network Connectivity Before Terraform Operations:**

Always check connectivity before running Terraform:

```bash
# Quick connectivity check
az account show  # Should work if network is OK
```

**2. Use Stable Network Connection:**

- Use a stable internet connection for Terraform operations
- Avoid running Terraform during network maintenance windows
- Use VPN if required by corporate policies

**3. Monitor Long-Running Operations:**

For long-running operations, monitor network connectivity:

```bash
# Keep connection alive during long operations
# Use tools like `ping` in a separate terminal
```

**4. Use Local State for Testing (Dev Only):**

For development/testing, consider using local state to avoid backend dependency:

```terraform
# terraform.tf (dev only - NOT for production)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

**5. Implement Retry Logic:**

For CI/CD pipelines, implement retry logic for state operations:

```yaml
# Example GitHub Actions retry
- name: Terraform Apply
  run: |
    for i in {1..3}; do
      terraform apply -auto-approve && break || sleep 10
    done
```

**6. Backup State Regularly:**

Regularly backup Terraform state:

```bash
# Manual backup before major operations
terraform state pull > terraform-state-backup-$(date +%Y%m%d).json
```

### Additional Notes

**Why State Recovery is Critical:**
- Terraform uses state to track which resources it manages
- If state is lost or out of sync, Terraform may try to recreate existing resources
- The `errored.tfstate` file prevents state loss during network failures

**State File Location:**
- Recovery file: `errored.tfstate` in your Terraform working directory
- Backend state: Stored in Azure Storage (configured in `backend.tf` or `terraform.tf`)

**When to Use State Push:**
- Only use `terraform state push` when you have a recovery file (`errored.tfstate`)
- Never use it with arbitrary state files unless you're certain they're correct
- Always verify state after pushing

**Verification After Recovery:**
- Run `terraform plan` to verify state matches reality
- Check that no unexpected changes are detected
- Verify resources exist in Azure Portal

**Last Updated:** 2026-02-27  
**Maintained By:** DevOps Team

---

## 16. Enterprise-Grade Staged Deployment

### Problem

Large deployments fail due to:
- Long-running AKS operations timing out
- Circular dependencies between resources
- Role assignments not ready when needed
- Terraform stuck on earlier provisioning resources
- Orphaned resources accumulating costs

### Solution: Staged Deployment Script

Use the enterprise deployment script that handles all these issues:

```powershell
cd infra/terraform

# Full deployment with monitoring
.\enterprise-deploy.ps1

# Dry run (shows what would happen)
.\enterprise-deploy.ps1 -DryRun

# Resume from specific stage after failure
.\enterprise-deploy.ps1 -Stage 3
```

### Deployment Stages

| Stage | Resources | Time | Description |
|-------|-----------|------|-------------|
| 1 | Pre-flight | 1-2 min | Cleanup orphaned resources, validate config |
| 2 | Foundation | 3-5 min | Resource Group, VNet, NAT Gateway |
| 3 | Security | 5-10 min | Key Vault, ACR, Private Endpoints |
| 4 | Access | 10-15 min | Bastion, Jumpbox |
| 5 | AKS | 30-60 min | AKS cluster with monitoring |

### Features

- **Auto-recovery**: Handles timeouts gracefully
- **State persistence**: Resume from failed stage
- **Pre-flight checks**: Cleans up soft-deleted Key Vaults, orphaned AD apps
- **Progress monitoring**: Shows AKS provisioning status
- **Role timing**: Waits for resources to stabilize before dependent deployments

---

## 17. Starting Fresh After Manual Resource Deletion

### Scenario

You've deleted Azure resources manually from the Azure Portal (e.g., to save costs) and want to start completely fresh with Terraform. This creates a state mismatch where Terraform thinks resources exist, but they're actually deleted in Azure.

### Why This Happens

**Root Cause:**
- Terraform state file (stored in Azure Storage) still references resources that no longer exist in Azure
- Manual deletion from Azure Portal doesn't update Terraform state
- Terraform will try to manage resources that don't exist, causing errors
- Azure AD resources (applications, service principals) may still exist even after Azure resources are deleted

**Common Scenarios:**
- Cost optimization: Deleting expensive resources (AKS, VMs) manually
- Quick cleanup: Faster than running `terraform destroy`
- Accidental deletion: Resources deleted outside of Terraform
- Testing: Want to redeploy from scratch

**What Gets Left Behind:**
- Terraform state file references
- Azure AD applications and service principals (not automatically deleted)
- Role assignments (may persist)
- Private DNS zones (may persist)
- Storage account blobs (state files)

### How to Fix: Complete Fresh Start

**Step 1: Verify What's Actually Deleted**

Check what resources still exist in Azure:

```bash
# Check Resource Group
az group show --name ola-rg-dev --query "properties.provisioningState" -o tsv 2>&1

# Check AKS cluster
az aks show --resource-group ola-rg-dev --name ola-aks-dev --query "provisioningState" -o tsv 2>&1

# Check Azure AD applications
az ad app list --filter "displayName eq 'github-actions-ola-aks-dev'" --query "[].displayName" -o table 2>&1

# List all resources in resource group
az resource list --resource-group ola-rg-dev --query "[].{name:name, type:type}" -o table 2>&1
```

**Step 2: Clean Up Azure AD Resources (If They Still Exist)**

Azure AD resources persist even after Azure resources are deleted:

```bash
# List Azure AD applications
az ad app list --query "[?contains(displayName, 'ola-aks-dev')].{displayName:displayName, appId:appId, objectId:id}" -o table

# Delete Azure AD application (if found)
# Replace <app-id> with actual app ID
az ad app delete --id <app-id>

# Or delete by display name
az ad app list --filter "displayName eq 'github-actions-ola-aks-dev'" --query "[].id" -o tsv | ForEach-Object { az ad app delete --id $_ }
```

**Step 3: Clean Up Terraform State**

**Option A: Remove All Resources from State (Recommended)**

Remove all resources from Terraform state to start fresh:

```bash
cd infra/terraform

# List all resources in state
terraform state list

# Remove all resources (except data sources - they're safe to keep)
terraform state list | Where-Object { $_ -notmatch "^data\." } | ForEach-Object { 
    Write-Host "Removing: $_"
    terraform state rm $_
}

# Verify state is clean
terraform state list
```

**Option B: Delete State File Entirely (Nuclear Option)**

⚠️ **Warning:** Only use this if you're absolutely sure you want to start completely fresh and you're using version control for your Terraform code.

```bash
cd infra/terraform

# Backup current state first (just in case)
terraform state pull > terraform.tfstate.backup

# Delete state file from Azure Storage
# Note: You'll need to access Azure Storage directly or use Azure Portal
# Or use Azure CLI:
az storage blob delete \
  --account-name olaportfolio001 \
  --container-name tfstate \
  --name terraform.tfstate \
  --auth-mode login
```

**Option C: Use Terraform Refresh (If Resources Still Exist)**

If some resources still exist and you want to sync state:

```bash
cd infra/terraform

# Refresh state to match reality
terraform refresh -var-file="envs/dev/terraform.tfvars"

# This will mark deleted resources as "tainted" or remove them
```

**Step 4: Verify State is Clean**

```bash
# Check state
terraform state list

# Should only show data sources (if any)
# Example output:
# data.azurerm_client_config.current
```

**Step 5: Re-initialize Terraform**

```bash
cd infra/terraform

# Re-initialize Terraform (downloads providers, sets up backend)
terraform init

# Verify backend connection
terraform init -backend-config="resource_group_name=tfstate-rg" \
               -backend-config="storage_account_name=olaportfolio001" \
               -backend-config="container_name=tfstate" \
               -backend-config="key=terraform.tfstate"
```

**Step 6: Verify Configuration**

Check your `terraform.tfvars` file is correct:

```bash
# Review configuration
cat envs/dev/terraform.tfvars

# Validate configuration syntax
terraform validate
```

**Step 7: Plan and Apply Fresh Infrastructure**

```bash
# Create a plan to see what will be created
terraform plan -var-file="envs/dev/terraform.tfvars"

# Review the plan carefully - should show all resources being created

# Apply the infrastructure
terraform apply -var-file="envs/dev/terraform.tfvars"
```

### Prevention

**Best Practices:**

1. **Always Use Terraform Destroy:**
   ```bash
   # Proper way to delete infrastructure
   terraform destroy -var-file="envs/dev/terraform.tfvars"
   ```
   - Terraform handles dependencies correctly
   - State is automatically updated
   - No orphaned resources

2. **Use Targeted Destroy for Cost Savings:**
   ```bash
   # Destroy expensive resources only
   terraform destroy -target=module.aks -var-file="envs/dev/terraform.tfvars"
   terraform destroy -target=module.bastion_jumpbox -var-file="envs/dev/terraform.tfvars"
   ```

3. **Keep State Backups:**
   ```bash
   # Backup state before major changes
   terraform state pull > terraform.tfstate.backup-$(Get-Date -Format "yyyyMMdd-HHmmss").json
   ```

4. **Use State Locking:**
   - Your backend (Azure Storage) already provides state locking
   - Prevents concurrent modifications
   - Always wait for locks to release

5. **Document Manual Deletions:**
   - If you must delete manually, document what was deleted
   - Update Terraform state immediately after
   - Consider using `terraform import` if you recreate resources

### Quick Start Script

Create `start-fresh.ps1`:

```powershell
# Start Fresh Script - Cleans up state after manual resource deletion
# Usage: .\start-fresh.ps1

Write-Host "🧹 Starting Fresh Terraform Setup..." -ForegroundColor Cyan

# Step 1: Check current state
Write-Host "`n📋 Checking current Terraform state..." -ForegroundColor Yellow
cd infra/terraform
$resources = terraform state list 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Terraform state not initialized. Running init..." -ForegroundColor Yellow
    terraform init
    $resources = terraform state list 2>&1
}

# Step 2: Remove all resources from state (except data sources)
Write-Host "`n🗑️  Removing resources from state..." -ForegroundColor Yellow
$resourcesToRemove = $resources | Where-Object { $_ -notmatch "^data\." -and $_ -ne "" }
if ($resourcesToRemove) {
    $resourcesToRemove | ForEach-Object {
        Write-Host "  Removing: $_" -ForegroundColor Gray
        terraform state rm $_ 2>&1 | Out-Null
    }
    Write-Host "✅ Removed $($resourcesToRemove.Count) resources from state" -ForegroundColor Green
} else {
    Write-Host "✅ State is already clean" -ForegroundColor Green
}

# Step 3: Clean up Azure AD resources
Write-Host "`n🔍 Checking for Azure AD resources..." -ForegroundColor Yellow
$adApps = az ad app list --query "[?contains(displayName, 'ola-aks-dev')].displayName" -o tsv 2>&1
if ($adApps) {
    Write-Host "  Found Azure AD applications. Consider cleaning them up manually:" -ForegroundColor Yellow
    $adApps | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    Write-Host "  Run: az ad app list --filter \"displayName eq 'github-actions-ola-aks-dev'\" --query \"[].id\" -o tsv | ForEach-Object { az ad app delete --id `$_ }" -ForegroundColor Cyan
} else {
    Write-Host "✅ No Azure AD applications found" -ForegroundColor Green
}

# Step 4: Re-initialize
Write-Host "`n🔄 Re-initializing Terraform..." -ForegroundColor Yellow
terraform init -upgrade

# Step 5: Validate
Write-Host "`n✔️  Validating configuration..." -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Configuration is valid" -ForegroundColor Green
} else {
    Write-Host "❌ Configuration validation failed" -ForegroundColor Red
    exit 1
}

# Step 6: Show plan
Write-Host "`n📊 Ready to plan and apply!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Review configuration: cat envs/dev/terraform.tfvars" -ForegroundColor White
Write-Host "  2. Create plan: terraform plan -var-file=\"envs/dev/terraform.tfvars\"" -ForegroundColor White
Write-Host "  3. Apply: terraform apply -var-file=\"envs/dev/terraform.tfvars\"" -ForegroundColor White

Write-Host "`n✅ Fresh start complete!" -ForegroundColor Green
```

### Additional Notes

**State File Location:**
- Your state is stored in Azure Storage: `olaportfolio001/tfstate/terraform.tfstate`
- State is versioned and can be recovered if needed
- Use Azure Portal → Storage Account → Blob Service to view/restore state

**What Gets Preserved:**
- Terraform configuration files (`.tf` files)
- Variable files (`terraform.tfvars`)
- Module structure
- Backend configuration

**What Gets Reset:**
- Terraform state (resource tracking)
- Resource IDs and relationships
- Output values

**Cost Considerations:**
- Starting fresh will recreate all resources
- Consider using smaller VM sizes for dev/testing
- Use `terraform plan` to estimate costs before applying
- Consider destroying specific modules instead of everything

---

## 18. AKS VMExtensionProvisioningError on vmssCSE (Exit Code 124)

### Error Message

In the **Activity Log** for the AKS node pool VMSS (e.g. `aks-system-<suffix>-vmss`), you see:

```json
"status": "Failed",
"error": {
  "code": "ResourceOperationFailure",
  "message": "The resource operation completed with terminal provisioning state 'Failed'.",
  "details": [
    {
      "code": "VMExtensionProvisioningError",
      "message": "VM has reported a failure when processing extension 'vmssCSE' (publisher 'Microsoft.Azure.Extensions' and type 'CustomScript'). Error message: 'Enable failed: failed to execute command: command terminated with exit status=124 ..."
    }
  ]
}
```

### Why It Happens

**Root Cause:**
- The AKS system node pool VMSS (`aks-system-...-vmss`) uses the `vmssCSE` **Custom Script Extension** to bootstrap the node (install Kubernetes components, configure networking, pull images, start kubelet, etc.).
- Exit code **124** means the CSE script **timed out** (900s) waiting for required steps to complete.
- In this project, the most common cause is:
  - Complex **NAT Gateway + userDefinedRouting + private cluster** configuration in dev, where outbound connectivity from the `aks-subnet` to required Azure/Microsoft endpoints is too fragile or intermittently broken.
  - As a result, kubelet never starts (`KubeletStartTime = "n/a"` in the CSE logs), and the node never becomes healthy.

**Effect:**
- The system node pool provisioning stays in `Failed` or `Updating`.
- AKS cluster create/update never fully completes.
- Terraform eventually fails with **`context deadline exceeded`** while waiting for the AKS operation.

### How to Fix (Dev Environment Simplification)

For the **dev** environment, we simplify outbound networking by:

1. **Disable NAT Gateway for dev** and rely on the AKS-managed load balancer for outbound:

**File:** `infra/terraform/envs/dev/terraform.tfvars`

```terraform
# NAT Gateway Configuration (Enterprise-Grade: Predictable Egress IPs)
enable_nat_gateway = false # Dev simplification: disable NAT Gateway to use AKS-managed load balancer egress and avoid vmssCSE timeout during cluster bootstrap
# nat_gateway_zones = []   # Empty = zone-redundant (recommended for high availability in environments where NAT Gateway is enabled)
```

2. **Drive AKS `outbound_type` from `enable_nat_gateway`** so the cluster always uses a consistent outbound mode:

**File:** `infra/terraform/main.tf`

```terraform
module "aks" {
  source = "./modules/aks"
  # ...

  # Outbound configuration:
  # - When NAT Gateway is enabled (enterprise-grade): use userDefinedRouting for predictable egress IPs
  # - When NAT Gateway is disabled (dev simplification): fall back to loadBalancer for simpler, more resilient outbound during bootstrap
  outbound_type = var.enable_nat_gateway ? "userDefinedRouting" : "loadBalancer"

  # ...
}
```

With these settings:
- **Dev**: `enable_nat_gateway = false` → `outbound_type = "loadBalancer"`  
  - AKS uses its standard outbound SNAT via the cluster load balancer.
  - The system node pool VMs have reliable internet access during bootstrap, so `vmssCSE` completes and the node pool reaches `Succeeded`.
- **Future prod**: you can re-enable NAT Gateway and keep `outbound_type = "userDefinedRouting"` for predictable egress IPs, after validating connectivity.

### Verification Steps

1. **Clean up failed cluster (optional for dev):**
   ```bash
   terraform destroy -target=module.aks -var-file="envs/dev/terraform.tfvars"
   ```

2. **Apply with the new configuration:**
   ```bash
   cd infra/terraform
   terraform plan  -var-file="envs/dev/terraform.tfvars"
   terraform apply -var-file="envs/dev/terraform.tfvars"
   ```

3. **Confirm node pool status:**
   ```bash
   az aks nodepool show \
     --resource-group ola-rg-dev \
     --cluster-name ola-aks-dev \
     --name system \
     --query "provisioningState" -o tsv
   # Expected: Succeeded
   ```

4. **Check that Terraform no longer reports `context deadline exceeded` while creating/updating the AKS cluster.**

**Last Updated:** 2026-02-27  
**Maintained By:** DevOps Team

---

## 19. Enabling NAT Gateway for Production (Avoiding vmssCSE Timeout)

### Overview

This guide explains how to safely enable **NAT Gateway** for production environments while avoiding the `vmssCSE` timeout error (exit code 124) that occurred in dev.

**Why NAT Gateway for Production:**
- ✅ **Predictable egress IPs**: All outbound traffic uses static public IPs from the NAT Gateway
- ✅ **Security compliance**: Required for firewall allowlists and security policies
- ✅ **Cost optimization**: Single NAT Gateway can serve multiple subnets
- ✅ **Enterprise-grade**: Industry standard for production AKS deployments

**Why It Failed in Dev:**
- Complex routing setup (NAT Gateway + userDefinedRouting + private cluster) created timing/propagation issues
- Route table association timing during cluster bootstrap
- Network connectivity fragility during node initialization

### Production Setup Steps

#### Step 1: Create Production Environment Configuration

**File:** `infra/terraform/envs/prod/terraform.tfvars`

```terraform
# Production Environment Configuration
resource_group_name = "ola-rg-prod"
location            = "uksouth"
aks_name           = "ola-aks-prod"

# NAT Gateway Configuration (Enterprise-Grade: Enabled for Production)
enable_nat_gateway = true  # ✅ ENABLED for production
nat_gateway_zones  = []    # Zone-redundant (recommended for high availability)

# Network Configuration
network_plugin_mode = "overlay"
network_policy      = "cilium"
network_dataplane   = "cilium"
pod_cidr            = "10.244.0.0/16"

# AKS Configuration
aks_private_cluster_enabled = true  # Private cluster for security
# ... rest of your production config ...
```

#### Step 2: Verify Route Table Configuration

The route table is **already correctly configured** in `modules/vnet/main.tf`:

```terraform
resource "azurerm_route_table" "aks_subnet" {
  # Route for VNet traffic
  route {
    name           = "VNetLocal"
    address_prefix = var.address_space[0]  # e.g., 10.0.0.0/16
    next_hop_type  = "VnetLocal"
  }
  
  # Azure services traffic automatically uses Azure's default routing
  # NAT Gateway only handles internet-bound traffic
}
```

**Key Points:**
- ✅ VNet traffic routes to `VnetLocal` (internal communication)
- ✅ Azure services (AKS API server, Azure APIs) use Azure's default routing
- ✅ Internet traffic goes through NAT Gateway (automatic when NAT Gateway is associated with subnet)

#### Step 3: Ensure Proper Dependency Ordering

The Terraform configuration **already handles this correctly**:

```terraform
# In main.tf - AKS module depends on route table association
module "aks" {
  # ...
  depends_on = [
    module.vnet.aks_subnet_route_table_association_id,  # ✅ Route table first
  ]
  outbound_type = var.enable_nat_gateway ? "userDefinedRouting" : "loadBalancer"
  # ...
}
```

**Dependency Chain (Already Correct):**
1. Route table created
2. Route table associated with subnet
3. NAT Gateway associated with subnet
4. AKS cluster created (uses userDefinedRouting)

#### Step 4: Staged Deployment (Recommended)

For production, use **staged deployment** to catch issues early:

**Stage 1: Deploy Infrastructure (Without AKS)**
```bash
cd infra/terraform

# Deploy VNet, NAT Gateway, route tables first
terraform apply \
  -var-file="envs/prod/terraform.tfvars" \
  -target=module.vnet \
  -target=azurerm_resource_group.rg

# Wait for completion, verify NAT Gateway is ready
az network nat gateway show \
  --resource-group ola-rg-prod \
  --name ola-rg-prod-vnet-nat-gateway \
  --query "provisioningState" -o tsv
# Expected: Succeeded
```

**Stage 2: Deploy AKS Cluster**
```bash
# Now deploy AKS (route table and NAT Gateway are ready)
terraform apply -var-file="envs/prod/terraform.tfvars"
```

**Why This Works:**
- Route table and NAT Gateway are fully provisioned and propagated before AKS starts
- Eliminates timing issues during cluster bootstrap
- Nodes can immediately reach required endpoints via NAT Gateway

#### Step 5: Monitor First Cluster Creation

During the first production cluster creation, monitor closely:

```bash
# Terminal 1: Monitor cluster provisioning
watch -n 30 'az aks show --resource-group ola-rg-prod --name ola-aks-prod --query "provisioningState" -o tsv'

# Terminal 2: Monitor node pool
watch -n 30 'az aks nodepool show --resource-group ola-rg-prod --cluster-name ola-aks-prod --name system --query "provisioningState" -o tsv'

# Terminal 3: Monitor Activity Log for errors
az monitor activity-log list \
  --resource-group ola-rg-prod \
  --max-events 10 \
  --query "[?contains(status.value, 'Failed')].{time:eventTimestamp, op:operationName.value, msg:properties.statusMessage}" \
  -o table
```

**What to Watch For:**
- ✅ Cluster `provisioningState` should progress: `Creating` → `Succeeded`
- ✅ Node pool `provisioningState` should progress: `Creating` → `Succeeded`
- ❌ If you see `VMExtensionProvisioningError` with exit code 124, see troubleshooting below

#### Step 6: Verify Connectivity After Creation

Once the cluster is created, verify outbound connectivity:

```bash
# Get a pod shell (if you have kubectl access)
kubectl run test-connectivity --image=curlimages/curl --rm -it --restart=Never -- curl -I https://mcr.microsoft.com

# Check NAT Gateway egress IP
az network public-ip show \
  --resource-group ola-rg-prod \
  --name ola-rg-prod-vnet-nat-gateway-pip \
  --query "ipAddress" -o tsv

# Verify this IP is used for outbound traffic (check firewall logs, etc.)
```

### Troubleshooting Production NAT Gateway Issues

#### If You Still See vmssCSE Timeout (Exit Code 124)

**1. Verify Route Table Association:**
```bash
az network vnet subnet show \
  --resource-group ola-rg-prod \
  --vnet-name ola-rg-prod-vnet \
  --name aks-subnet \
  --query "routeTable.id" -o tsv
# Should return route table resource ID
```

**2. Verify NAT Gateway Association:**
```bash
az network vnet subnet show \
  --resource-group ola-rg-prod \
  --vnet-name ola-rg-prod-vnet \
  --name aks-subnet \
  --query "natGateway.id" -o tsv
# Should return NAT Gateway resource ID
```

**3. Check Route Table Routes:**
```bash
az network route-table route list \
  --resource-group ola-rg-prod \
  --route-table-name aks-subnet-route-table \
  --query "[].{name:name, prefix:addressPrefix, nextHop:nextHopType}" \
  -o table
# Should show VNetLocal route
```

**4. Verify NAT Gateway Public IP:**
```bash
az network public-ip show \
  --resource-group ola-rg-prod \
  --name ola-rg-prod-vnet-nat-gateway-pip \
  --query "{ip:ipAddress, state:provisioningState}" -o json
# Should show IP address and Succeeded state
```

**5. If Issues Persist:**
- **Temporary workaround**: Disable NAT Gateway, deploy cluster, then enable NAT Gateway and update cluster
- **Permanent fix**: Ensure route table and NAT Gateway are created **before** AKS cluster (use staged deployment above)

### Best Practices for Production

**1. Always Use Staged Deployment:**
- Deploy network infrastructure first
- Wait for completion
- Then deploy AKS cluster

**2. Monitor First Deployment:**
- Watch Activity Log for errors
- Monitor node pool provisioning state
- Verify connectivity after creation

**3. Test in Staging First:**
- Create a staging environment with NAT Gateway enabled
- Validate the full deployment process
- Only then deploy to production

**4. Use Zone-Redundant NAT Gateway:**
```terraform
nat_gateway_zones = []  # Empty = zone-redundant (recommended)
```

**5. Document Egress IPs:**
- Record NAT Gateway public IP addresses
- Update firewall allowlists
- Document for security/compliance audits

### Configuration Summary

**Production (`envs/prod/terraform.tfvars`):**
```terraform
enable_nat_gateway = true   # ✅ Enabled
nat_gateway_zones  = []     # Zone-redundant
```

**Development (`envs/dev/terraform.tfvars`):**
```terraform
enable_nat_gateway = false  # ✅ Disabled (simpler, faster)
```

**Terraform automatically handles:**
- `outbound_type = "userDefinedRouting"` when NAT Gateway enabled
- `outbound_type = "loadBalancer"` when NAT Gateway disabled
- Proper dependency ordering (route table → NAT Gateway → AKS)

### Additional Resources

- **Azure Docs**: [NAT Gateway with AKS](https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype#nat-gateway)
- **Troubleshooting**: See Section 18 for vmssCSE timeout details
- **Route Tables**: See Section 2 for route table configuration

**Last Updated:** 2026-02-27  
**Maintained By:** DevOps Team
