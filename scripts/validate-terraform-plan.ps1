# Run a safe Terraform plan from a laptop (private AKS API is not reachable).
# Usage: .\scripts\validate-terraform-plan.ps1
param(
    [string]$VarFile = "envs/dev/terraform.tfvars"
)

$ErrorActionPreference = "Stop"
Push-Location "$PSScriptRoot\..\infra\terraform"

Write-Host "Terraform init (reconfigure if backend changed)..." -ForegroundColor Cyan
terraform init -reconfigure -input=false

Write-Host "Plan with -refresh=false (remote state only; safe from laptop)..." -ForegroundColor Cyan
terraform plan -refresh=false -var-file="$VarFile" -input=false -compact-warnings

Pop-Location
