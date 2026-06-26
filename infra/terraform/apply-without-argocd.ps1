# Phase 1: Apply all infrastructure EXCEPT ArgoCD (for private AKS from laptop)
# Use this when the AKS API is private and your laptop cannot reach the cluster API.
# After this succeeds, connect to the jumpbox VM and run phase 2 (enable_argocd=true).
# See HELM_CACHE_FIX.md "Private AKS: two-phase apply"

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Laptop kubeconfig often points at localhost and breaks Terraform refresh of Argo CD state.
$env:KUBECONFIG = ""

# Stale Argo CD resources in state cannot be refreshed from a laptop (private API / localhost kubeconfig).
$argocdStateAddresses = @(
  'module.argocd[0].kubernetes_namespace_v1.argocd',
  'module.argocd[0].helm_release.argocd'
)
foreach ($address in $argocdStateAddresses) {
  $listed = terraform state list 2>$null | Select-String -SimpleMatch $address
  if ($listed) {
    Write-Host "Removing stale state: $address" -ForegroundColor Yellow
    terraform state rm $address 2>&1 | Out-Null
  }
}

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
terraform apply -var-file="envs/dev/terraform.tfvars" -var="enable_argocd=false" -var="enable_aks_monitoring_addon=false" -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nPhase 1 done. Next: connect to the jumpbox VM and run:" -ForegroundColor Green
    Write-Host '  ./scripts/phase2-on-vm.sh' -ForegroundColor Gray
    Write-Host '  # or: terraform apply -var-file="envs/dev/terraform.tfvars" -var="enable_argocd=true" -var="enable_aks_monitoring_addon=true" -auto-approve' -ForegroundColor Gray
}
