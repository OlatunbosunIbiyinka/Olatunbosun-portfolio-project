# 🛠️ Enterprise-Grade VM Setup Fix

## Problem
The original VM setup script installed all tools in a single extension, causing:
- **Timeout errors** (60+ minutes)
- **dpkg lock conflicts**
- **Single point of failure** (one tool failure breaks everything)
- **Difficult troubleshooting** (hard to identify which tool failed)

## Solution: Two-Phase Installation

### ✅ **Phase 1: Critical Tools** (Fast & Essential)
- **Duration**: ~5-10 minutes
- **Tools**: Azure CLI, kubectl, kubelogin, Helm, git, jq
- **Status**: **Always installed** - Required for basic VM operations
- **Failure handling**: Fails fast with clear error messages

### ⚙️ **Phase 2: Optional Tools** (Can be Skipped)
- **Duration**: ~20-45 minutes (if all enabled)
- **Tools**: Docker, Terraform, Node.js, GitHub Actions Runner
- **Status**: **Optional** - Can be installed later if needed
- **Failure handling**: Continues on errors (warnings logged, non-critical)

## Benefits

1. **Fast VM Deployment**: Phase 1 completes in < 10 minutes
2. **Resilient**: Phase 2 failures don't break Phase 1
3. **Flexible**: Install optional tools later or skip entirely
4. **Enterprise-Grade**: Production-ready with proper error handling
5. **No Timeouts**: Phase 1 is fast enough to avoid timeout issues

## Configuration

### Option 1: Install All Tools (Default)
```hcl
# In terraform.tfvars
jumpbox_install_docker        = true
jumpbox_install_terraform     = true
jumpbox_install_nodejs        = true
jumpbox_install_github_runner = true
```

### Option 2: Skip Optional Tools (Fastest Deployment)
```hcl
# In terraform.tfvars - Install only critical tools
jumpbox_install_docker        = false
jumpbox_install_terraform     = false
jumpbox_install_nodejs        = false
jumpbox_install_github_runner = false
```

### Option 3: Selective Installation
```hcl
# In terraform.tfvars - Install only what you need
jumpbox_install_docker        = true   # For CI/CD builds
jumpbox_install_terraform     = false  # Install manually later
jumpbox_install_nodejs        = false  # Not needed
jumpbox_install_github_runner = true   # For self-hosted runners
```

## Migration from Old Setup

If you have an existing VM with the old single-phase setup:

### Step 1: Delete Old Extension
```bash
az vm extension delete \
  --resource-group ola-rg-dev \
  --vm-name aks-operations-vm \
  --name aks-operations-vm-setup
```

### Step 2: Apply New Configuration
```bash
cd infra/terraform
terraform plan -var-file="envs/dev/terraform.tfvars"
terraform apply -var-file="envs/dev/terraform.tfvars"
```

The new configuration will:
- Install Phase 1 (critical tools) - **Required**
- Install Phase 2 (optional tools) - **Based on your configuration**

## Installing Optional Tools Later

If you skipped Phase 2 tools, you can install them later:

### Via Azure Portal
1. Go to VM → Extensions → Add
2. Select "Custom Script for Linux"
3. Use the Phase 2 script from `modules/bastion-jumpbox/main.tf`

### Via Azure CLI
```bash
# Example: Install Docker only
az vm extension set \
  --resource-group ola-rg-dev \
  --vm-name aks-operations-vm \
  --name install-docker \
  --publisher Microsoft.Azure.Extensions \
  --type CustomScript \
  --type-handler-version 2.1 \
  --settings '{"script":"<base64-encoded-script>"}'
```

### Via SSH (Manual Installation)
```bash
# Connect via Azure Bastion or Azure AD login
az ssh vm --name aks-operations-vm --resource-group ola-rg-dev

# Then install tools manually
# Example: Install Docker
curl -fsSL https://get.docker.com | sudo sh
```

## Troubleshooting

### Phase 1 Failed
- Check logs: `/var/log/operations-vm-setup-phase1.log`
- Critical tools are required - fix errors before proceeding

### Phase 2 Failed/Warnings
- Check logs: `/var/log/operations-vm-setup-phase2.log`
- Warnings are expected for optional tools
- VM is still functional - Phase 1 tools are installed
- Install failed tools manually if needed

### Extension Still Shows "Failed"
- Azure Portal may show old status
- Check actual VM logs: `/var/log/operations-vm-setup-phase*.log`
- Verify tools are installed:
  ```bash
  az vm run-command invoke \
    --resource-group ola-rg-dev \
    --name aks-operations-vm \
    --command-id RunShellScript \
    --scripts "which az kubectl kubelogin helm"
  ```

## Best Practices

1. **Production**: Set all Phase 2 tools to `false` initially, install later if needed
2. **Development**: Enable Phase 2 tools you actually use
3. **CI/CD**: Enable Docker and GitHub Runner if using self-hosted runners
4. **Monitoring**: Check Phase 2 logs even if it shows "Failed" - warnings are normal

## Architecture

```
┌─────────────────────────────────────────┐
│  VM Extension: Phase 1 (Critical)     │
│  ├─ Azure CLI                          │
│  ├─ kubectl                            │
│  ├─ kubelogin                          │
│  ├─ Helm                               │
│  └─ git, jq, curl                      │
│  Duration: ~5-10 minutes               │
│  Status: Always Required               │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  VM Extension: Phase 2 (Optional)      │
│  ├─ Docker (if enabled)                │
│  ├─ Terraform (if enabled)             │
│  ├─ Node.js (if enabled)               │
│  └─ GitHub Runner (if enabled)         │
│  Duration: ~20-45 minutes               │
│  Status: Optional, can skip             │
└─────────────────────────────────────────┘
```

## Summary

✅ **Problem Solved**: No more timeout errors  
✅ **Fast Deployment**: Phase 1 completes in < 10 minutes  
✅ **Resilient**: Phase 2 failures don't break Phase 1  
✅ **Flexible**: Install optional tools later or skip  
✅ **Enterprise-Grade**: Production-ready with proper error handling  
