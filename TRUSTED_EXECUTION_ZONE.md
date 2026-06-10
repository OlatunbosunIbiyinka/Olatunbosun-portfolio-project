# 🛡️ Trusted Execution Zone - Enterprise-Grade Operations VM

## Overview

Your infrastructure now includes a **Trusted Execution Zone** VM that serves as:

1. **Operations Box** - Day-to-day cluster management and administration
2. **kubectl Box** - Secure access to your private AKS cluster
3. **CI/CD Execution Engine** - Runs GitHub Actions, builds Docker images, deploys applications

## ✅ Enterprise-Grade Features

### Security
- ✅ **Azure AD Login** - Enterprise-grade authentication, no SSH keys needed
- ✅ **RBAC-Controlled Access** - Access via Azure RBAC roles (Virtual Machine User/Admin Login)
- ✅ **Managed Identity** - No passwords or keys stored on VM for Azure services
- ✅ **Role-Based Access Control** - Least privilege permissions
- ✅ **Disk Encryption** - OS disk encrypted at rest
- ✅ **Network Isolation** - Only accessible via Azure Bastion
- ✅ **Security Hardening** - Automatic security updates, root login disabled
- ✅ **Audit Logging** - All operations logged

### Pre-Installed Tools
- ✅ **kubectl, kubelogin, Helm** - Kubernetes operations
- ✅ **Azure CLI** - Authenticated via Managed Identity
- ✅ **Docker** - For CI/CD image builds
- ✅ **GitHub Actions Runner** - Self-hosted CI/CD execution
- ✅ **Terraform** - Infrastructure as Code
- ✅ **Node.js** - For frontend builds
- ✅ **Git, jq, and utilities** - Development tools

### Role Assignments
The VM's Managed Identity has been granted:
- **AKS Cluster Admin Role** - Full kubectl access
- **ACR Contributor** - Push/pull container images
- **Key Vault Secrets User** - Access secrets for CI/CD
- **Resource Group Contributor** - Manage resources

## 🚀 Quick Start

### 1. Enable in Terraform

Add to `infra/terraform/envs/dev/terraform.tfvars`:

```hcl
# Trusted Execution Zone (Operations VM)
enable_bastion = true
bastion_subnet_address_prefixes = ["10.0.3.0/26"]
jumpbox_subnet_address_prefixes = ["10.0.4.0/24"]
jumpbox_vm_size = "Standard_D2s_v3"  # Sufficient for operations and CI/CD

# Enterprise-Grade: Azure AD Login (No SSH keys needed!)
# Access is controlled via Azure RBAC roles
# Get your Azure AD user/group Object IDs and add them:
vm_admin_login_principal_ids = [
  # "00000000-0000-0000-0000-000000000000"  # Your Azure AD user/group Object ID (full sudo access)
]
vm_user_login_principal_ids = [
  # "00000000-0000-0000-0000-000000000000"  # Your Azure AD user/group Object ID (regular user access)
]

# Optional: GitHub Actions Runner
github_repository_url = "https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project"
# github_runner_token = "..."  # Get from GitHub repo settings
```

### 2. Apply Terraform

```powershell
cd infra/terraform
terraform apply -var-file="envs/dev/terraform.tfvars"
```

### 3. Grant Azure AD Access

Get your Azure AD user Object ID:
```powershell
az ad signed-in-user show --query id -o tsv
```

Add it to `terraform.tfvars` and apply:
```hcl
vm_admin_login_principal_ids = ["your-object-id-here"]
```

### 4. Connect via Azure AD Login

**Method 1: Azure Portal (Recommended)**
1. Go to **Azure Portal** → **Virtual Machines** → `aks-operations-vm`
2. Click **"Connect"** → **"Bastion"** tab
3. Authenticate with your Azure AD credentials
4. Click **"Connect"**

**Method 2: Azure CLI**
```powershell
az ssh vm --name aks-operations-vm --resource-group ola-rg-dev
```

### 4. Use the Trusted Execution Zone

Once connected, the VM is ready to use:

