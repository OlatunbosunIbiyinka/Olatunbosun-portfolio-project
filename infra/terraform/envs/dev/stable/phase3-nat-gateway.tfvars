# Stable phase 3 — AKS-native NAT egress (predictable outbound IP, no UDR)
#
# managedNATGateway is NOT allowed with a custom/BYO VNet (private AKS).
# Use userAssignedNATGateway: Terraform creates NAT + associates it to aks-subnet.
# Do NOT use enable_nat_gateway + userDefinedRouting (breaks node egress).
aks_outbound_type = "userAssignedNATGateway"

# Optional NAT zones (empty = zone-redundant):
# nat_gateway_zones = []
