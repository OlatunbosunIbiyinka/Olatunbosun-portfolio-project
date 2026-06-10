# 🚀 Olatunbosun Portfolio - Production-Grade Cloud Deployment

[![CI - Build and Push](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci-build-push.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci-build-push.yml)
[![CI - Quality](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml)
[![Terraform Validation](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/terraform.yml/badge.svg)](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/terraform.yml)

A **production-grade** React portfolio application deployed on **Azure Kubernetes Service (AKS)** with complete infrastructure-as-code, automated CI/CD pipelines, enterprise security, and comprehensive observability.

---

## 📋 Table of Contents

- [Quick Start Guide](#-quick-start-guide)
- [What's Included](#-whats-included)
- [Architecture Overview](#-architecture-overview)
- [Prerequisites](#-prerequisites)
- [Complete Setup Walkthrough](#-complete-setup-walkthrough)
- [Key Features](#-key-features)
- [Documentation](#-documentation)
- [Troubleshooting](#-troubleshooting)

---

## ⚡ Quick Start Guide

Get your production-grade deployment up and running in **5 simple steps**:

### Step 1: Clone & Configure

```bash
# Clone the repository
git clone https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project.git
cd Olatunbosun-portfolio-project

# Copy and edit Terraform variables
cp infra/terraform/envs/dev/terraform.tfvars.example infra/terraform/envs/dev/terraform.tfvars
# Edit terraform.tfvars with your values
```

### Step 2: Deploy Infrastructure

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="envs/dev/terraform.tfvars" -out=tfplan

# Apply infrastructure (takes ~15-20 minutes for dev, ~30-45 minutes for production)
terraform apply tfplan
```

**Note:** For production environments with NAT Gateway, use **staged deployment** (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 19) to avoid bootstrap timeouts.

### Step 3: Setup GitHub OIDC (Automatically Configured)

GitHub OIDC is **automatically configured** during infrastructure deployment. The Terraform module creates:
- Azure AD Application for GitHub Actions
- Federated Identity Credential for OIDC authentication
- Role assignments for ACR push access

**Verify OIDC Configuration:**
```bash
cd infra/terraform
terraform output github_oidc_client_id
terraform output github_oidc_tenant_id
```

**Note:** GitHub Actions workflows use OIDC automatically - no manual secret configuration needed. See [docs/OIDC_SETUP.md](docs/OIDC_SETUP.md) for details.

### Step 4: Access Private AKS Cluster

Since the AKS cluster is **private** (`aks_private_cluster_enabled = true`), you need to access it from within the VNet:

**Option 1: Azure Cloud Shell (Quick Test)**
```bash
# Open Azure Cloud Shell: https://shell.azure.com
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
kubectl get nodes
```

**Option 2: Azure Bastion + Jumpbox (Production)**
- Enable in `terraform.tfvars`: `enable_bastion = true`
- Connect via Azure Portal → Virtual Machines → Connect → Bastion
- Tools (kubectl, Azure CLI, kubelogin) are pre-installed

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed access instructions.

### Step 5: Configure Key Vault Secrets

```bash
# Get Key Vault name
KEY_VAULT_NAME=$(cd infra/terraform && terraform output -raw key_vault_name)

# Store secrets
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "acr-username" --value "<value>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "acr-password" --value "<value>"
```

### Step 6: Deploy Application

```bash
# Get AKS credentials (from Cloud Shell or Jumpbox)
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev

# Install Secret Store CSI Driver (if not already installed)
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system --set syncSecret.enabled=true

# Deploy application
kubectl apply -f k8s/
```

**🎉 Done!** Your application is now running in production-grade Kubernetes.

---

## 🎯 What's Included

This project provides a **complete production-ready infrastructure** with:

### 🏗️ Infrastructure
- ✅ **Terraform IaC** - Modular, reusable infrastructure code
- ✅ **Azure AKS** - Managed Kubernetes cluster with auto-scaling
  - ✅ **Azure CNI Overlay** - Better IP management and scalability (up to 50,000 pods)
  - ✅ **Cilium Network Policy** - Advanced network policies with eBPF-based security
  - ✅ **Cilium Dataplane** - eBPF-based networking for enhanced performance
  - ✅ **Separate Node Pools** - System pool (CoreDNS, metrics-server) and Workload pool (applications)
  - ✅ **Production-Grade Isolation** - Taints and labels for workload separation
  - ✅ **Private Cluster** - API server only accessible from VNet
  - ✅ **Azure RBAC** - Enterprise-grade access control with Azure AD integration
- ✅ **Azure ACR** - Premium container registry with private endpoints
- ✅ **Azure Key Vault** - Centralized secrets management with private endpoints and RBAC
- ✅ **Virtual Network (VNet)** - Enterprise-grade network isolation with dedicated subnets
- ✅ **Outbound Configuration** - Dynamic based on environment:
  - **Dev**: AKS-managed load balancer egress (simpler, faster bootstrap)
  - **Production**: NAT Gateway with predictable static egress IPs (when enabled)
- ✅ **Private Endpoints** - Zero-trust network security (ACR & Key Vault)
- ✅ **Private DNS Zones** - Automatic DNS resolution for private endpoints
- ✅ **Network Security Groups (NSG)** - Network-level security controls
- ✅ **Log Analytics** - Centralized logging and monitoring with Container Insights

### 🔐 Security
- ✅ **OIDC Authentication** - Passwordless GitHub Actions → Azure
- ✅ **Workload Identity** - Secure pod-level Azure authentication
- ✅ **Key Vault Integration** - Secrets mounted via CSI driver
- ✅ **Cilium Network Policies** - Advanced Layer 7 network policies with default-deny
- ✅ **Azure Policy Add-on** - Admission control guardrails (block :latest, require limits, restrict registries)
- ✅ **Namespace Isolation** - Default-deny with explicit allows for DNS, Ingress, Prometheus, Argo CD
- ✅ **Pod Security Standards** - Enforced security policies
- ✅ **Image Scanning** - Trivy vulnerability scanning
- ✅ **Code Analysis** - SonarCloud integration

### 🚀 CI/CD
- ✅ **Automated Builds** - Docker images on every push
- ✅ **Security Scans** - Automated vulnerability checks
- ✅ **Zero-Downtime Deployments** - Rolling updates with rollback
- ✅ **Health Checks** - Automatic deployment verification

### 📊 Observability
- ✅ **Prometheus & Grafana** - Metrics and dashboards
- ✅ **Cilium Hubble** - Network flow observability and policy verification
- ✅ **Azure Monitor** - Cloud-native monitoring
- ✅ **Log Analytics** - Centralized logging
- ✅ **Alerting** - Email notifications

### ⚡ High Availability
- ✅ **Multi-Replica** - 2+ pod replicas
- ✅ **Auto-Scaling** - Horizontal Pod Autoscaler (HPA)
- ✅ **Pod Disruption Budgets** - Ensures minimum availability
- ✅ **Health Probes** - Liveness and readiness checks

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ CI (Build/   │  │ Security Scan│  │ Argo CD      │     │
│  │ Push to ACR) │  │  (Trivy)     │  │  (GitOps)    │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼─────────────────┼──────────────┘
          │                  │                 │
          ▼                  ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud                              │
│                                                             │
│  ┌──────────────┐      ┌──────────────┐                    │
│  │  Azure ACR   │◄─────┤  Azure AKS   │                    │
│  │  (Registry)  │      │  (Cluster)   │                    │
│  └──────────────┘      └──────┬───────┘                    │
│                               │                            │
│  ┌──────────────┐            │                            │
│  │ Azure Key     │            │                            │
│  │ Vault         │────────────┘                            │
│  │ (Secrets)     │  Workload Identity                      │
│  └──────────────┘                                          │
│                                                             │
│  ┌──────────────┐      ┌──────────────┐                    │
│  │ Log Analytics│      │  Prometheus   │                    │
│  │  Workspace   │      │  & Grafana   │                    │
│  └──────────────┘      └──────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

### Component Flow

1. **Developer** pushes code to GitHub
2. **CI Pipeline** builds Docker image and pushes to ACR via **private endpoint** (using OIDC)
3. **Security Pipeline** scans image for vulnerabilities
4. **Argo CD** syncs manifests from Git and deploys to AKS (in-cluster; CI has no cluster access)
5. **AKS Pods** access ACR via **private endpoint** (no internet exposure)
6. **Pods** authenticate to Key Vault via **private endpoint** using Workload Identity
7. **Secrets** are mounted via Secret Store CSI Driver
8. **Application** runs with enterprise-grade security, network isolation, and monitoring

### Enterprise Network Security

- **VNet Isolation**: All resources within isolated Virtual Network
- **Private Endpoints**: ACR and Key Vault accessible only via private Azure network
- **Private DNS**: Automatic DNS resolution via Azure Private DNS Zones
- **Network Security Groups**: Network-level access controls
- **Zero Public Exposure**: Sensitive resources not accessible from internet

---

## 📦 Prerequisites

Before starting, ensure you have:

| Tool | Version | Purpose |
|------|---------|---------|
| **Azure CLI** | Latest | Azure authentication and management |
| **Terraform** | >= 1.0 | Infrastructure provisioning |
| **kubectl** | Latest | Kubernetes cluster management |
| **Docker** | Latest | Local image building |
| **Helm** | >= 3.0 | Kubernetes package management |

### Azure Requirements

- ✅ Azure subscription with **Contributor** or **Owner** role
- ✅ Azure AD permissions for RBAC configuration
- ✅ Ability to create: Resource Groups, AKS, ACR, Key Vault

### GitHub Requirements

- ✅ GitHub repository
- ✅ GitHub Actions enabled
- ✅ Access to repository settings/secrets

---

## 🚀 Complete Setup Walkthrough

### Phase 1: Infrastructure Setup

#### 1.1 Configure Terraform Variables

Edit `infra/terraform/envs/dev/terraform.tfvars`:

```hcl
# Basic Configuration
resource_group_name = "ola-rg-prod"
location            = "uksouth"
aks_name            = "ola-aks-prod"
acr_name            = "olaacr01prod"  # Must be globally unique
key_vault_name      = "ola-kv-prod"   # Must be globally unique

# GitHub OIDC Configuration (Recommended)
enable_github_oidc = true
github_repository  = "OlatunbosunIbiyinka/Olatunbosun-portfolio-project"
github_branch      = "main"

# Node Pool Configuration
default_node_pool_vm_size   = "Standard_D2s_v3"
default_node_pool_node_count = 2
min_node_count              = 2
max_node_count              = 5

# Security Configuration
enable_azure_policy    = true
disable_local_accounts = true
enable_azure_rbac      = true

# Tags
tags = {
  Environment = "production"
  Project     = "portfolio"
  ManagedBy   = "Terraform"
}
```

#### 1.2 Deploy Infrastructure

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="envs/dev/terraform.tfvars" -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

**What gets created:**
- Resource Group
- Virtual Network (VNet) with subnets
- Log Analytics Workspace
- Azure Container Registry (ACR) with private endpoint
- Azure Key Vault with private endpoint and RBAC
- Azure Kubernetes Service (AKS) with private cluster
- Workload Identity for pod-level authentication
- GitHub OIDC App Registration and federated credentials
- Role assignments for ACR and Key Vault access

**Time Estimate:**
- **Dev environment**: ~15-20 minutes (NAT Gateway disabled, simpler outbound)
- **Production environment**: ~30-45 minutes (with NAT Gateway, use staged deployment)

#### 1.3 Access Private AKS Cluster

Since the cluster is private, access it via:

**Option 1: Azure Cloud Shell (Quick Test)**
```bash
# Open: https://shell.azure.com
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
kubectl get nodes
```

**Option 2: Azure Bastion + Jumpbox (Production)**
- Enable in `terraform.tfvars`: `enable_bastion = true`
- Connect via Azure Portal → Virtual Machines → Connect → Bastion
- Tools are pre-installed on jumpbox

---

### Phase 2: GitHub OIDC Setup (Recommended)

OIDC eliminates the need to store service principal credentials in GitHub.

#### 2.1 Get OIDC Configuration

```bash
cd infra/terraform

# Get OIDC values
terraform output github_oidc_client_id
terraform output github_oidc_tenant_id
terraform output github_oidc_subscription_id
```

#### 2.2 Configure GitHub Secrets

Go to: `https://github.com/<owner>/<repo>/settings/secrets/actions`

Add these secrets:

| Secret Name | Value Source |
|------------|--------------|
| `AZURE_CLIENT_ID` | `terraform output github_oidc_client_id` |
| `AZURE_TENANT_ID` | `terraform output github_oidc_tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | `terraform output github_oidc_subscription_id` |

**Or use the automated script:**

```bash
./scripts/setup-github-oidc.sh OlatunbosunIbiyinka/Olatunbosun-portfolio-project ola-rg-prod
```

📖 **Detailed Guide**: See [OIDC Setup Documentation](docs/OIDC_SETUP.md)

---

### Phase 3: Key Vault Configuration

#### 3.1 Store Secrets in Key Vault

```bash
# Get Key Vault name
KEY_VAULT_NAME=$(cd infra/terraform && terraform output -raw key_vault_name)

# Store secrets
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "acr-username" --value "<value>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "acr-password" --value "<value>"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "sonar-token" --value "<value>"
```

**Or use the automated script:**

```bash
./scripts/setup-keyvault-secrets.sh <key-vault-name>
```

#### 3.2 Get Workload Identity Details

```bash
cd infra/terraform

# Get values needed for Kubernetes manifests
WORKLOAD_IDENTITY_CLIENT_ID=$(terraform output -raw workload_identity_client_id)
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
TENANT_ID=$(az account show --query tenantId -o tsv)
```

#### 3.3 Update Kubernetes Manifests

Update `k8s/serviceaccount.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workload-identity-sa
  namespace: default
  annotations:
    azure.workload.identity/client-id: "<WORKLOAD_IDENTITY_CLIENT_ID>"
```

Update `k8s/secretproviderclass.yaml`:

```yaml
spec:
  parameters:
    clientID: "<WORKLOAD_IDENTITY_CLIENT_ID>"
    keyvaultName: "<KEY_VAULT_NAME>"
    tenantId: "<TENANT_ID>"
```

---

### Phase 4: Kubernetes Add-ons

#### 4.1 Install Secret Store CSI Driver

```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true

# Verify installation
kubectl get pods -n kube-system | grep csi-secrets-store
```

#### 4.2 Verify Workload Identity (if not already enabled)

```bash
az aks show --name ola-aks-prod --resource-group ola-rg-prod \
  --query oidcIssuerProfile.enabled

# If false, enable it:
az aks update --name ola-aks-prod --resource-group ola-rg-prod \
  --enable-oidc-issuer --enable-workload-identity
```

#### 4.3 Install NGINX Ingress (Optional)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

---

### Phase 5: Application Deployment

#### 5.1 Build and Push Docker Image

```bash
cd app

# Get ACR name
ACR_NAME=$(cd ../infra/terraform && terraform output -raw acr_login_server | cut -d'.' -f1)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push
docker build -t $ACR_NAME.azurecr.io/ola-portfolio-app:latest .
docker push $ACR_NAME.azurecr.io/ola-portfolio-app:latest
```

#### 5.2 Deploy to Kubernetes

```bash
# Update deployment with your image
sed -i "s|IMAGE_PLACEHOLDER|$ACR_NAME.azurecr.io/ola-portfolio-app:latest|g" k8s/deployment.yaml

# Apply all manifests
kubectl apply -f k8s/serviceaccount.yaml
kubectl apply -f k8s/secretproviderclass.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
kubectl apply -f k8s/networkpolicy.yaml

# Or apply all at once
kubectl apply -f k8s/
```

#### 5.3 Verify Deployment

```bash
# Check pod status
kubectl get pods -l app=ola-portfolio-app

# Check service
kubectl get svc ola-portfolio-service

# Check HPA
kubectl get hpa

# Verify secrets are mounted
POD_NAME=$(kubectl get pods -l app=ola-portfolio-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -- ls -la /mnt/secrets-store

# Get service IP
kubectl get svc ola-portfolio-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## ✨ Key Features

### 🔐 Security Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **OIDC Authentication** | Passwordless GitHub Actions → Azure | No secrets to manage |
| **Workload Identity** | Pod-level Azure authentication | Secure service access |
| **Key Vault** | Centralized secrets management with RBAC | No secrets in code/images |
| **Cilium Network Policies** | Advanced Layer 7 network policies | Network isolation with eBPF |
| **Azure RBAC** | Enterprise-grade access control | Azure AD integration |
| **Private Cluster** | API server only accessible from VNet | Zero public exposure |
| **Private Endpoints** | ACR and Key Vault via private network | No internet exposure |
| **Azure Policy** | Admission control guardrails | Compliance ready |
| **Image Scanning** | Trivy vulnerability scanning | Security assurance |
| **Code Analysis** | SonarCloud integration | Code quality |

### ⚡ High Availability Features

| Feature | Description |
|---------|-------------|
| **Multi-Replica** | 2+ pod replicas for redundancy |
| **Auto-Scaling** | HPA scales based on CPU/memory |
| **Pod Disruption Budgets** | Ensures minimum availability during updates |
| **Health Probes** | Automatic pod health monitoring |
| **Rolling Updates** | Zero-downtime deployments |

### 📊 Observability Features

| Feature | Description |
|---------|-------------|
| **Prometheus** | Metrics collection |
| **Grafana** | Dashboards and visualization |
| **Azure Monitor** | Cloud-native monitoring |
| **Log Analytics** | Centralized logging |
| **Alerting** | Email notifications |

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Deployment Guide](DEPLOYMENT.md) | Detailed deployment instructions |
| [Troubleshooting Guide](TROUBLESHOOTING.md) | Common errors and solutions (19 sections) |
| [Project Pitch Script](PROJECT_PITCH_SCRIPT.md) | **Complete project explanation & recruiter pitch** - Word-for-word script for interviews |
| [Safe Destroy Guide](SAFE_DESTROY_GUIDE.md) | Step-by-step guide for safely destroying infrastructure |
| [CloudShell Resource Groups Explained](CLOUDSHELL_RESOURCE_GROUP_EXPLAINED.md) | **Why you see temporary RGs** - Understanding CloudShell connection resources |
| [Enterprise Grade Summary](ENTERPRISE_GRADE_SUMMARY.md) | Overview of enterprise security features |
| [GitOps Architecture](GITOPS_ARCHITECTURE.md) | Complete GitOps deployment architecture |
| [Operations VM Setup](VM_SETUP_FIX.md) | Operations VM (Trusted Execution Zone) documentation |
| [OIDC Setup Guide](docs/OIDC_SETUP.md) | Complete OIDC authentication setup |
| [Azure AD Group Setup](AZURE_AD_GROUP_SETUP.md) | Setting up Azure AD groups for VM administration |
| [Quick Reference](QUICK_REFERENCE.md) | Common commands and operations |
| [Production Checklist](PRODUCTION_CHECKLIST.md) | Pre-deployment verification |

---

## 🔧 Troubleshooting

### Quick Fixes

**AKS Cluster Creation Timeout:**
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 18: "AKS VMExtensionProvisioningError on vmssCSE"
- Dev environment uses simplified outbound (NAT Gateway disabled) to avoid bootstrap timeouts
- Production: Use staged deployment when enabling NAT Gateway (Section 19)

**State Lock Errors:**
```bash
terraform force-unlock <lock-id>
```

**Resources Already Exist:**
```bash
# Import existing resource into state
terraform import -var-file="envs/dev/terraform.tfvars" <resource_address> <azure_resource_id>
```

**Cleanup After Manual Deletion:**
```bash
cd infra/terraform
.\cleanup-after-portal-delete.ps1
```

### Common Issues

#### Pods Not Starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

#### Secrets Not Mounting
```bash
kubectl describe secretproviderclass azure-kv-secrets
kubectl logs -n kube-system -l app=secrets-store-csi-driver
```

#### Cannot Connect to Private AKS Cluster
- Use Azure Cloud Shell or Azure Bastion + Jumpbox
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 11

📖 **Complete Troubleshooting Guide**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) with 19 documented solutions

---

## 🎓 Learning Resources

- [Azure Kubernetes Service Docs](https://docs.microsoft.com/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**Olatunbosun Ibiyinka**

- 🔗 [LinkedIn](https://linkedin.com/in/yourprofile)
- 🐙 [GitHub](https://github.com/OlatunbosunIbiyinka)
- 📧 [Email](mailto:your.email@example.com)

---

## 🙏 Acknowledgments

- Azure Kubernetes Service team
- Terraform Azure provider maintainers
- Kubernetes community
- Open source contributors

---

## ⚠️ Important Notes

- **Production Ready**: This setup is production-grade. Test in a development environment first.
- **Costs**: Monitor Azure costs. Use appropriate VM sizes for your needs.
- **Security**: Review all security configurations before production deployment.
- **Backups**: Implement backup strategies for critical data.

---

**⭐ If you find this project helpful, please give it a star!**

---

*Last updated: February 2026 | Production-Grade Azure Kubernetes Deployment*

---

## 🛠️ Infrastructure Configuration

### Current Configuration (Dev Environment)

**Network:**
- ✅ Azure CNI Overlay with Cilium dataplane
- ✅ Private AKS cluster (API server only accessible from VNet)
- ✅ Private endpoints for ACR and Key Vault
- ✅ NAT Gateway **disabled** for dev (simplified outbound via load balancer)
- ✅ Private DNS Zones for automatic DNS resolution

**Security:**
- ✅ Azure RBAC with Azure AD group integration
- ✅ Workload Identity for pod-level authentication
- ✅ GitHub OIDC for passwordless CI/CD
- ✅ Local accounts disabled (Azure AD only)

**For Production:**
- Enable NAT Gateway: `enable_nat_gateway = true` in `envs/prod/terraform.tfvars`
- Use staged deployment (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) Section 19)
- Enable Azure Bastion: `enable_bastion = true` for secure access

### Helper Scripts

Located in `infra/terraform/`:
- `cleanup-after-portal-delete.ps1` - Clean up Terraform state after manual resource deletion
- `handle-aks-timeout.ps1` - Check AKS cluster status and recover from timeouts
- `enterprise-deploy.ps1` - Staged deployment script for production
