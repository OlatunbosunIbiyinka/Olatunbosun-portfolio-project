# Safe Destroy Script - Handles AKS cluster that's still creating
# This script safely destroys infrastructure even if AKS is still being created

Write-Host "🔍 Checking Infrastructure Status..." -ForegroundColor Cyan

$resourceGroup = "ola-rg-dev"
$clusterName = "ola-aks-dev"

# Check if AKS cluster exists and its state
Write-Host "`n📊 Checking AKS Cluster Status..." -ForegroundColor Yellow
$cluster = az aks show --resource-group $resourceGroup --name $clusterName --query "{provisioningState:provisioningState, powerState:powerState.code}" -o json 2>&1 | ConvertFrom-Json

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Cluster State: $($cluster.provisioningState)" -ForegroundColor Gray
    Write-Host "  Power State: $($cluster.powerState)" -ForegroundColor Gray
    
    if ($cluster.provisioningState -eq "Creating") {
        Write-Host "`n⚠️  WARNING: AKS cluster is still being created!" -ForegroundColor Yellow
        Write-Host "   Terraform destroy will NOT delete the AKS cluster (it's not in state)." -ForegroundColor Yellow
        Write-Host "   You have two options:" -ForegroundColor Cyan
        Write-Host "`n   Option 1: Cancel AKS creation first (recommended for cost savings)" -ForegroundColor White
        Write-Host "     az aks delete --resource-group $resourceGroup --name $clusterName --yes" -ForegroundColor Gray
        Write-Host "     (This will cancel the creation and delete the cluster)" -ForegroundColor Gray
        Write-Host "`n   Option 2: Let Terraform destroy other resources, then manually delete AKS" -ForegroundColor White
        Write-Host "     terraform destroy -var-file=`"envs/dev/terraform.tfvars`"" -ForegroundColor Gray
        Write-Host "     az aks delete --resource-group $resourceGroup --name $clusterName --yes" -ForegroundColor Gray
        
        $choice = Read-Host "`n   Choose option (1 or 2, or 'c' to cancel)"
        
        if ($choice -eq "1") {
            Write-Host "`n🗑️  Canceling AKS cluster creation..." -ForegroundColor Yellow
            az aks delete --resource-group $resourceGroup --name $clusterName --yes 2>&1 | Out-Null
            Write-Host "   Waiting for deletion to start (this may take a few minutes)..." -ForegroundColor Gray
            Start-Sleep -Seconds 30
            
            # Wait for cluster to be deleted or creation to be canceled
            $maxWait = 10
            $waited = 0
            while ($waited -lt $maxWait) {
                $status = az aks show --resource-group $resourceGroup --name $clusterName --query "provisioningState" -o tsv 2>&1
                if ($LASTEXITCODE -ne 0 -or $status -eq "Deleting" -or $status -eq "Failed") {
                    break
                }
                Write-Host "   Still canceling... ($waited/$maxWait)" -ForegroundColor Gray
                Start-Sleep -Seconds 30
                $waited++
            }
            
            Write-Host "`n✅ Proceeding with Terraform destroy..." -ForegroundColor Green
        }
        elseif ($choice -eq "2") {
            Write-Host "`n⚠️  Proceeding with Terraform destroy (AKS will need manual deletion)" -ForegroundColor Yellow
        }
        else {
            Write-Host "`n❌ Cancelled" -ForegroundColor Red
            exit 0
        }
    }
    elseif ($cluster.provisioningState -eq "Succeeded") {
        Write-Host "`n✅ Cluster is ready. Terraform destroy will handle it." -ForegroundColor Green
    }
    elseif ($cluster.provisioningState -eq "Deleting") {
        Write-Host "`n⏳ Cluster is already being deleted. Waiting..." -ForegroundColor Yellow
    }
}
else {
    Write-Host "  ✅ AKS cluster doesn't exist or was already deleted" -ForegroundColor Green
}

# Check Terraform state
Write-Host "`n📋 Checking Terraform State..." -ForegroundColor Yellow
cd $PSScriptRoot
$stateResources = terraform state list 2>&1
$resourceCount = ($stateResources | Measure-Object -Line).Lines

Write-Host "  Found $resourceCount resources in Terraform state" -ForegroundColor Gray

# Show what will be destroyed
Write-Host "`n📊 Resources that will be destroyed:" -ForegroundColor Yellow
terraform plan -destroy -var-file="envs/dev/terraform.tfvars" -out=destroy.tfplan 2>&1 | Select-String -Pattern "will be destroyed|Plan:" -Context 0,2 | Select-Object -First 10

# Confirm before destroying
Write-Host "`n⚠️  This will destroy all resources in Terraform state!" -ForegroundColor Red
$confirm = Read-Host "   Type 'yes' to continue, or anything else to cancel"

