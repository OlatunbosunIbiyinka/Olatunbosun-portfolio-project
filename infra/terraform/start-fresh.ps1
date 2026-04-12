# Start Fresh Script - Cleans up Terraform state after manual resource deletion
# Usage: .\start-fresh.ps1

Write-Host "🧹 Starting Fresh Terraform Setup..." -ForegroundColor Cyan
Write-Host "This script will clean up Terraform state after manual resource deletion." -ForegroundColor Yellow
Write-Host ""

# Step 1: Check current state
Write-Host "📋 Step 1: Checking current Terraform state..." -ForegroundColor Yellow
Set-Location $PSScriptRoot

$resources = terraform state list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Terraform state not initialized. Running init..." -ForegroundColor Yellow
    terraform init
    $resources = terraform state list 2>&1
}

Write-Host "Found resources in state:" -ForegroundColor Gray
$resources | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

# Step 2: Remove all resources from state (except data sources)
Write-Host "`n🗑️  Step 2: Removing resources from state (keeping data sources)..." -ForegroundColor Yellow
$resourcesToRemove = $resources | Where-Object { $_ -notmatch "^data\." -and $_ -ne "" -and $_ -notmatch "Error" }
if ($resourcesToRemove) {
    $removedCount = 0
    $resourcesToRemove | ForEach-Object {
        Write-Host "  Removing: $_" -ForegroundColor Gray
        terraform state rm $_ 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $removedCount++
        }
    }
    Write-Host "✅ Removed $removedCount resources from state" -ForegroundColor Green
} else {
    Write-Host "✅ State is already clean (only data sources remain)" -ForegroundColor Green
}

# Step 3: Clean up Azure AD resources
Write-Host "`n🔍 Step 3: Checking for Azure AD resources..." -ForegroundColor Yellow
$adApps = az ad app list --query "[?contains(displayName, 'ola-aks-dev')].{displayName:displayName, appId:appId}" -o json 2>&1 | ConvertFrom-Json
if ($adApps -and $adApps.Count -gt 0) {
    Write-Host "⚠️  Found Azure AD applications that may need cleanup:" -ForegroundColor Yellow
    $adApps | ForEach-Object { 
        Write-Host "    - $($_.displayName) (App ID: $($_.appId))" -ForegroundColor Gray 
    }
    Write-Host "`n  To delete these applications, run:" -ForegroundColor Cyan
    Write-Host "    az ad app list --filter \"displayName eq 'github-actions-ola-aks-dev'\" --query \"[].id\" -o tsv | ForEach-Object { az ad app delete --id `$_ }" -ForegroundColor White
} else {
    Write-Host "✅ No Azure AD applications found (or already cleaned up)" -ForegroundColor Green
}

# Step 4: Re-initialize
Write-Host "`n🔄 Step 4: Re-initializing Terraform..." -ForegroundColor Yellow
terraform init -upgrade
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Terraform initialized successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
    exit 1
}

# Step 5: Validate
Write-Host "`n✔️  Step 5: Validating configuration..." -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Configuration is valid" -ForegroundColor Green
} else {
    Write-Host "❌ Configuration validation failed" -ForegroundColor Red
    Write-Host "Please fix configuration errors before proceeding" -ForegroundColor Yellow
    exit 1
}

# Step 6: Show final state
Write-Host "`n📊 Final state check..." -ForegroundColor Yellow
$finalState = terraform state list 2>&1
Write-Host "Resources remaining in state:" -ForegroundColor Gray
$finalState | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

# Step 7: Instructions
Write-Host "`n✅ Fresh start complete!" -ForegroundColor Green
Write-Host "`n📝 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review your configuration:" -ForegroundColor White
Write-Host "     cat envs/dev/terraform.tfvars" -ForegroundColor Gray
Write-Host "`n  2. Create a plan to see what will be created:" -ForegroundColor White
Write-Host "     terraform plan -var-file=\"envs/dev/terraform.tfvars\"" -ForegroundColor Gray
Write-Host "`n  3. Apply the infrastructure:" -ForegroundColor White
Write-Host "     terraform apply -var-file=\"envs/dev/terraform.tfvars\"" -ForegroundColor Gray
Write-Host "`n💡 Tip: Review the plan carefully before applying to avoid unexpected costs!" -ForegroundColor Yellow
