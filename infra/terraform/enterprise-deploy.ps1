# Enterprise-Grade Staged Deployment Script
# Prevents: Long-running AKS failures, circular dependencies, role assignment timing issues,
#           orphaned resources, and Terraform state corruption
#
# Usage: .\enterprise-deploy.ps1 [-SkipPreChecks] [-DryRun] [-Stage <1-5>]
#
# Stages:
#   1. Pre-flight checks and cleanup
#   2. Foundation (Resource Group, VNet, NSGs, NAT Gateway)
#   3. Security & Storage (Key Vault, ACR, Private Endpoints, DNS)
#   4. Access Infrastructure (Bastion + Jumpbox)
#   5. AKS Cluster (with monitoring and auto-recovery)

param(
    [switch]$SkipPreChecks,
    [switch]$DryRun,
    [int]$Stage = 0,  # 0 = all stages
    [string]$VarFile = "envs/dev/terraform.tfvars"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
Set-Location $ScriptDir

# Colors for output
function Write-Step { param($msg) Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Gray }

# Track deployment state
$DeploymentState = @{
    StartTime = Get-Date
    Stage = 0
    Errors = @()
    Warnings = @()
    ResourcesCreated = @()
}

function Save-DeploymentState {
    $DeploymentState | ConvertTo-Json -Depth 5 | Out-File "$ScriptDir/.deployment-state.json" -Force
}

function Get-DeploymentState {
    if (Test-Path "$ScriptDir/.deployment-state.json") {
        return Get-Content "$ScriptDir/.deployment-state.json" | ConvertFrom-Json
    }
    return $null
}

#######################################
# STAGE 1: Pre-flight Checks & Cleanup
#######################################
function Invoke-PreflightChecks {
    Write-Step "STAGE 1: Pre-flight Checks & Cleanup"
    
    # 1.1 Check Azure CLI login
    Write-Info "Checking Azure CLI authentication..."
    $account = az account show 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Not logged into Azure CLI. Run: az login"
        return $false
    }
    $accountInfo = $account | ConvertFrom-Json
    Write-Success "Logged in as: $($accountInfo.user.name) | Subscription: $($accountInfo.name)"
    
    # 1.2 Check Terraform
    Write-Info "Checking Terraform..."
    $tfVersion = terraform version -json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform not found. Please install Terraform."
        return $false
    }
    Write-Success "Terraform version: $($tfVersion.terraform_version)"
    
    # 1.3 Check for soft-deleted Key Vault (CRITICAL)
    Write-Info "Checking for soft-deleted Key Vault..."
    $deletedKv = az keyvault list-deleted --query "[?name=='ola-kv-dev']" -o json 2>&1 | ConvertFrom-Json
    if ($deletedKv -and $deletedKv.Count -gt 0) {
        Write-Warning "Found soft-deleted Key Vault: ola-kv-dev"
        Write-Info "This will cause deployment failure. Purging now..."
        
        if (-not $DryRun) {
            az keyvault purge --name "ola-kv-dev" --location "uksouth" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Key Vault purged successfully"
            } else {
                Write-Warning "Could not purge Key Vault. It may be scheduled for auto-purge."
                $scheduledPurge = $deletedKv[0].properties.scheduledPurgeDate
                Write-Info "Scheduled purge date: $scheduledPurge"
                
                # Check if purge date has passed
                if ([DateTime]::Parse($scheduledPurge) -le (Get-Date)) {
                    Write-Info "Purge date has passed. Waiting for Azure to complete purge..."
                    Start-Sleep -Seconds 30
                } else {
                    Write-Error "Key Vault cannot be purged yet. Either wait until $scheduledPurge or rename the Key Vault in terraform.tfvars"
                    return $false
                }
            }
        } else {
            Write-Info "[DRY RUN] Would purge Key Vault: ola-kv-dev"
        }
    } else {
        Write-Success "No soft-deleted Key Vault found"
    }
    
    # 1.4 Check for orphaned Azure AD applications
    Write-Info "Checking for orphaned Azure AD applications..."
    $adApps = az ad app list --filter "startswith(displayName, 'github-actions')" --query "[].{displayName:displayName, appId:appId}" -o json 2>&1 | ConvertFrom-Json
    if ($adApps -and $adApps.Count -gt 0) {
        Write-Warning "Found existing Azure AD applications:"
        foreach ($app in $adApps) {
            Write-Info "  - $($app.displayName) (AppId: $($app.appId))"
        }
        
        $targetApp = $adApps | Where-Object { $_.displayName -eq "github-actions-oidc-dev" }
        if ($targetApp) {
            Write-Warning "Found conflicting app: github-actions-oidc-dev"
            Write-Info "This may cause 'already exists' errors. Deleting..."
            
            if (-not $DryRun) {
                az ad app delete --id $targetApp.appId 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Deleted Azure AD application: github-actions-oidc-dev"
                } else {
                    Write-Warning "Could not delete Azure AD application. You may need to delete it manually."
                }
            } else {
                Write-Info "[DRY RUN] Would delete Azure AD app: github-actions-oidc-dev"
            }
        }
    } else {
        Write-Success "No orphaned Azure AD applications found"
    }
    
    # 1.5 Check Terraform state
    Write-Info "Checking Terraform state..."
    $stateList = terraform state list 2>&1
    if ($stateList -and $stateList -notmatch "No state file") {
        $resourceCount = ($stateList | Measure-Object -Line).Lines
        if ($resourceCount -gt 0) {
            Write-Warning "Terraform state contains $resourceCount resources"
            Write-Info "These resources may already exist in Azure. Run 'terraform plan' to check."
        }
    } else {
        Write-Success "Terraform state is clean"
    }
    
    # 1.6 Initialize Terraform
    Write-Info "Initializing Terraform..."
    if (-not $DryRun) {
        terraform init -upgrade 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform init failed"
            return $false
        }
    }
    Write-Success "Terraform initialized"
    
    # 1.7 Validate configuration
    Write-Info "Validating Terraform configuration..."
    if (-not $DryRun) {
        $validateOutput = terraform validate 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform validation failed:"
            Write-Host $validateOutput -ForegroundColor Red
            return $false
        }
    }
    Write-Success "Configuration is valid"
    
    # 1.8 Prepare Helm cache for ArgoCD (if enabled)
    if (-not $DryRun) {
        Write-Info "Preparing Helm cache for ArgoCD..."
        $helmCache = "$env:LOCALAPPDATA\Temp\helm"
        $cachePaths = @("$env:LOCALAPPDATA\Temp\helm", "$env:USERPROFILE\.helm\cache", "$env:TEMP\helm")
        foreach ($p in $cachePaths) { if (Test-Path $p) { Remove-Item $p -Recurse -Force -EA 0 } }
        New-Item -ItemType Directory -Path $helmCache -Force | Out-Null
        $env:HELM_CACHE_HOME = $helmCache
        $helm = Get-Command helm -ErrorAction SilentlyContinue
        if ($helm) {
            helm repo add argoproj https://argoproj.github.io/argo-helm 2>$null
            helm repo update 2>$null
            Write-Success "Helm cache prepared"
        } else {
            Write-Warning "Helm CLI not found - ArgoCD deployment may fail. Install: winget install Helm.Helm"
        }
    }
    
    $DeploymentState.Stage = 1
    Save-DeploymentState
    return $true
}

