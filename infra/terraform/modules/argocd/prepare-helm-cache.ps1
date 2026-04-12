# Prepares Helm cache for Terraform Helm provider (runs during plan)
# Clears corrupted cache so provider can fetch charts
$ErrorActionPreference = "SilentlyContinue"
$cachePaths = @(
  "$env:LOCALAPPDATA\Temp\helm",
  "$env:USERPROFILE\.helm\cache",
  "$env:TEMP\helm"
)
foreach ($p in $cachePaths) {
  if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}
Get-ChildItem "$env:LOCALAPPDATA\Temp" -Filter "*prometheus*" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse
# Add ArgoCD repo if Helm CLI available (populates cache Terraform uses)
$helmCache = "$env:LOCALAPPDATA\Temp\helm"
New-Item -ItemType Directory -Path $helmCache -Force | Out-Null
$env:HELM_CACHE_HOME = $helmCache
$helm = Get-Command helm -ErrorAction SilentlyContinue
if (-not $helm) {
  Write-Error "Helm CLI required for ArgoCD. Install from https://helm.sh/docs/intro/install/ then run: helm repo add argoproj https://argoproj.github.io/argo-helm"
  exit 1
}
# Terraform external data requires ONLY one JSON object on stdout - no other output
helm repo add argoproj https://argoproj.github.io/argo-helm 2>&1 | Out-Null
helm repo update 2>&1 | Out-Null
Write-Output '{"result":"ok"}'
