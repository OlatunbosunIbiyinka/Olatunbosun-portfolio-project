# Stable phase 3 — AKS-native NAT egress (predictable outbound IP)
#
# managedNATGateway is NOT allowed with a custom/BYO VNet (private AKS).
# Use userAssignedNATGateway: Terraform creates NAT + associates it to aks-subnet.
aks_outbound_type = "userAssignedNATGateway"

# Optional NAT zones (empty = zone-redundant):
# nat_gateway_zones = []