if ($confirm -eq "yes") {
    Write-Host "`n🗑️  Destroying infrastructure..." -ForegroundColor Yellow
    terraform destroy -var-file="envs/dev/terraform.tfvars" -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Terraform destroy completed!" -ForegroundColor Green
        
        # Check for orphaned federated credentials (common issue)
        Write-Host "`n🔍 Checking for orphaned resources in state..." -ForegroundColor Cyan
        $federated = terraform state list 2>&1 | Select-String "federated"
        if ($federated) {
            Write-Host "   ⚠️  Found orphaned federated credentials in state" -ForegroundColor Yellow
            Write-Host "   Cleaning up..." -ForegroundColor Gray
            $federated | ForEach-Object { 
                terraform state rm $_.Line.Trim() 2>&1 | Out-Null
            }
            Write-Host "   ✅ Cleaned up orphaned resources" -ForegroundColor Green
        }
        
        # Check if AKS still exists
        $aksCheck = az aks show --resource-group $resourceGroup --name $clusterName --query "provisioningState" -o tsv 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n⚠️  AKS cluster still exists (it wasn't in Terraform state)" -ForegroundColor Yellow
            Write-Host "   To delete it manually:" -ForegroundColor Cyan
            Write-Host "   az aks delete --resource-group $resourceGroup --name $clusterName --yes" -ForegroundColor White
        }
        else {
            Write-Host "`n✅ All resources destroyed!" -ForegroundColor Green
        }
        
        # Verify Resource Group
        Write-Host "`n🔍 Verifying cleanup..." -ForegroundColor Cyan
        $rgExists = az group show --name $resourceGroup --query "name" -o tsv 2>&1
        if ($LASTEXITCODE -eq 0) {
            $rgResources = az resource list --resource-group $resourceGroup --query "length(@)" -o tsv
            if ($rgResources -gt 0) {
                Write-Host "   ⚠️  Resource Group still contains $rgResources resource(s)" -ForegroundColor Yellow
                Write-Host "   To delete Resource Group:" -ForegroundColor Cyan
                Write-Host "   az group delete --name $resourceGroup --yes --no-wait" -ForegroundColor White
            }
            else {
                Write-Host "   ✅ Resource Group is empty" -ForegroundColor Green
                Write-Host "   To delete Resource Group:" -ForegroundColor Cyan
                Write-Host "   az group delete --name $resourceGroup --yes" -ForegroundColor White
            }
        }
        else {
            Write-Host "   ✅ Resource Group already deleted" -ForegroundColor Green
        }
        
        # Check for CloudShell connection resource groups
        Write-Host "`n🔍 Checking for CloudShell connection resource groups..." -ForegroundColor Cyan
        $cloudShellRGs = az group list --query "[?contains(name, 'RG-CloudShell-PrivateClusterConnection')].name" -o tsv 2>&1
        if ($cloudShellRGs -and $cloudShellRGs.Count -gt 0) {
            Write-Host "   ⚠️  Found CloudShell connection resource groups (temporary RGs from accessing private AKS via Cloud Shell)" -ForegroundColor Yellow
            Write-Host "   These are safe to delete. To clean them up:" -ForegroundColor Cyan
            Write-Host "   .\cleanup-cloudshell-rgs.ps1" -ForegroundColor White
        }
        else {
            Write-Host "   ✅ No CloudShell connection resource groups found" -ForegroundColor Green
        }
        
        # Final state check
        Write-Host "`n📋 Final Terraform State Check..." -ForegroundColor Cyan
        $finalState = terraform state list 2>&1
        $finalCount = ($finalState | Measure-Object -Line).Lines
        if ($finalCount -eq 0) {
            Write-Host "   ✅ Terraform state is clean - ready for next apply!" -ForegroundColor Green
        }
        else {
            Write-Host "   ⚠️  Terraform state still contains $finalCount resource(s)" -ForegroundColor Yellow
            Write-Host "   Review with: terraform state list" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "`n❌ Terraform destroy had errors. Check output above." -ForegroundColor Red
        Write-Host "`n💡 Common fixes:" -ForegroundColor Cyan
        Write-Host "   1. If federated credentials error: terraform state list | Select-String 'federated' | ForEach-Object { terraform state rm `$_.Line }" -ForegroundColor Gray
        Write-Host "   2. If resources still creating: Wait for completion or cancel manually" -ForegroundColor Gray
        Write-Host "   3. See SAFE_DESTROY_GUIDE.md for detailed troubleshooting" -ForegroundColor Gray
    }
}
else {
    Write-Host "`n❌ Destroy cancelled" -ForegroundColor Yellow
}
