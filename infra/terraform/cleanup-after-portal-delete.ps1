# Cleanup Terraform State After Manual Portal Deletion
# This script removes AKS and related resources from Terraform state after manual deletion from Azure Portal
# Usage: .\cleanup-after-portal-delete.ps1

param(
    [string]$ResourceGroup = "ola-rg-dev",
    [string]$ClusterName = "ola-aks-dev"
)

Write-Host "🧹 Cleaning Up Terraform State After Portal Deletion..." -ForegroundColor Cyan
Write-Host ""

# Change to Terraform directory
$terraformDir = $PSScriptRoot
if (-not (Test-Path "$terraformDir\main.tf")) {
    Write-Host "❌ Error: main.tf not found. Are you in the terraform directory?" -ForegroundColor Red
    exit 1
}

Set-Location $terraformDir

# Step 1: Verify resources are deleted in Azure
Write-Host "📋 Step 1: Verifying resources are deleted in Azure..." -ForegroundColor Yellow

$clusterExists = az aks show --resource-group $ResourceGroup --name $ClusterName --query "name" -o tsv 2>&1
if ($LASTEXITCODE -eq 0 -and $clusterExists) {
    Write-Host "⚠️  WARNING: AKS cluster '$ClusterName' still exists in Azure!" -ForegroundColor Red
    Write-Host "   Please delete it from Azure Portal first, then run this script again." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✅ AKS cluster is deleted (or doesn't exist)" -ForegroundColor Green
}

$mcRgExists = az group show --name "MC_${ResourceGroup}_${ClusterName}_uksouth" --query "name" -o tsv 2>&1
if ($LASTEXITCODE -eq 0 -and $mcRgExists) {
    Write-Host "⚠️  WARNING: Managed cluster resource group 'MC_${ResourceGroup}_${ClusterName}_uksouth' still exists!" -ForegroundColor Yellow
    Write-Host "   This should be automatically deleted when the cluster is deleted." -ForegroundColor Gray
    Write-Host "   You may need to delete it manually from Portal if it's stuck." -ForegroundColor Gray
} else {
    Write-Host "✅ Managed cluster resource group is deleted (or doesn't exist)" -ForegroundColor Green
}

Write-Host ""

# Step 2: List AKS-related resources in Terraform state
Write-Host "📋 Step 2: Finding AKS-related resources in Terraform state..." -ForegroundColor Yellow

$allResources = terraform state list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Terraform state not initialized. Running init..." -ForegroundColor Yellow
    terraform init
    $allResources = terraform state list 2>&1
}

# Find AKS-related resources
$aksResources = $allResources | Where-Object { 
    $_ -match "module\.aks" -or 
    $_ -match "azurerm_kubernetes_cluster" -or
    $_ -match "azurerm_role_assignment.*aks" -or
    $_ -match "azurerm_federated_identity_credential.*workload_identity" -or
    $_ -match "azurerm_user_assigned_identity.*workload_identity"
}

if ($aksResources) {
    Write-Host "`nFound AKS-related resources in state:" -ForegroundColor Cyan
    $aksResources | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
} else {
    Write-Host "✅ No AKS-related resources found in state" -ForegroundColor Green
}

Write-Host ""

# Step 3: Remove AKS resources from state
if ($aksResources) {
    Write-Host "🗑️  Step 3: Removing AKS resources from Terraform state..." -ForegroundColor Yellow
    
    $removedCount = 0
    $failedCount = 0
    
    foreach ($resource in $aksResources) {
        Write-Host "  Removing: $resource" -ForegroundColor Gray
        terraform state rm $resource 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            $removedCount++
        } else {
            Write-Host "    ⚠️  Failed to remove (may already be removed)" -ForegroundColor Yellow
            $failedCount++
        }
    }
    
    Write-Host ""
    Write-Host "✅ Removed $removedCount resource(s) from state" -ForegroundColor Green
    if ($failedCount -gt 0) {
        Write-Host "⚠️  $failedCount resource(s) failed to remove (may already be gone)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⏭️  Step 3: Skipped (no AKS resources to remove)" -ForegroundColor Gray
}

Write-Host ""

# Step 4: Check for GitHub OIDC resources (may have been deleted)
Write-Host "📋 Step 4: Checking GitHub OIDC resources..." -ForegroundColor Yellow

$githubResources = $allResources | Where-Object { $_ -match "module\.github_oidc" }
if ($githubResources) {
    Write-Host "Found GitHub OIDC resources:" -ForegroundColor Cyan
    $githubResources | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    
    # Check if Azure AD app still exists
    $appId = terraform state show ($githubResources | Select-Object -First 1) 2>&1 | Select-String "application_id" | ForEach-Object { ($_ -split "=")[1].Trim() }
    
    if ($appId) {
        $appExists = az ad app show --id $appId --query "appId" -o tsv 2>&1
        if ($LASTEXITCODE -ne 0 -or -not $appExists) {
            Write-Host "⚠️  GitHub OIDC Azure AD app doesn't exist in Azure. Removing from state..." -ForegroundColor Yellow
            $githubResources | ForEach-Object {
                Write-Host "  Removing: $_" -ForegroundColor Gray
                terraform state rm $_ 2>&1 | Out-Null
            }
        }
    }
} else {
    Write-Host "✅ No GitHub OIDC resources in state" -ForegroundColor Green
}

Write-Host ""

# Step 5: Verify state is clean
Write-Host "📋 Step 5: Verifying state cleanup..." -ForegroundColor Yellow

$remainingAks = terraform state list 2>&1 | Where-Object { $_ -match "module\.aks" }
if ($remainingAks) {
    Write-Host "⚠️  Some AKS resources may still be in state:" -ForegroundColor Yellow
    $remainingAks | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
} else {
    Write-Host "✅ AKS resources removed from state" -ForegroundColor Green
}

Write-Host ""

# Step 6: Summary and next steps
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Terraform state cleaned up" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Verify all resources are deleted in Azure Portal" -ForegroundColor White
Write-Host "  2. Run: terraform plan -var-file=`"envs/dev/terraform.tfvars`" -destroy" -ForegroundColor White
Write-Host "     (This will show what Terraform thinks still needs to be destroyed)" -ForegroundColor Gray
Write-Host "  3. If plan shows resources that are already deleted, remove them from state:" -ForegroundColor White
Write-Host "     terraform state rm <resource_address>" -ForegroundColor Gray
Write-Host "  4. Once plan shows no changes, you're ready for a fresh deployment:" -ForegroundColor White
Write-Host "     terraform apply -var-file=`"envs/dev/terraform.tfvars`"" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Cleanup complete!" -ForegroundColor Green
