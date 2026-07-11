# 🚀 Deployment Guide

This guide provides step-by-step instructions for deploying the portfolio application to production.

## Prerequisites Checklist

- [ ] Azure subscription with appropriate permissions
- [ ] Azure CLI installed and logged in (`az login`)
- [ ] Terraform >= 1.0 installed
- [ ] kubectl installed and configured
- [ ] Docker installed (for local builds)
- [ ] GitHub repository with secrets configured
- [ ] Domain name (optional, for custom domain)

## Quick Start

### 1. Infrastructure Deployment

```bash
# Navigate to Terraform directory
cd infra/terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="envs/dev/terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="envs/dev/terraform.tfvars"
```

**Expected Output:**
- Resource Group created
- Virtual Network (VNet) created with dedicated subnets:
  - AKS subnet (10.0.1.0/24)
  - Private endpoints subnet (10.0.2.0/24)
  - Azure Bastion subnet (10.0.3.0/26) - When `enable_bastion = true`
  - Operations VM subnet (10.0.4.0/24) - When `enable_bastion = true`
- Private DNS Zones created (for ACR & Key Vault)
- Network Security Groups (NSG) created
- Log Analytics Workspace created
- Azure Container Registry (ACR) created with private endpoint
- Azure Key Vault created with private endpoint and RBAC
- Azure Kubernetes Service (AKS) created with:
  - Azure CNI Overlay + Cilium dataplane
  - Private cluster (API server only accessible from VNet)
  - Azure RBAC with Azure AD integration
  - Separate system and workload node pools
- Workload Identity created
- GitHub OIDC App Registration and federated credentials
- Role assignments configured
- **Operations VM (Trusted Execution Zone)** - When `enable_bastion = true`:
  - Azure Bastion host for secure access
  - Operations VM (`aks-operations-vm`) with Managed Identity
  - Phase 1 tools installed (Azure CLI, kubectl, kubelogin, Helm)
  - Azure AD login configured (no SSH keys needed)
  - Role assignments for AKS, ACR, Key Vault access

**Enterprise-Grade Security Features:**
- ✅ Private endpoints for ACR and Key Vault (no public internet access)
- ✅ VNet isolation with dedicated subnets
- ✅ Private DNS Zones for automatic DNS resolution
- ✅ Network Security Groups for network-level controls
- ✅ Public network access disabled for sensitive resources
- ✅ Private AKS cluster (API server not exposed to internet)
- ✅ Azure RBAC (local accounts disabled)
- ✅ **Operations VM with Azure AD Login** - No SSH keys, RBAC-controlled access
- ✅ **Managed Identity** - No passwords or keys for Azure services
- ✅ **Security Hardening** - Automatic updates, root login disabled

**Time Estimate:**
- **Dev environment**: ~15-20 minutes (NAT Gateway disabled, simpler outbound)
  - **With Operations VM**: +2-3 minutes (Phase 1 completes in ~1 minute)
- **Production environment**: ~30-45 minutes (with NAT Gateway, use staged deployment - see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 19)
  - **With Operations VM**: +3-5 minutes (Phase 1 completes in ~1 minute)

### 2. Access Private AKS Cluster

Since your AKS cluster is **private** (`aks_private_cluster_enabled = true`), you need to access it from within the VNet or via Azure Cloud Shell.

#### Option 1: Azure Cloud Shell (Recommended for Quick Access)

**Easiest method** - Azure Cloud Shell can access private endpoints:

1. **Open Azure Cloud Shell:**
   - Navigate to: https://shell.azure.com
   - Or use Azure Portal → Cloud Shell icon (top right)

2. **Get AKS Credentials:**
   ```bash
   # Login to Azure (if needed)
   az login
   
   # Get AKS credentials
   az aks get-credentials \
     --resource-group ola-rg-dev \
     --name ola-aks-dev \
     --overwrite-existing
   
   # Test connection
   kubectl get nodes
   kubectl get namespaces
   ```

3. **Verify Cluster Access:**
   ```bash
   kubectl cluster-info
   kubectl get nodes -o wide
   kubectl get pods -n kube-system
   ```