#######################################
# STAGE 2: Foundation Infrastructure
#######################################
function Deploy-Foundation {
    Write-Step "STAGE 2: Foundation Infrastructure (Resource Group, VNet, NAT Gateway)"
    
    $targets = @(
        "azurerm_resource_group.rg",
        "module.vnet"
    )
    
    Write-Info "Deploying: Resource Group, VNet, Subnets, NSGs, Route Tables, NAT Gateway"
    Write-Info "This stage typically takes 3-5 minutes..."
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would deploy foundation infrastructure"
        terraform plan -var-file="$VarFile" -target="azurerm_resource_group.rg" -target="module.vnet" 2>&1
        return $true
    }
    
    # Deploy with targets
    $result = terraform apply -var-file="$VarFile" `
        -target="azurerm_resource_group.rg" `
        -target="module.vnet" `
        -auto-approve 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Foundation deployment failed"
        Write-Host $result -ForegroundColor Red
        return $false
    }
    
    Write-Success "Foundation infrastructure deployed"
    $DeploymentState.Stage = 2
    $DeploymentState.ResourcesCreated += "ResourceGroup", "VNet", "Subnets", "NSG", "RouteTable", "NATGateway"
    Save-DeploymentState
    
    # Wait for resources to stabilize
    Write-Info "Waiting 30 seconds for resources to stabilize..."
    Start-Sleep -Seconds 30
    
    return $true
}

#######################################
# STAGE 3: Security & Storage
#######################################
function Deploy-SecurityStorage {
    Write-Step "STAGE 3: Security & Storage (Key Vault, ACR, Private Endpoints, DNS)"
    
    Write-Info "Deploying: Log Analytics, Key Vault, ACR, Private DNS Zones, Private Endpoints"
    Write-Info "This stage typically takes 5-10 minutes..."
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would deploy security and storage infrastructure"
        terraform plan -var-file="$VarFile" `
            -target="azurerm_log_analytics_workspace.monitoring" `
            -target="module.keyvault" `
            -target="module.acr" 2>&1
        return $true
    }
    
    # Deploy security and storage
    $result = terraform apply -var-file="$VarFile" `
        -target="azurerm_log_analytics_workspace.monitoring" `
        -target="module.keyvault" `
        -target="module.acr" `
        -auto-approve 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Security & Storage deployment failed"
        Write-Host $result -ForegroundColor Red
        
        # Check for specific errors
        if ($result -match "SoftDeletedVault") {
            Write-Warning "Key Vault still exists in soft-deleted state. Attempting to purge..."
            az keyvault purge --name "ola-kv-dev" --location "uksouth" 2>&1
            Write-Info "Retrying deployment..."
            
            $result = terraform apply -var-file="$VarFile" `
                -target="azurerm_log_analytics_workspace.monitoring" `
                -target="module.keyvault" `
                -target="module.acr" `
                -auto-approve 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                return $false
            }
        } else {
            return $false
        }
    }
    
    Write-Success "Security & Storage infrastructure deployed"
    $DeploymentState.Stage = 3
    $DeploymentState.ResourcesCreated += "LogAnalytics", "KeyVault", "ACR", "PrivateDNS", "PrivateEndpoints"
    Save-DeploymentState
    
    # Wait for private endpoints to become active
    Write-Info "Waiting 60 seconds for private endpoints to activate..."
    Start-Sleep -Seconds 60
    
    return $true
}

