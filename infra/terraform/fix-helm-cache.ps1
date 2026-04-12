# Fix Helm Cache for Terraform Helm Provider
# Clears corrupted cache and populates ArgoCD repo. Sets HELM_CACHE_HOME so Terraform uses same cache.
# Usage: . .\fix-helm-cache.ps1  (dot-source to set env in current session, then run terraform)
#    Or: .\fix-helm-cache.ps1 plan    (prepare cache and run terraform plan)
#    Or: .\fix-helm-cache.ps1 apply   (prepare cache and run terraform apply)
param([string]$TerraformCmd = "")

$ErrorActionPreference = "Stop"
$helmCache = "$env:LOCALAPPDATA\Temp\helm"
Write-Host "Preparing Helm cache for Terraform Helm Provider" -ForegroundColor Cyan

$cacheLocations = @(
    "$env:LOCALAPPDATA\Temp\helm",
    "$env:USERPROFILE\.helm\cache",
    "$env:TEMP\helm"
)
foreach ($location in $cacheLocations) {
    if (Test-Path $location) {
        Remove-Item -Path $location -Force -Recurse -ErrorAction SilentlyContinue
    }
}
Get-ChildItem "$env:LOCALAPPDATA\Temp" -Filter "*prometheus*" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Path $helmCache -Force | Out-Null
$env:HELM_CACHE_HOME = $helmCache
$env:HELM_REPOSITORY_CACHE = "$helmCache\repository"

$helm = Get-Command helm -ErrorAction SilentlyContinue
if (-not $helm) {
    Write-Host "Helm CLI required. Install: winget install Helm.Helm" -ForegroundColor Red
    exit 1
}
helm repo add argoproj https://argoproj.github.io/argo-helm 2>$null
helm repo update 2>$null
Write-Host "Helm cache ready at $helmCache" -ForegroundColor Green

if ($TerraformCmd -eq "plan") {
    terraform plan -var-file="envs/dev/terraform.tfvars" @args
} elseif ($TerraformCmd -eq "apply") {
    terraform apply -var-file="envs/dev/terraform.tfvars" @args
} elseif ($TerraformCmd -ne "") {
    terraform $TerraformCmd -var-file="envs/dev/terraform.tfvars" @args
} else {
    Write-Host "Run terraform in this same session (HELM_CACHE_HOME is set), or: .\fix-helm-cache.ps1 plan" -ForegroundColor Cyan
}