**Benefits:**
- ✅ No setup required - works immediately
- ✅ Can access private endpoints
- ✅ Pre-installed tools (kubectl, Azure CLI, kubelogin)
- ✅ Perfect for quick operations and testing

#### Option 2: Azure Bastion + Operations VM (Enterprise-Grade)

**✅ Enterprise-Grade Trusted Execution Zone** - Fully deployed and ready!

The Operations VM (`aks-operations-vm`) is an enterprise-grade VM configured with:
- ✅ **Azure AD Login** - No SSH keys needed! RBAC-controlled access
- ✅ **Managed Identity** - Automatic Azure authentication
- ✅ **Pre-installed Tools** - Phase 1 tools ready to use
- ✅ **Security Hardening** - Enterprise production-grade

**Phase 1 Tools Installed (Ready Now):**
- ✅ Azure CLI (authenticated via Managed Identity)
- ✅ kubectl (latest stable)
- ✅ kubelogin (for Azure AD RBAC)
- ✅ Helm 3
- ✅ git, jq, curl, unzip

**Phase 2 Tools (Optional - Install Manually):**
- Docker (for CI/CD builds)
- Terraform (for IaC)
- Node.js (for frontend builds)
- GitHub Actions Runner (if needed)

### Connect to Operations VM

**Step 1: Ensure Azure AD Access is Configured**

Get your Azure AD user Object ID and add it to `terraform.tfvars`:

```bash
# Get your user Object ID
az ad signed-in-user show --query id -o tsv

# Or get a group Object ID
az ad group show --group "Your Group Name" --query id -o tsv
```

Update `infra/terraform/envs/dev/terraform.tfvars`:
```hcl
# Enterprise-Grade: Azure AD Login (No SSH keys!)
vm_admin_login_principal_ids = [
  "your-user-object-id-here"  # Full sudo access
]
# vm_user_login_principal_ids = []  # Regular user access (optional)
```

Apply the changes:
```bash
cd infra/terraform
terraform apply -var-file="envs/dev/terraform.tfvars"
```

**Step 2: Connect via Azure Portal (Recommended)**

1. Go to **Azure Portal** → **Virtual Machines**
2. Find `aks-operations-vm` in resource group `ola-rg-dev`
3. Click **"Connect"** → Select **"Bastion"** tab
4. Click **"Connect"** (authenticates with your Azure AD credentials)
5. You'll be connected via browser-based SSH session

**Step 3: Connect via Azure CLI (Alternative)**

```bash
# Ensure you're logged in
az login

# Connect via SSH (uses Azure AD authentication)
az ssh vm --name aks-operations-vm --resource-group ola-rg-dev
```

**Step 4: Start Using the VM**

Once connected, verify tools and start working:

```bash
# Verify Azure CLI (already authenticated via Managed Identity)
az account show
az aks list --resource-group ola-rg-dev

# Verify installed tools
kubectl version --client
helm version
kubelogin --version
az --version

# Get AKS credentials (uses Managed Identity automatically)
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev --overwrite-existing

# Test kubectl access
kubectl get nodes
kubectl get namespaces
kubectl cluster-info

# Check Azure CLI configuration
cat ~/.azure_cli_config.sh
source ~/.azure_cli_config.sh  # If not already sourced

# Navigate to operations directory
cd ~/operations
ls -la
```

**Common Operations:**

```bash
# AKS Operations
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
kubectl logs <pod-name> -n <namespace>

# Azure Resource Management
az aks show --resource-group ola-rg-dev --name ola-aks-dev
az acr list --resource-group ola-rg-dev
az keyvault list --resource-group ola-rg-dev

# Helm Operations
helm list --all-namespaces
helm repo add <repo-name> <repo-url>
helm install <release-name> <chart>

# Git Operations (if needed)
git clone <repository-url>
cd <repository>
```

