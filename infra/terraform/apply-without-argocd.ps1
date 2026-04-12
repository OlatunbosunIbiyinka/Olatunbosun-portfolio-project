# Phase 1: Apply all infrastructure EXCEPT ArgoCD (for private AKS from laptop)
# Use this when the AKS API is private and your laptop cannot resolve *.privatelink.*.azmk8s.io
# After this succeeds, connect to the jumpbox VM and run terraform apply with enable_argocd=true
# See HELM_CACHE_FIX.md "Private AKS: two-phase apply"

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Prepare Helm cache (avoids external data source errors during plan)
$helmCache = "$env:LOCALAPPDATA\Temp\helm"
@("$env:LOCALAPPDATA\Temp\helm", "$env:USERPROFILE\.helm\cache", "$env:TEMP\helm") | ForEach-Object {
    if (Test-Path $_) { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }
}
New-Item -ItemType Directory -Path $helmCache -Force | Out-Null
$env:HELM_CACHE_HOME = $helmCache
$env:HELM_REPOSITORY_CACHE = "$helmCache\repository"
$h = Get-Command helm -ErrorAction SilentlyContinue
if ($h) { helm repo add argoproj https://argoproj.github.io/argo-helm 2>&1 | Out-Null; helm repo update 2>&1 | Out-Null }

Write-Host "Applying with enable_argocd=false (skip ArgoCD; create VM and rest)..." -ForegroundColor Cyan
terraform apply -var-file="envs/dev/terraform.tfvars" -var="enable_argocd=false" -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nPhase 1 done. Next: connect to the jumpbox VM and run:" -ForegroundColor Green
    Write-Host '  terraform apply -var-file="envs/dev/terraform.tfvars" -var="enable_argocd=true" -auto-approve' -ForegroundColor Gray
}
