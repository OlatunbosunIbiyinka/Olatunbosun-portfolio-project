# Partial backend config for staging (codified — not deployed by default).
#
#   terraform init -reconfigure -backend-config=backends/staging.hcl
#   terraform plan  -var-file=envs/staging/terraform.tfvars
#
key = "staging/terraform.tfstate"
