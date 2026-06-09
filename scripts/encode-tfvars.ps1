# Encode terraform.tfvars to base64 for safe transfer to the ops VM (avoids Bastion paste corruption).
# Usage (from repo root, PowerShell):
#   .\scripts\encode-tfvars.ps1
#   .\scripts\encode-tfvars.ps1 -ToClipboard
#   .\scripts\encode-tfvars.ps1 -InputPath infra\terraform\envs\dev\terraform.tfvars -OutputPath tfvars.b64.txt

param(
    [string]$InputPath = "infra\terraform\envs\dev\terraform.tfvars",
    [string]$OutputPath = "infra\terraform\envs\dev\terraform.tfvars.b64",
    [switch]$ToClipboard
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$inputFile = Join-Path $repoRoot $InputPath
$outputFile = Join-Path $repoRoot $OutputPath

if (-not (Test-Path $inputFile)) {
    Write-Error "Input not found: $inputFile"
}

$bytes = [IO.File]::ReadAllBytes($inputFile)
$b64 = [Convert]::ToBase64String($bytes)

$outDir = Split-Path -Parent $outputFile
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

Set-Content -Path $outputFile -Value $b64 -Encoding Ascii -NoNewline

Write-Host "Encoded: $inputFile"
Write-Host "Output:  $outputFile"
Write-Host "Size:    $($b64.Length) chars (base64)"

if ($ToClipboard) {
    Set-Clipboard -Value $b64
    Write-Host "Copied base64 to clipboard."
}

Write-Host ""
Write-Host "On the VM:"
Write-Host "  nano ~/terraform.tfvars.b64    # paste, save"
Write-Host "  ./scripts/decode-tfvars.sh ~/terraform.tfvars.b64"
Write-Host ""
Write-Host "Note: base64 is not encryption. Do not commit .b64 files or share publicly."
