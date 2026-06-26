# Partial backend config for production (codified — not deployed by default).
#
#   terraform init -reconfigure -backend-config=backends/prod.hcl
#   terraform plan  -var-file=envs/prod/terraform.tfvars
#
key = "prod/terraform.tfstate"