```bash
# Azure CLI is already authenticated via Managed Identity
az account show
az aks list

# Get AKS credentials
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
kubectl get nodes

# Docker is ready
docker ps
docker build -t myapp:latest .

# GitHub Actions Runner (if configured)
sudo systemctl status actions.runner.*.service

# Terraform
terraform version
```

## 🔐 Security Architecture

### Managed Identity Authentication

The VM uses **User-Assigned Managed Identity** for all Azure operations:

```bash
# No need to run 'az login' - already authenticated!
az account show
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
```

### Network Security

- **No Public IP** - VM is completely private
- **Azure Bastion Only** - Access via secure Bastion connection
- **NSG Rules** - Only SSH from Bastion subnet allowed
- **VNet Integration** - Can resolve private DNS zones

### Access Control

- **SSH Key Authentication** - Recommended (no passwords)
- **Role-Based Permissions** - Managed Identity has specific roles
- **Audit Trail** - All operations logged to Log Analytics

## 🏗️ CI/CD Integration

### GitHub Actions Runner

If configured, the VM runs a self-hosted GitHub Actions runner:

```yaml
# .github/workflows/ci-build-push.yml (build/push only; Argo CD deploys)
name: Deploy to AKS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: self-hosted  # Uses the Trusted Execution Zone VM
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and push image
        run: |
          az acr login --name olaacr01dev
          docker build -t olaacr01dev.azurecr.io/app:${{ github.sha }} .
          docker push olaacr01dev.azurecr.io/app:${{ github.sha }}
      
      - name: Deploy to AKS
        run: |
          az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
          kubectl set image deployment/app app=olaacr01dev.azurecr.io/app:${{ github.sha }}
```

### Benefits

- ✅ **No GitHub Secrets Required** - Uses Managed Identity
- ✅ **Private Network Access** - Can access private AKS, ACR, Key Vault
- ✅ **Persistent Runner** - Always available, no cold starts
- ✅ **Secure** - Runs in your VNet, not on GitHub's infrastructure

## 📊 Monitoring

### Log Analytics Integration

If `log_analytics_workspace_id` is provided:
- Azure Monitor Agent installed automatically
- System logs sent to Log Analytics
- Query logs: `KubePodInventory | where Namespace == "default"`

### Boot Diagnostics

- Boot logs stored in managed storage account
- Access via Azure Portal → VM → Boot diagnostics

## 🔧 Maintenance

### Update Tools

```bash
# Update kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Update Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Security Updates

Automatic security updates are enabled:
- `patch_mode = "AutomaticByPlatform"`
- Updates applied during maintenance windows

## 🎯 Use Cases

### 1. Operations & Administration

```bash
# Cluster management
kubectl get nodes
kubectl get pods -A
kubectl describe node <node-name>

# Resource management
az aks show --resource-group ola-rg-dev --name ola-aks-dev
az acr repository list --name olaacr01dev
```

### 2. CI/CD Pipeline Execution

```bash
# Build and push images
docker build -t olaacr01dev.azurecr.io/app:v1.0.0 .
az acr login --name olaacr01dev
docker push olaacr01dev.azurecr.io/app:v1.0.0

# Deploy to AKS
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
kubectl apply -f k8s/
```

### 3. Troubleshooting

```bash
# Debug cluster issues
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'

# Network diagnostics
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
```

## 📝 Best Practices

1. **Always use SSH keys** - Never use passwords in production
2. **Rotate SSH keys regularly** - Update `jumpbox_ssh_public_key` in Terraform
3. **Monitor access** - Review Log Analytics for suspicious activity
4. **Keep tools updated** - Regularly update kubectl, Docker, etc.
5. **Use Managed Identity** - Never store Azure credentials on the VM
6. **Limit access** - Only grant access to authorized personnel

## 🔗 Related Documentation

- [Cluster Operations Guide](CLUSTER_OPERATIONS.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Troubleshooting](TROUBLESHOOTING.md)

---

**✅ This configuration is enterprise-grade and production-ready!**

The Trusted Execution Zone provides:
- ✅ Secure, isolated environment
- ✅ No credential management overhead
- ✅ Full CI/CD capabilities
- ✅ Complete audit trail
- ✅ Zero-trust network model
