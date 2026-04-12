# Handle AKS Cluster Creation Timeout
# This script helps recover from AKS cluster creation timeouts

Write-Host "🔍 Checking AKS Cluster Status..." -ForegroundColor Cyan

$resourceGroup = "ola-rg-dev"
$clusterName = "ola-aks-dev"

# Check cluster status
$cluster = az aks show --resource-group $resourceGroup --name $clusterName --query "{name:name, provisioningState:provisioningState, powerState:powerState.code, fqdn:fqdn}" -o json 2>&1 | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: Could not retrieve cluster status" -ForegroundColor Red
    exit 1
}

Write-Host "`n📊 Cluster Status:" -ForegroundColor Yellow
Write-Host "  Name: $($cluster.name)" -ForegroundColor Gray
Write-Host "  Provisioning State: $($cluster.provisioningState)" -ForegroundColor Gray
Write-Host "  Power State: $($cluster.powerState)" -ForegroundColor Gray
Write-Host "  FQDN: $($cluster.fqdn)" -ForegroundColor Gray

if ($cluster.provisioningState -eq "Creating") {
    Write-Host "`n⏳ Cluster is still being created..." -ForegroundColor Yellow
    Write-Host "   This can take 120-180+ minutes for complex network configurations." -ForegroundColor Gray
    Write-Host "   Options:" -ForegroundColor Cyan
    Write-Host "   1. Wait for creation to complete (recommended)" -ForegroundColor White
    Write-Host "   2. Check for errors in Azure Portal Activity Log" -ForegroundColor White
    Write-Host "   3. Monitor progress: az aks show --resource-group $resourceGroup --name $clusterName --query provisioningState -o tsv" -ForegroundColor Gray
    
    Write-Host "`n   Once creation completes, run:" -ForegroundColor Cyan
    Write-Host "   terraform refresh -var-file=`"envs/dev/terraform.tfvars`"" -ForegroundColor White
    Write-Host "   terraform apply -var-file=`"envs/dev/terraform.tfvars`"" -ForegroundColor White
}
elseif ($cluster.provisioningState -eq "Succeeded") {
    Write-Host "`n✅ Cluster creation completed!" -ForegroundColor Green
    Write-Host "   Refreshing Terraform state..." -ForegroundColor Yellow
    
    cd $PSScriptRoot
    terraform refresh -var-file="envs/dev/terraform.tfvars" 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ State refreshed successfully" -ForegroundColor Green
        Write-Host "`n   Next step: terraform apply -var-file=`"envs/dev/terraform.tfvars`"" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  State refresh had issues. You may need to import the cluster:" -ForegroundColor Yellow
        Write-Host "   terraform import -var-file=`"envs/dev/terraform.tfvars`" module.aks.azurerm_kubernetes_cluster.aks /subscriptions/<subscription-id>/resourceGroups/$resourceGroup/providers/Microsoft.ContainerService/managedClusters/$clusterName" -ForegroundColor Gray
    }
}
elseif ($cluster.provisioningState -eq "Failed") {
    Write-Host "`n❌ Cluster creation failed!" -ForegroundColor Red
    Write-Host "   Check Azure Portal Activity Log for error details" -ForegroundColor Yellow
    Write-Host "   You may need to delete and recreate the cluster" -ForegroundColor Yellow
}
else {
    Write-Host "`n⚠️  Unexpected state: $($cluster.provisioningState)" -ForegroundColor Yellow
    Write-Host "   Check Azure Portal for details" -ForegroundColor Gray
}
