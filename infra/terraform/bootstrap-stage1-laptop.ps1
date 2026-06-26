# Stage 1 (laptop): foundation already deployed + Bastion + ops VM. Does NOT create AKS.
# Usage: .\bootstrap-stage1-laptop.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$env:KUBECONFIG = ""
$VarFile = "envs/dev/terraform.tfvars"

Write-Host "=== Stage 1: Bastion + ops VM (no AKS) ===" -ForegroundColor Cyan

terraform init -upgrade | Out-Host
terraform validate | Out-Host

Write-Host "`nDeploying module.bastion_jumpbox only (~15 min)..." -ForegroundColor Yellow
terraform apply `
  -var-file="$VarFile" `
  -var="enable_argocd=false" `
  -var="enable_aks_monitoring_addon=false" `
  -target="module.bastion_jumpbox[0]" `
  -auto-approve

if ($LASTEXITCODE -eq 0) {
  Write-Host @"

=== Stage 1 complete ===
Connect: Azure Portal -> ola-rg-dev -> aks-operations-vm -> Connect -> Bastion (Azure AD)

On the VM:
  git clone https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project.git
  cd Olatunbosun-portfolio-project
  chmod +x scripts/bootstrap-stage2-from-vm.sh
  ./scripts/bootstrap-stage2-from-vm.sh
"@ -ForegroundColor Green
}

exit $LASTEXITCODE
