# Stable phase 1 — dedicated workload node pool + system pool taints
system_pool_taints = ["CriticalAddonsOnly=true:NoSchedule"]

workload_node_pools = {
  "workload" = {
    vm_size             = "Standard_D4s_v3"
    node_count          = 1
    os_disk_size_gb     = 128
    os_sku              = "Ubuntu"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    max_pods            = 30
    node_labels = {
      "pool.type"               = "user"
      "workload"                = "application"
      "node.kubernetes.io/role" = "workload"
    }
    node_taints = []
    mode        = "User"
  }
}