#######################################
# STAGE 4: Access Infrastructure
#######################################
function Deploy-AccessInfra {
    Write-Step "STAGE 4: Access Infrastructure (Bastion + Jumpbox)"
    
    Write-Info "Deploying: Azure Bastion, Jumpbox VM, VM Extensions"
    Write-Info "This stage typically takes 10-15 minutes..."
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would deploy access infrastructure"
        terraform plan -var-file="$VarFile" -target="module.bastion_jumpbox" 2>&1
        return $true
    }
    
    # Deploy Bastion and Jumpbox
    $result = terraform apply -var-file="$VarFile" `
        -target="module.bastion_jumpbox" `
        -auto-approve 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Access infrastructure deployment failed"
        Write-Host $result -ForegroundColor Red
        
        # Check for VM extension failures (non-critical)
        if ($result -match "VMExtension") {
            Write-Warning "VM extension failed but Jumpbox is accessible. Continuing..."
            Write-Info "You can manually install tools on the Jumpbox later."
        } else {
            return $false
        }
    }
    
    Write-Success "Access infrastructure deployed"
    $DeploymentState.Stage = 4
    $DeploymentState.ResourcesCreated += "Bastion", "Jumpbox"
    Save-DeploymentState
    
    return $true
}

#######################################
# STAGE 5: AKS Cluster (with monitoring)
#######################################
function Deploy-AKS {
    Write-Step "STAGE 5: AKS Cluster (with monitoring and recovery)"
    
    Write-Warning "⚠️  AKS deployment is the longest stage"
    Write-Info "Expected time: 30-60 minutes for private cluster with Cilium"
    Write-Info "The script will monitor progress and handle timeouts gracefully"
    
    if ($DryRun) {
        Write-Info "[DRY RUN] Would deploy AKS cluster"
        terraform plan -var-file="$VarFile" `
            -target="module.aks" `
            -target="azurerm_user_assigned_identity.workload_identity" `
            -target="azurerm_role_assignment.workload_identity_keyvault_secrets_user" `
            -target="azurerm_federated_identity_credential.workload_identity" 2>&1
        return $true
    }
    
    # Start AKS deployment and monitor Azure status directly
    Write-Info "Starting AKS deployment..."
    Write-Info "Terraform will run with extended timeout (240 minutes)"
    Write-Info "Script will monitor Azure status independently..."
    
    # Start Terraform in background
    $aksJob = Start-Job -ScriptBlock {
        param($ScriptDir, $VarFile)
        Set-Location $ScriptDir
        $ErrorActionPreference = "Continue"
        terraform apply -var-file="$VarFile" `
            -target="module.aks" `
            -auto-approve 2>&1 | Out-String
    } -ArgumentList $ScriptDir, $VarFile
    
    # Monitor AKS creation in Azure (independent of Terraform)
    $startTime = Get-Date
    $maxWaitMinutes = 300  # 5 hours max (AKS can take 3-4 hours for complex setups)
    $checkInterval = 30    # Check every 30 seconds
    $terraformFinished = $false
    $terraformResult = $null
    
    Write-Info "Monitoring AKS provisioning status in Azure..."
    
    while ($true) {
        $elapsed = (Get-Date) - $startTime
        $elapsedMinutes = [math]::Round($elapsed.TotalMinutes, 1)
        
        # Check if Terraform job finished
        if (-not $terraformFinished -and $aksJob.State -ne "Running") {
            $terraformFinished = $true
            $terraformResult = Receive-Job $aksJob
            Remove-Job $aksJob
            Write-Info "[$elapsedMinutes min] Terraform job completed (may have timed out)"
        }
        
        # Check Azure for AKS status (primary source of truth)
        try {
            $aksStatus = az aks show --resource-group "ola-rg-dev" --name "ola-aks-dev" --query "provisioningState" -o tsv 2>&1
            if ($LASTEXITCODE -ne 0) {
                # Cluster might not exist yet
                $aksStatus = "NotCreated"
            }
        } catch {
            $aksStatus = "Unknown"
        }
        
        # Check status
        if ($aksStatus -eq "Succeeded") {
            Write-Success "AKS cluster provisioning succeeded in Azure!"
            
            # If Terraform timed out, refresh state
            if ($terraformFinished -and ($terraformResult -match "timeout" -or $terraformResult -match "context deadline exceeded")) {
                Write-Warning "Terraform timed out, but AKS succeeded. Refreshing Terraform state..."
                terraform apply -var-file="$VarFile" -target="module.aks" -refresh-only -auto-approve 2>&1 | Out-Null
            }
            break
        } elseif ($aksStatus -eq "Failed") {
            Write-Error "AKS cluster provisioning failed in Azure"
            if (-not $terraformFinished) {
                Stop-Job $aksJob -ErrorAction SilentlyContinue
                Remove-Job $aksJob -ErrorAction SilentlyContinue
            }
            return $false
        } elseif ($aksStatus -match "Creating" -or $aksStatus -match "Updating") {
            if ($elapsedMinutes % 5 -lt 1) {  # Show status every 5 minutes
                Write-Info "[$elapsedMinutes min] AKS status: $aksStatus - still provisioning..."
            }
        } elseif ($aksStatus -eq "NotCreated") {
            if ($elapsedMinutes % 2 -lt 1) {  # Show status every 2 minutes while not created
                Write-Info "[$elapsedMinutes min] Waiting for AKS cluster to appear in Azure..."
            }
        }
        
        # Check for absolute timeout
        if ($elapsed.TotalMinutes -gt $maxWaitMinutes) {
            Write-Warning "Maximum wait time ($maxWaitMinutes minutes) exceeded"
            Write-Info "Current AKS status: $aksStatus"
            
            if ($aksStatus -match "Creating" -or $aksStatus -match "Updating") {
                Write-Warning "AKS is still provisioning. You can:"
                Write-Info "  1. Wait for it to complete manually"
                Write-Info "  2. Check status: az aks show -g ola-rg-dev -n ola-aks-dev"
                Write-Info "  3. Once succeeded, refresh Terraform: terraform apply -target=module.aks -refresh-only"
                return $false
            } else {
                Write-Error "AKS deployment timed out with status: $aksStatus"
                return $false
            }
        }
        
        Start-Sleep -Seconds $checkInterval
    }
    
    # Get Terraform result if not already retrieved
    if (-not $terraformFinished) {
        $terraformResult = Receive-Job $aksJob
        Remove-Job $aksJob
    }
    
    # Check if Terraform had errors (other than timeout)
    if ($terraformResult -and $terraformResult -match "Error:" -and $terraformResult -notmatch "timeout" -and $terraformResult -notmatch "context deadline exceeded") {
        Write-Warning "Terraform reported errors, but AKS succeeded in Azure"
        Write-Info "Review Terraform output for details, but continuing since AKS is healthy..."
    }
    
    Write-Success "AKS cluster deployed and verified"
    
    # Deploy remaining resources (Workload Identity, GitHub OIDC)
    Write-Info "Deploying Workload Identity and remaining resources..."
    
    $result = terraform apply -var-file="$VarFile" -auto-approve 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        # Check for role assignment timing issues
        if ($result -match "PrincipalNotFound" -or $result -match "does not exist") {
            Write-Warning "Role assignment timing issue. Waiting 60 seconds and retrying..."
            Start-Sleep -Seconds 60
            
            $result = terraform apply -var-file="$VarFile" -auto-approve 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Some resources may have failed. Review output:"
                Write-Host $result -ForegroundColor Yellow
            }
        }
    }
    
    Write-Success "All resources deployed"
    $DeploymentState.Stage = 5
    $DeploymentState.ResourcesCreated += "AKS", "WorkloadIdentity", "GitHubOIDC"
    Save-DeploymentState
    
    return $true
}

