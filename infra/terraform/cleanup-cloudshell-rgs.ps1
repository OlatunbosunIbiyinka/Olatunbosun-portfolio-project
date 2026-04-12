# Cleanup CloudShell PrivateClusterConnection Resource Groups
# These are temporary resource groups created by Azure when accessing private AKS clusters from Cloud Shell

Write-Host "🔍 Finding CloudShell connection resource groups..." -ForegroundColor Cyan

$cloudShellRGs = az group list --query "[?contains(name, 'RG-CloudShell-PrivateClusterConnection')].{Name:name, Location:location}" -o json 2>&1 | ConvertFrom-Json

if ($null -eq $cloudShellRGs -or $cloudShellRGs.Count -eq 0) {
    Write-Host "✅ No CloudShell connection resource groups found" -ForegroundColor Green
    exit 0
}

Write-Host "`nFound $($cloudShellRGs.Count) CloudShell connection resource group(s):" -ForegroundColor Yellow
$cloudShellRGs | ForEach-Object {
    Write-Host "  - $($_.Name) ($($_.Location))" -ForegroundColor Gray
}

Write-Host "`n⚠️  These are temporary resource groups created by Azure Cloud Shell" -ForegroundColor Yellow
Write-Host "   They can be safely deleted." -ForegroundColor Gray

$confirm = Read-Host "`nDelete all CloudShell connection resource groups? (yes/no)"
if ($confirm -eq "yes") {
    foreach ($rg in $cloudShellRGs) {
        Write-Host "`n🗑️  Deleting $($rg.Name)..." -ForegroundColor Yellow
        az group delete --name $rg.Name --yes --no-wait 2>&1 | Out-Null
        Write-Host "   ✅ Deleted" -ForegroundColor Green
    }
    Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Cleanup cancelled" -ForegroundColor Yellow
}
