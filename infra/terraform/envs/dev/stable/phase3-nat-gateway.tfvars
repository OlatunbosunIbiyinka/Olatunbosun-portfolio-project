# Stable phase 3 — AKS-native NAT egress (predictable outbound IP, no UDR)
#
# Prefer managedNATGateway (AKS owns the NAT).
# Alternative: userAssignedNATGateway (creates module.vnet NAT + subnet association only).
aks_outbound_type = "managedNATGateway"

# Optional tuning for managedNATGateway:
# managed_nat_gateway_outbound_ip_count = 1
# nat_gateway_idle_timeout_in_minutes   = 4

# For BYO NAT instead, use:
# aks_outbound_type = "userAssignedNATGateway"
