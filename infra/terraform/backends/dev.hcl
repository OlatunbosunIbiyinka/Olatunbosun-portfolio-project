# Partial backend config for the development environment.
# Merges with backend.tf on init. Dev state key matches the live deployed stack.
#
#   terraform init -reconfigure -backend-config=backends/dev.hcl
#
key = "terraform.tfstate"