**Benefits:**
- ✅ **No SSH Keys** - Azure AD login with RBAC control
- ✅ **No Public IPs** - Fully private, accessed via Bastion
- ✅ **Pre-configured** - Tools ready, Azure CLI authenticated
- ✅ **Managed Identity** - No passwords or keys for Azure services
- ✅ **Enterprise-Grade** - Security hardening, audit logging
- ✅ **Fast Setup** - Phase 1 completes in ~1 minute

**Install Phase 2 Tools (Optional):**

If you need Docker, Terraform, or Node.js, install them manually:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker  # Or logout/login
docker --version

# Install Terraform
TERRAFORM_VERSION="1.6.0"  # Update as needed
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Install Node.js
NODE_VERSION="20"  # Update as needed
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version
```

**Troubleshooting Connection:**

```bash
# If Azure AD login fails, verify your Object ID is correct
az ad signed-in-user show --query id -o tsv

# Check VM status
az vm show --name aks-operations-vm --resource-group ola-rg-dev --query "provisioningState"

# Check Bastion status
az network bastion show --name ola-bastion-dev --resource-group ola-rg-dev --query "provisioningState"

# View VM extension logs (if Phase 1 had issues)
az vm extension show \
  --resource-group ola-rg-dev \
  --vm-name aks-operations-vm \
  --name aks-operations-vm-setup-phase1 \
  --query "instanceView.statuses"
```

### 3. Connect to Operations VM (If Enabled)

If you enabled the Operations VM (`enable_bastion = true`), you can now connect and start using it:

**Quick Start:**

```bash
# 1. Verify VM is running
az vm show --name aks-operations-vm --resource-group ola-rg-dev --query "powerState"

# 2. Connect via Azure Portal:
#    - Go to Virtual Machines → aks-operations-vm → Connect → Bastion → Connect

# 3. Or connect via Azure CLI:
az ssh vm --name aks-operations-vm --resource-group ola-rg-dev

# 4. Once connected, verify tools:
kubectl version --client
helm version
az --version
kubelogin --version

# 5. Get AKS credentials (uses Managed Identity automatically):
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev

# 6. Test access:
kubectl get nodes
kubectl get namespaces
```

**See Section "Option 2: Azure Bastion + Operations VM" below for detailed instructions.**

### 4. Configure Key Vault Secrets

```bash
# Get Key Vault name from Terraform output
cd infra/terraform
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
cd ../..

