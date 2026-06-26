# Clean dev bootstrap — Phase 1 from your laptop (private AKS safe settings).
# Usage: .\bootstrap-dev.ps1 [-SkipApply] [-DryRun]
#
# Phase 1 creates: RG, VNet, NAT, ACR, KV, AKS, Bastion, ops VM, GitHub OIDC.
# Skips: Argo CD, Container Insights addon, VM tool extensions (install on VM in Phase 2).
#
# After Phase 1 (~2–3h): Bastion → ops VM → .\scripts\phase2-on-vm.sh

param(
    [switch]$SkipApply,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$VarFile = "envs/dev/terraform.tfvars"
$KvName  = "ola-kv-dev"
$Location = "uksouth"

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "OK: $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "WARN: $msg" -ForegroundColor Yellow }

Write-Host "=== Portfolio dev bootstrap (Phase 1) ===" -ForegroundColor White

# --- Preflight ---
Write-Step "Azure CLI login"
$account = az account show 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Run: az login" -ForegroundColor Red
    exit 1
}
$info = $account | ConvertFrom-Json
Write-Ok "Logged in as $($info.user.name) | sub: $($info.name)"

Write-Step "Terraform init"
terraform init -upgrade | Out-Host
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Ok "Terraform initialized"

Write-Step "Validate configuration"
terraform validate | Out-Host
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Step "Check var file exists"
if (-not (Test-Path $VarFile)) {
    Copy-Item "envs/dev/terraform.tfvars.example" $VarFile
    Write-Warn "Created $VarFile from example — review before apply"
}

Write-Step "Soft-deleted Key Vault (blocks recreate)"
$deleted = az keyvault list-deleted --query "[?name=='$KvName']" -o json 2>&1 | ConvertFrom-Json
if ($deleted -and $deleted.Count -gt 0) {
    if ($DryRun) {
        Write-Warn "[DRY RUN] Would purge $KvName"
    } else {
        Write-Host "Purging $KvName..." -ForegroundColor Yellow
        az keyvault purge --name $KvName --location $Location 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Purge failed — wait for scheduled purge or rename key_vault_name in tfvars"
        } else {
            Write-Ok "Key Vault purged"
            Start-Sleep -Seconds 15
        }
    }
} else {
    Write-Ok "No soft-deleted Key Vault"
}

Write-Step "Orphan resource groups"
$olaRg = az group show -g ola-rg-dev --query name -o tsv 2>$null
if ($olaRg) {
    Write-Warn "ola-rg-dev already exists — terraform apply will update or fail if drifted"
} else {
    Write-Ok "ola-rg-dev not present (clean create)"
}

Write-Step "Remote state"
$state = terraform state list 2>&1
if ($state -and ($state | Where-Object { $_ -notmatch "^data\." })) {
    Write-Warn "State has resources from a prior run. If Azure was destroyed, run .\start-fresh.ps1 first"
} else {
    Write-Ok "State empty (fresh start)"
}

# --- Phase 1 apply ---
if ($SkipApply) {
    Write-Host "`nSkipApply set. Run manually:" -ForegroundColor Yellow
    Write-Host "  .\apply-without-argocd.ps1" -ForegroundColor Gray
    exit 0
}

if ($DryRun) {
    Write-Step "Plan (dry run)"
    $env:KUBECONFIG = ""
    terraform plan -var-file=$VarFile -var="enable_argocd=false" -var="enable_aks_monitoring_addon=false"
    exit $LASTEXITCODE
}

Write-Step "Phase 1 apply (enable_argocd=false, enable_aks_monitoring_addon=false)"
Write-Host "Expected duration: 2–3 hours. Do not close this terminal." -ForegroundColor Yellow
& "$PSScriptRoot\apply-without-argocd.ps1"
$exit = $LASTEXITCODE

if ($exit -eq 0) {
    Write-Host "`n=== Phase 1 complete ===" -ForegroundColor Green
    Write-Host @"

Next (on ops VM via Azure Bastion):
  1. git clone <this-repo> && cd Olatunbosun-portfolio-project
  2. ./scripts/phase2-on-vm.sh

Or from infra/terraform on the VM:
  terraform apply -var-file=envs/dev/terraform.tfvars \
    -var=enable_argocd=true -var=enable_aks_monitoring_addon=true -auto-approve

See docs/QUICK_START.md for GitHub secrets, runner, Argo CD app, and DNS.
"@ -ForegroundColor Gray
}

exit $exit
