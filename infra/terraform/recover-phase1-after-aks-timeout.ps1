# Recover Phase 1 when terraform apply times out but AKS is still Creating/Succeeded in Azure.
# Usage: .\recover-phase1-after-aks-timeout.ps1 [-MaxWaitMinutes 120]

param(
    [int]$MaxWaitMinutes = 180,
    [string]$VarFile = "envs/dev/terraform.tfvars",
    [string]$ResourceGroup = "ola-rg-dev",
    [string]$ClusterName = "ola-aks-dev"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$env:KUBECONFIG = ""

$subId = (az account show --query id -o tsv)
$aksId = "/subscriptions/$subId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$ClusterName"

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }

Write-Step "Waiting for AKS provisioningState = Succeeded (max ${MaxWaitMinutes}m)"
$deadline = (Get-Date).AddMinutes($MaxWaitMinutes)
$state = "Creating"

while ((Get-Date) -lt $deadline) {
    $state = az aks show -g $ResourceGroup -n $ClusterName --query provisioningState -o tsv 2>$null
    if ($state -eq "Succeeded") { Write-Host "OK: AKS Succeeded" -ForegroundColor Green; break }
    if ($state -eq "Failed") {
        Write-Host "AKS Failed — check Azure Portal Activity Log" -ForegroundColor Red
        exit 1
    }
    Write-Host "$(Get-Date -Format HH:mm:ss) AKS=$state — waiting 60s..."
    Start-Sleep -Seconds 60
}

if ($state -ne "Succeeded") {
    Write-Host "Timed out waiting for AKS. Re-run this script later." -ForegroundColor Yellow
    exit 1
}

Write-Step "Import AKS cluster into state (if missing)"
$inState = terraform state list 2>$null | Select-String "module.aks.azurerm_kubernetes_cluster.aks"
if (-not $inState) {
    terraform import -var-file=$VarFile -var="enable_argocd=false" -var="enable_aks_monitoring_addon=false" `
        module.aks.azurerm_kubernetes_cluster.aks $aksId
    if ($LASTEXITCODE -ne 0) { exit 1 }
} else {
    Write-Host "AKS already in state" -ForegroundColor Gray
}

Write-Step "Complete Phase 1 (bastion, node pools, role assignments)"
terraform apply -var-file=$VarFile -var="enable_argocd=false" -var="enable_aks_monitoring_addon=false" -auto-approve
exit $LASTEXITCODE