# Run setup script
chmod +x scripts/setup-keyvault-secrets.sh
./scripts/setup-keyvault-secrets.sh $KEY_VAULT_NAME
```

Or manually:

```bash
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "acr-username" --value "<ACR_USERNAME>"
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "acr-password" --value "<ACR_PASSWORD>"
az keyvault secret set --vault-name <KEY_VAULT_NAME> --name "sonar-token" --value "<SONAR_TOKEN>"
```

### 5. Install Kubernetes Add-ons

**Note:** 
- If you're using **Azure Bastion + Operations VM**, run these commands from the Operations VM (`aks-operations-vm`). The tools are already installed and Azure CLI is authenticated via Managed Identity.
- If using **Azure Cloud Shell**, run from Cloud Shell.

```bash
# Get AKS credentials (if not already done in Step 2)
AKS_NAME=$(cd infra/terraform && terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(cd infra/terraform && terraform output -raw resource_group_name)
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# Install Secret Store CSI Driver
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true

# Verify installation
kubectl get pods -n kube-system | grep csi-secrets-store
```

### 6. Update Kubernetes Manifests

```bash
# Get values from Terraform outputs
cd infra/terraform
WORKLOAD_IDENTITY_CLIENT_ID=$(terraform output -raw workload_identity_client_id)
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
TENANT_ID=$(az account show --query tenantId -o tsv)
cd ../..

# Update serviceaccount.yaml
sed -i "s/WORKLOAD_IDENTITY_CLIENT_ID_PLACEHOLDER/$WORKLOAD_IDENTITY_CLIENT_ID/g" k8s/serviceaccount.yaml

# Update secretproviderclass.yaml
sed -i "s/WORKLOAD_IDENTITY_CLIENT_ID_PLACEHOLDER/$WORKLOAD_IDENTITY_CLIENT_ID/g" k8s/secretproviderclass.yaml
sed -i "s/KEY_VAULT_NAME_PLACEHOLDER/$KEY_VAULT_NAME/g" k8s/secretproviderclass.yaml
sed -i "s/TENANT_ID_PLACEHOLDER/$TENANT_ID/g" k8s/secretproviderclass.yaml
```

### 7. Build and Push Docker Image

```bash
# Get ACR name
cd infra/terraform
ACR_NAME=$(terraform output -raw acr_login_server | cut -d'.' -f1)
cd ../../app

# Login to ACR
az acr login --name $ACR_NAME

# Build image
docker build -t $ACR_NAME.azurecr.io/ola-portfolio-app:latest .

# Push image
docker push $ACR_NAME.azurecr.io/ola-portfolio-app:latest
```

### 8. Deploy to Kubernetes

```bash
# Update deployment with image
cd ../k8s
sed -i "s|IMAGE_PLACEHOLDER|$ACR_NAME.azurecr.io/ola-portfolio-app:latest|g" deployment.yaml

# Apply all manifests
kubectl apply -f serviceaccount.yaml
kubectl apply -f secretproviderclass.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
kubectl apply -f pdb.yaml
kubectl apply -f networkpolicy.yaml

# Wait for rollout
kubectl rollout status deployment/ola-portfolio-app --timeout=5m

# Verify deployment
kubectl get pods -l app=ola-portfolio-app
kubectl get svc ola-portfolio-service
```

### 9. Verify Deployment

```bash
# Check pod status
kubectl get pods -l app=ola-portfolio-app

# Check service
kubectl get svc ola-portfolio-service

# Check HPA
kubectl get hpa

# Check secrets mount
POD_NAME=$(kubectl get pods -l app=ola-portfolio-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- ls -la /mnt/secrets-store

# Get service IP
kubectl get svc ola-portfolio-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Automated Deployment (CI/CD)

The project includes GitHub Actions workflows for automated deployment:

1. **Push to main branch** triggers CI pipeline
2. **CI pipeline** builds and pushes Docker image
3. **CD pipeline** automatically deploys to AKS

Ensure GitHub Secrets are configured (see README.md).

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod for details
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Secrets Not Mounting

```bash
# Check SecretProviderClass
kubectl describe secretproviderclass azure-kv-secrets

# Check CSI driver logs
kubectl logs -n kube-system -l app=secrets-store-csi-driver
```

### Image Pull Errors

```bash
# Verify ACR access
az aks check-acr --name <AKS_NAME> --resource-group <RG_NAME> --acr <ACR_NAME>

# Check image pull secrets
kubectl get secrets
```

## Rollback

If deployment fails:

```bash
# Rollback to previous version
kubectl rollout undo deployment/ola-portfolio-app

# Rollback to specific revision
kubectl rollout undo deployment/ola-portfolio-app --to-revision=2

# Check rollout history
kubectl rollout history deployment/ola-portfolio-app
```

## Cleanup

### Safe Destroy (Recommended)

**Use the safe destroy script for clean, issue-free destruction:**

```powershell
cd infra/terraform
.\safe-destroy.ps1
```

The script automatically:
- ✅ Checks AKS cluster status
- ✅ Handles resources still being created
- ✅ Shows what will be destroyed
- ✅ Cleans up orphaned resources
- ✅ Verifies completion
- ✅ Ensures clean state for next apply

**See [SAFE_DESTROY_GUIDE.md](SAFE_DESTROY_GUIDE.md) for complete guide.**

### Manual Cleanup

```bash
# Delete Kubernetes resources (optional but recommended)
kubectl delete -f k8s/

# Destroy Terraform infrastructure
cd infra/terraform
terraform destroy -var-file="envs/dev/terraform.tfvars"
```

### Cleanup After Manual Portal Deletion

If you deleted resources manually from Azure Portal (e.g., to save costs or fix stuck resources):

```powershell
cd infra/terraform

# Run cleanup script to sync Terraform state
.\cleanup-after-portal-delete.ps1

# Then verify what Terraform thinks still exists
terraform plan -var-file="envs/dev/terraform.tfvars" -destroy
```

**Note:** See [SAFE_DESTROY_GUIDE.md](SAFE_DESTROY_GUIDE.md) for complete cleanup guide and [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 16 for additional troubleshooting.

## Enterprise-Grade Network Architecture

### ✅ Current Configuration (Dev Environment)

This project is configured with **enterprise-grade network security**:

**Network Components:**
- ✅ **VNet automatically created** with dedicated subnets:
  - AKS Subnet (10.0.1.0/24) - AKS cluster nodes
  - Private Endpoints Subnet (10.0.2.0/24) - ACR and Key Vault private endpoints
  - Azure Bastion Subnet (10.0.3.0/26) - Optional, when `enable_bastion = true`
- ✅ **Private endpoints enabled** for ACR and Key Vault
- ✅ **Private DNS Zones** for automatic DNS resolution
- ✅ **Network Security Groups** for network-level controls
- ✅ **Public network access disabled** for sensitive resources
- ✅ **Private AKS cluster** - API server only accessible from VNet

**Outbound Configuration:**
- **Dev**: AKS-managed load balancer egress (`enable_nat_gateway = false`)
  - Simpler, faster bootstrap
  - No NAT Gateway costs
  - Less predictable egress IPs (acceptable for dev)
- **Production**: NAT Gateway with predictable static egress IPs (when `enable_nat_gateway = true`)
  - Use staged deployment (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 19)

**Network Architecture:**
```
VNet (10.0.0.0/16)
├── AKS Subnet (10.0.1.0/24)
│   └── AKS Cluster Nodes
├── Private Endpoints Subnet (10.0.2.0/24)
│   ├── ACR Private Endpoint
│   └── Key Vault Private Endpoint
└── Azure Bastion Subnet (10.0.3.0/26) [Optional]
    └── Azure Bastion Host + Jumpbox VM
```

**Benefits:**
- 🔒 **Zero Trust Security**: All traffic stays within Azure backbone
- 🛡️ **No Internet Exposure**: ACR and Key Vault not accessible from internet
- 📋 **Compliance Ready**: Meets SOC 2, ISO 27001, HIPAA requirements
- ✅ **Automatic DNS**: Private DNS Zones handle DNS resolution
- ✅ **Private Cluster**: AKS API server not exposed to internet

**Configuration (Current in terraform.tfvars):**
```hcl
# Private endpoints enabled by default (enterprise-grade)
enable_acr_private_endpoint = true
enable_keyvault_private_endpoint = true
acr_public_network_access = false
key_vault_public_access = false

# VNet automatically created
enable_private_dns = true
enable_nsg = true

# NAT Gateway (disabled for dev, enable for production)
enable_nat_gateway = false  # Dev: disabled for simpler outbound
# enable_nat_gateway = true  # Production: enabled for predictable egress IPs

# Azure Bastion + Jumpbox (optional, enable for production)
enable_bastion = false  # Set to true for production secure access
```

**Access Methods:**
- ✅ **Azure Cloud Shell** (Recommended for dev) - Quick access, no setup
- ✅ **Azure Bastion + Operations VM** (Enterprise-Grade) - Secure access via Azure Portal with Azure AD login
- ✅ **VPN Connection** - For enterprise connectivity (if configured)

**Operations VM Features:**
- ✅ **Azure AD Login** - No SSH keys, RBAC-controlled access
- ✅ **Managed Identity** - Automatic Azure authentication
- ✅ **Pre-installed Tools** - kubectl, Helm, Azure CLI, kubelogin
- ✅ **Fast Deployment** - Phase 1 completes in ~1 minute
- ✅ **Enterprise Security** - Hardened, audited, private access only

**Note:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 19 for production NAT Gateway setup guide.

#### Configure Azure RBAC for AKS Access

1. **Get your Azure AD group object IDs:**
   ```bash
   # For admin access
   az ad group show --group "YourAdminGroup" --query id -o tsv
   
   # For operator access (read-only)
   az ad group show --group "YourOperatorGroup" --query id -o tsv
   ```

2. **Update `terraform.tfvars`:**
   ```hcl
   admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]  # Your admin group ID
   operator_group_object_ids = ["11111111-1111-1111-1111-111111111111"]  # Your operator group ID
   ```

3. **Apply changes:**
   ```bash
   terraform apply -var-file=envs/dev/terraform.tfvars
   ```

### Additional Next Steps

- [ ] Configure custom domain
- [ ] Set up SSL/TLS certificates
- [ ] Configure monitoring alerts
- [ ] Set up backup strategy
- [ ] Review security policies
- [ ] Document runbooks
- [ ] **For Production**: Enable NAT Gateway (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 19)
- [ ] **Operations VM**: Connect and verify Phase 1 tools are working
- [ ] **Operations VM**: Install Phase 2 tools (Docker, Terraform, Node.js) if needed
- [ ] **Operations VM**: Configure GitHub Actions Runner if needed (requires token)
- [ ] Configure Azure RBAC groups for AKS access (already configured if `admin_group_names` is set)

## Troubleshooting

For common issues and solutions, see the comprehensive [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide with 19 documented solutions including:

- AKS cluster creation timeouts
- Network connectivity issues
- State management problems
- Resource cleanup procedures
- Production NAT Gateway setup

**Quick Help:**
- **AKS timeout errors**: See Section 18 (vmssCSE timeout) and Section 19 (NAT Gateway setup)
- **State lock errors**: `terraform force-unlock <lock-id>`
- **Resources already exist**: Import with `terraform import`
- **Cleanup after manual deletion**: Run `cleanup-after-portal-delete.ps1`
- **Operations VM connection issues**: See "Option 2: Azure Bastion + Operations VM" section above

## Operations VM Quick Reference

### Connect to Operations VM

```bash
# Via Azure Portal (Recommended)
# Virtual Machines → aks-operations-vm → Connect → Bastion → Connect

# Via Azure CLI
az ssh vm --name aks-operations-vm --resource-group ola-rg-dev
```

### Common Operations VM Commands

```bash
# Verify Azure CLI authentication (Managed Identity)
az account show
az aks list --resource-group ola-rg-dev

# Get AKS credentials
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev --overwrite-existing

# Kubernetes Operations
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>

# Helm Operations
helm list --all-namespaces
helm repo add <repo-name> <repo-url>
helm install <release-name> <chart>
helm upgrade <release-name> <chart>

# Azure Resource Management
az aks show --resource-group ola-rg-dev --name ola-aks-dev
az acr list --resource-group ola-rg-dev
az keyvault list --resource-group ola-rg-dev
az keyvault secret show --vault-name <vault-name> --name <secret-name>

# Check installed tools
kubectl version --client
helm version
az --version
kubelogin --version
git --version
jq --version

# View Phase 1 setup logs
cat /var/log/operations-vm-setup-phase1.log

# Navigate to operations directory
cd ~/operations
ls -la
```

### Install Phase 2 Tools (Optional)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker  # Or logout/login
docker --version
docker ps

# Install Terraform
TERRAFORM_VERSION="1.6.0"  # Update as needed
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# Install Node.js
NODE_VERSION="20"  # Update as needed
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version
```

### Troubleshooting Operations VM

```bash
# Check VM status
az vm show --name aks-operations-vm --resource-group ola-rg-dev --query "powerState"

# Check VM extension status
az vm extension show \
  --resource-group ola-rg-dev \
  --vm-name aks-operations-vm \
  --name aks-operations-vm-setup-phase1 \
  --query "instanceView.statuses"

# View extension logs
az vm extension show \
  --resource-group ola-rg-dev \
  --vm-name aks-operations-vm \
  --name aks-operations-vm-setup-phase1 \
  --query "instanceView.substatuses"

# Check Azure AD login configuration
az vm show \
  --name aks-operations-vm \
  --resource-group ola-rg-dev \
  --query "osProfile.linuxConfiguration.ssh"

# Verify Managed Identity
az vm identity show \
  --name aks-operations-vm \
  --resource-group ola-rg-dev

# Test Managed Identity access
curl -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/"
```

