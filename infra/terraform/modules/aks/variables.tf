variable "resource_group_name" {
  description = "Resource group for AKS"
  type        = string
}

variable "location" {
  description = "Azure region for AKS"
  type        = string
}

variable "aks_name" {
  description = "AKS cluster name"
  type        = string
}

variable "acr_id" {
  description = "ACR resource ID for attaching to AKS"
  type        = string
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS nodes (required for VNet integration)"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS SKU tier - 'Free' (basic, no SLA) or 'Standard' (production-grade with SLA). Enterprise-grade: Use 'Standard'."
  type        = string
  default     = "Standard" # Enterprise-grade: Standard tier for production
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "sku_tier must be either 'Free' or 'Standard'."
  }
}

variable "network_plugin" {
  description = "Network plugin (azure or kubenet). Enterprise-grade: Use 'azure' with overlay mode."
  type        = string
  default     = "azure"
}

variable "network_plugin_mode" {
  description = "Network plugin mode. Enterprise-grade: Use 'overlay' for Azure CNI Overlay (better IP management, scalability)."
  type        = string
  default     = "overlay"
  validation {
    condition     = contains(["overlay", null], var.network_plugin_mode) || var.network_plugin_mode == ""
    error_message = "network_plugin_mode must be 'overlay' for Azure CNI Overlay or empty/null for standard Azure CNI."
  }
}

variable "network_policy" {
  description = "Network policy engine. Enterprise-grade: Use 'cilium' for advanced network policies and observability."
  type        = string
  default     = "cilium"
  validation {
    condition     = contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "network_policy must be 'azure', 'calico', or 'cilium'."
  }
}

variable "network_dataplane" {
  description = "Network dataplane. REQUIRED: Must be 'cilium' when network_policy = 'cilium'. Enterprise-grade: Use 'cilium' for Cilium dataplane."
  type        = string
  default     = "cilium"
  validation {
    condition     = contains(["azure", "cilium"], var.network_dataplane)
    error_message = "network_dataplane must be 'azure' or 'cilium'."
  }
}

variable "pod_cidr" {
  description = "CIDR for Kubernetes pods (required for overlay mode). Default: 10.244.0.0/16"
  type        = string
  default     = "10.244.0.0/16"
}

variable "load_balancer_sku" {
  description = "Load balancer SKU (basic or standard)"
  type        = string
  default     = "standard"
}

variable "outbound_type" {
  description = "Outbound type: 'loadBalancer' (default) or 'userDefinedRouting' (for NAT Gateway). Enterprise-grade: Use 'userDefinedRouting' with NAT Gateway for predictable egress IPs."
  type        = string
  default     = "userDefinedRouting" # Enterprise-grade: Use NAT Gateway for predictable egress IPs
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services. Must NOT overlap with VNet subnets. Default: 10.1.0.0/16 (non-overlapping with common VNet ranges)"
  type        = string
  default     = "10.1.0.0/16"  # Changed from 10.0.0.0/16 to avoid overlap with VNet subnets
}

variable "dns_service_ip" {
  description = "DNS service IP (must be within service CIDR). Updated to match new service_cidr default (10.1.0.0/16)"
  type        = string
  default     = "10.1.0.10"  # Updated to match new service_cidr (10.1.0.0/16)
}

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "system"
}

variable "default_node_pool_node_count" {
  description = "Number of nodes in default pool"
  type        = number
  default     = 1
}

variable "default_node_pool_vm_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "default_node_pool_os_disk_size_gb" {
  description = "OS disk size in GB for default node pool"
  type        = number
  default     = 128
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for default node pool"
  type        = bool
  default     = true
}

# Auto-scaler profile variables - Enterprise-grade: Compliance-focused defaults
variable "auto_scaler_balance_similar_node_groups" {
  description = "Balance similar node groups in cluster autoscaler (compliance: false for predictable scaling)"
  type        = bool
  default     = false
}

variable "auto_scaler_max_graceful_termination_sec" {
  description = "Maximum graceful termination time in seconds (compliance: 600s for safe pod termination)"
  type        = string
  default     = "600"
}

variable "auto_scaler_scale_down_delay_after_add" {
  description = "Time to wait before scaling down after adding nodes (compliance: 10m for stability)"
  type        = string
  default     = "10m"
}

variable "auto_scaler_scale_down_unneeded" {
  description = "Time before unneeded nodes are removed (compliance: 10m for cost optimization)"
  type        = string
  default     = "10m"
}

variable "auto_scaler_scale_down_utilization_threshold" {
  description = "Node utilization threshold for scale down (compliance: 0.5 for efficient resource usage)"
  type        = string
  default     = "0.5"
}

variable "auto_scaler_scan_interval" {
  description = "How often cluster autoscaler scans for changes (compliance: 10s for responsive scaling)"
  type        = string
  default     = "10s"
}

variable "min_node_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
  default     = 30
}

variable "os_sku" {
  description = "OS SKU (Ubuntu or AzureLinux)"
  type        = string
  default     = "Ubuntu"
}

variable "auto_upgrade_enabled" {
  description = "Enable automatic node OS upgrades"
  type        = bool
  default     = true
}

variable "node_labels" {
  description = "Additional labels for default node pool (system labels are added automatically)"
  type        = map(string)
  default     = {}
}

variable "system_pool_taints" {
  description = "Taints for system node pool to prevent user workloads. Default: CriticalAddonsOnly=true:NoSchedule"
  type        = list(string)
  default     = ["CriticalAddonsOnly=true:NoSchedule"]
}

variable "node_taints" {
  description = "Taints for additional node pools (deprecated, use pool-specific taints)"
  type        = list(string)
  default     = []
}

variable "oidc_issuer_enabled" {
  description = "Enable OIDC issuer for Workload Identity"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Workload Identity"
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server"
  type        = list(string)
  default     = []
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy"
  type        = bool
  default     = true
}

variable "http_application_routing_enabled" {
  description = "Enable HTTP application routing"
  type        = bool
  default     = false
}

variable "ingress_application_gateway_id" {
  description = "Application Gateway ID for ingress"
  type        = string
  default     = null
}

variable "maintenance_window_day" {
  description = "Day of week for maintenance window"
  type        = string
  default     = "Sunday"
}

variable "maintenance_window_hours" {
  description = "Hours for maintenance window"
  type        = list(number)
  default     = [2, 3, 4]
}

variable "automatic_channel_upgrade" {
  description = "Automatic channel upgrade (patch, rapid, node-image, none)"
  type        = string
  default     = "patch"
}

variable "local_account_disabled" {
  description = "Disable local accounts (use Azure AD only)"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Azure AD admin group object IDs"
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC"
  type        = bool
  default     = true
}

variable "additional_node_pools" {
  description = "Additional node pools configuration"
  type = map(object({
    vm_size             = string
    node_count          = number
    os_disk_size_gb     = number
    os_sku              = string
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    max_pods            = number
    node_labels         = map(string)
    node_taints         = list(string)
    mode                = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to AKS cluster"
  type        = map(string)
  default     = {}
}