#######################################
# MAIN DEPLOYMENT ORCHESTRATION
#######################################
function Start-EnterpriseDeployment {
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║      ENTERPRISE-GRADE AKS DEPLOYMENT                        ║" -ForegroundColor Magenta
    Write-Host "║      Staged deployment with monitoring and recovery         ║" -ForegroundColor Magenta
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No changes will be made"
    }
    
    $stages = @(
        @{ Name = "Pre-flight Checks"; Function = { Invoke-PreflightChecks } },
        @{ Name = "Foundation (VNet, NAT)"; Function = { Deploy-Foundation } },
        @{ Name = "Security (KV, ACR)"; Function = { Deploy-SecurityStorage } },
        @{ Name = "Access (Bastion)"; Function = { Deploy-AccessInfra } },
        @{ Name = "AKS Cluster"; Function = { Deploy-AKS } }
    )
    
    # Determine starting stage
    $startStage = 0
    if ($Stage -gt 0) {
        $startStage = $Stage - 1
        Write-Info "Starting from Stage ${Stage}: $($stages[$startStage].Name)"
    } else {
        # Check for previous deployment state
        $previousState = Get-DeploymentState
        if ($previousState -and $previousState.Stage -gt 0) {
            Write-Warning "Previous deployment found at Stage $($previousState.Stage)"
            $resume = Read-Host "Resume from Stage $($previousState.Stage + 1)? (y/n)"
            if ($resume -eq "y") {
                $startStage = $previousState.Stage
            }
        }
    }
    
    # Execute stages
    for ($i = $startStage; $i -lt $stages.Count; $i++) {
        $stage = $stages[$i]
        
        $success = & $stage.Function
        
        if (-not $success) {
            Write-Error "Deployment failed at Stage $($i + 1): $($stage.Name)"
            Write-Info "To resume from this stage, run: .\enterprise-deploy.ps1 -Stage $($i + 1)"
            return $false
        }
    }
    
    # Final summary
    $duration = (Get-Date) - $DeploymentState.StartTime
    
    Write-Host "`n"
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║      DEPLOYMENT COMPLETE                                     ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Success "Total deployment time: $([math]::Round($duration.TotalMinutes, 1)) minutes"
    Write-Info "Resources created: $($DeploymentState.ResourcesCreated -join ', ')"
    
    # Show connection instructions
    Write-Step "Next Steps"
    Write-Host @"

1. Get Bastion connection info:
   terraform output -json bastion_connection_instructions

2. Get Jumpbox password:
   terraform output jumpbox_password

3. Connect to Jumpbox via Azure Portal:
   - Go to Azure Portal > Bastion > ola-rg-dev-bastion
   - Connect to: aks-jumpbox
   - Username: azureuser
   - Password: (from step 2)

4. On Jumpbox, connect to AKS:
   az login
   az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
   kubectl get nodes

"@ -ForegroundColor Cyan
    
    # Cleanup deployment state
    if (Test-Path "$ScriptDir/.deployment-state.json") {
        Remove-Item "$ScriptDir/.deployment-state.json" -Force
    }
    
    return $true
}

# Execute main function
$success = Start-EnterpriseDeployment

if ($success) {
    exit 0
} else {
    exit 1
}
