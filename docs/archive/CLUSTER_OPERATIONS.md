# 🚀 AKS Cluster Operations Guide

Complete guide for operating your private AKS cluster with Azure RBAC.

## 📋 Prerequisites

### 1. Install Required Tools

**Windows (PowerShell):**
```powershell
# Install kubectl
winget install Kubernetes.kubectl

# Install kubelogin (REQUIRED for Azure RBAC)
winget install Microsoft.Azure.Kubelogin

# Verify installations
kubectl version --client
kubelogin --version
az --version
```

**Why kubelogin?**
- Your cluster uses Azure AD RBAC (`azure_rbac_enabled = true`)
- kubelogin is required to authenticate with Azure AD
- Without it, `kubectl` commands will fail

### 2. Azure CLI Login

```powershell
# Login to Azure
az login

# Set subscription (if needed)
az account set --subscription "cd258f56-ee0f-45e2-976a-a78ae7e93d8c"

# Verify login
az account show
```

## 🔌 Connecting to Your Cluster

Your cluster is **private** (`aks_private_cluster_enabled = true`) with a **system-managed private DNS zone**. This means the API server DNS only resolves from within the VNet.

### ⚡ Quick Solution: Azure Portal "Connect" Feature

**Easiest method - works immediately, no setup required:**

1. Go to **Azure Portal** → **Kubernetes services** → `ola-aks-dev`
2. Click the **"Connect"** button in the top menu
3. Select **"Azure Cloud Shell"** tab
4. Run kubectl commands directly in the portal terminal

✅ **This works even though Cloud Shell can't resolve the DNS** - Azure Portal handles the connection internally.

---

### Other Connection Options

If you need command-line access, you have these options:

### Option 1: Azure Cloud Shell (Easiest - Recommended)

**Best for:** Quick operations, testing, learning

1. **Open Azure Cloud Shell:**
   - Go to: https://shell.azure.com
   - Or click Cloud Shell icon in Azure Portal (top right)

2. **Get Cluster Credentials:**
   ```bash
   az aks get-credentials \
     --resource-group ola-rg-dev \
     --name ola-aks-dev \
     --overwrite-existing
   ```

3. **Test Connection:**
   ```bash
   kubectl get nodes
   kubectl get namespaces
   ```

**Benefits:**
- ✅ No local setup required
- ✅ All tools pre-installed (kubectl, kubelogin, Azure CLI)
- ✅ Can access private endpoints
- ✅ Works immediately

### Option 2: Local Machine (If Authorized)

**⚠️ IMPORTANT: Private Cluster Limitation**

Your cluster is **private** (`aks_private_cluster_enabled = true`), which means:
- ❌ **Cannot access from local machine directly** (no network connectivity to private endpoint)
- ✅ **Must use Azure Cloud Shell** or **Azure Bastion + Jumpbox**
- ✅ The private endpoint DNS only resolves within the VNet

**If you see this error:**
```
dial tcp: lookup ola-aks-dev-dns-*.privatelink.uksouth.azmk8s.io: no such host
```

**This means:** Your local machine cannot resolve the private endpoint DNS name. This is **expected behavior** for private clusters.

**Solutions:**
1. **Use Azure Cloud Shell** (recommended - see Option 1 above)
2. **Use Azure Bastion + Jumpbox** (see Option 3 below)
3. **Set up VPN/ExpressRoute** to connect to the VNet (advanced)

**For Local Development (If VPN Available):**

If you have VPN access to the VNet:

```powershell
# Get cluster credentials
az aks get-credentials `
  --resource-group ola-rg-dev `
  --name ola-aks-dev `
  --overwrite-existing

# Test connection
kubectl get nodes
```

**Note:** If you get "kubelogin not found" error, install it first (see Prerequisites).

### Option 3: Azure Bastion + Jumpbox (Production)

**Best for:** Production environments, secure access

1. **Connect via Azure Portal:**
   - Go to **Virtual Machines** → `aks-jumpbox`
   - Click **"Connect"** → **"Bastion"** tab
   - Enter username: `azureuser`
   - Enter password: (get from Terraform output)

2. **Get Jumpbox Password:**
   ```powershell
   cd infra/terraform
   terraform output jumpbox_password
   ```

3. **On Jumpbox, connect to cluster:**
   ```bash
   # Tools are pre-installed
   az login
   az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
   kubectl get nodes
   ```

## 🎯 Basic Cluster Operations

### Check Cluster Status

```bash
# Get cluster info
kubectl cluster-info

# List all nodes
kubectl get nodes
kubectl get nodes -o wide

# Check node labels (system vs workload pools)
kubectl get nodes --show-labels

# Describe a node
kubectl describe node <node-name>
```

### View Resources

```bash
# List all namespaces
kubectl get namespaces

# List pods in default namespace
kubectl get pods

# List pods in all namespaces
kubectl get pods -A

# List pods with labels
kubectl get pods -l app=ola-portfolio-app

# List services
kubectl get svc
kubectl get svc -A

# List deployments
kubectl get deployments
kubectl get deployments -A

# List all resources
kubectl get all
kubectl get all -A
```

### View System Components

```bash
# System pods (CoreDNS, metrics-server, etc.)
kubectl get pods -n kube-system

# Cilium network components
kubectl get pods -n kube-system | grep cilium

# CSI Secrets Store driver (for Key Vault integration)
kubectl get pods -n kube-system | grep csi-secrets-store

# Check node pools
kubectl get nodes -l node.kubernetes.io/role=system    # System pool
kubectl get nodes -l node.kubernetes.io/role=workload  # Workload pool
```

## 📦 Application Operations

### Deploy Applications

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Apply from directory
kubectl apply -f k8s/

# Create namespace
kubectl create namespace portfolio-app
```

### Monitor Applications

```bash
# Watch pods
kubectl get pods -w

# Get pod details
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs

# View logs from all pods with label
kubectl logs -l app=ola-portfolio-app

# View events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n default --sort-by='.lastTimestamp'
```

### Scale Applications

```bash
# Manual scaling
kubectl scale deployment ola-portfolio-app --replicas=3

# Check HPA (Horizontal Pod Autoscaler)
kubectl get hpa
kubectl describe hpa ola-portfolio-app-hpa

# Check current resource usage
kubectl top nodes
kubectl top pods
```

### Update Applications

```bash
# Update deployment image
kubectl set image deployment/ola-portfolio-app \
  ola-portfolio-app=olaacr01dev.azurecr.io/ola-portfolio-app:v1.0.0

# Monitor rollout
kubectl rollout status deployment/ola-portfolio-app

# View rollout history
kubectl rollout history deployment/ola-portfolio-app

# Rollback to previous version
kubectl rollout undo deployment/ola-portfolio-app

# Rollback to specific revision
kubectl rollout undo deployment/ola-portfolio-app --to-revision=2
```

## 🔐 Secrets & Key Vault Operations

### View Secrets

```bash
# List secrets
kubectl get secrets
kubectl get secrets -A

# Describe secret
kubectl describe secret <secret-name>

# Check SecretProviderClass (Key Vault integration)
kubectl get secretproviderclass
kubectl describe secretproviderclass azure-kv-secrets

# Check ServiceAccount (Workload Identity)
kubectl get serviceaccount
kubectl describe serviceaccount workload-identity-sa
```

### Update Key Vault Secrets

```bash
# Update secret in Key Vault
az keyvault secret set \
  --vault-name ola-kv-dev \
  --name "acr-username" \
  --value "new-value"

# Restart pods to pick up new secrets
kubectl rollout restart deployment/ola-portfolio-app

# Verify secrets are mounted
kubectl exec -it <pod-name> -- ls -la /mnt/secrets-store
```

## 🌐 Network Operations

### Network Policies (Cilium)

```bash
# List network policies
kubectl get networkpolicies
kubectl get networkpolicies -A

# Describe network policy
kubectl describe networkpolicy <policy-name>

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- \
  nslookup kubernetes.default
```

### Port Forwarding

```bash
# Forward service port
kubectl port-forward svc/ola-portfolio-service 8080:80

# Forward pod port
kubectl port-forward <pod-name> 8080:8080

# Access: http://localhost:8080
```

## 🔍 Troubleshooting

### Check Cluster Health

```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes
kubectl describe node <node-name>

# Check for issues
kubectl get events --sort-by='.lastTimestamp' | head -20
```

### Debug Pod Issues

```bash
# Describe pod (shows events, conditions, etc.)
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Previous container instance

# Exec into pod
kubectl exec -it <pod-name> -- /bin/sh

# Check resource usage
kubectl top pod <pod-name>
```

### Check CSI Secrets Store

```bash
# Check CSI driver pods
kubectl get pods -n kube-system | grep csi-secrets-store

# View CSI driver logs
kubectl logs -n kube-system -l app=secrets-store-csi-driver

# Check if secrets are mounted
kubectl exec <pod-name> -- ls -la /mnt/secrets-store
```

### Verify ACR Access

```bash
# Check ACR connectivity
az aks check-acr \
  --name ola-aks-dev \
  --resource-group ola-rg-dev \
  --acr olaacr01dev
```

## 📊 Resource Management

### View Resource Usage

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods
kubectl top pods -A

# Resource quotas
kubectl get resourcequota
kubectl describe resourcequota
```

### Clean Up Resources

```bash
# Delete deployment
kubectl delete deployment ola-portfolio-app

# Delete service
kubectl delete svc ola-portfolio-service

# Delete namespace (deletes all resources in namespace)
kubectl delete namespace portfolio-app

# Delete all resources from manifest
kubectl delete -f k8s/
```

## 🔄 Common Workflows

### Deploy New Application Version

```bash
# 1. Build and push image to ACR
docker build -t olaacr01dev.azurecr.io/ola-portfolio-app:v1.0.0 .
az acr login --name olaacr01dev
docker push olaacr01dev.azurecr.io/ola-portfolio-app:v1.0.0

# 2. Update deployment
kubectl set image deployment/ola-portfolio-app \
  ola-portfolio-app=olaacr01dev.azurecr.io/ola-portfolio-app:v1.0.0

# 3. Monitor rollout
kubectl rollout status deployment/ola-portfolio-app

# 4. Verify
kubectl get pods -l app=ola-portfolio-app
```

### Update Secrets

```bash
# 1. Update in Key Vault
az keyvault secret set \
  --vault-name ola-kv-dev \
  --name "secret-name" \
  --value "new-value"

# 2. Restart pods to pick up new secrets
kubectl rollout restart deployment/ola-portfolio-app

# 3. Verify
kubectl get pods -l app=ola-portfolio-app
```

### Scale Application

```bash
# Manual scale
kubectl scale deployment ola-portfolio-app --replicas=5

# Check HPA status
kubectl get hpa ola-portfolio-app-hpa

# View scaling events
kubectl describe hpa ola-portfolio-app-hpa
```

## 📝 Quick Reference

### Essential Commands

```bash
# Connect to cluster
az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev

# Check nodes
kubectl get nodes

# List pods
kubectl get pods -A

# View logs
kubectl logs <pod-name>

# Describe resource
kubectl describe <resource-type> <resource-name>

# Apply manifest
kubectl apply -f <file.yaml>

# Delete resource
kubectl delete <resource-type> <resource-name>
```

### Get Cluster Information

```bash
# Get cluster name
cd infra/terraform
terraform output -raw aks_cluster_name

# Get Key Vault name
terraform output -raw key_vault_name

# Get ACR name
terraform output -raw acr_login_server
```

## 🆘 Getting Help

### Common Issues

1. **"kubelogin not found"**
   - Install: `winget install Microsoft.Azure.Kubelogin`
   - See: TROUBLESHOOTING.md Section 7

2. **"Unable to connect to the server" or "no such host" for privatelink URL**
   - **This is expected for private clusters!** The API server uses a system-managed private DNS zone
   - **The DNS only resolves from within the VNet** - not from Cloud Shell or local machines
   - **Solutions (in order of preference):**
     
     **Option A: Azure Portal "Connect" Feature (Easiest - No Setup)**
     - Go to Azure Portal → Kubernetes services → `ola-aks-dev`
     - Click **"Connect"** button (top menu)
     - Select **"Azure Cloud Shell"** tab
     - Run kubectl commands directly in the portal terminal
     - ✅ Works immediately, no setup required
     
     **Option B: Deploy Jumpbox + Bastion (Recommended for Production)**
     - Deploy Azure Bastion + Jumpbox VM in your VNet
     - Connect via Azure Portal → Virtual Machines → Jumpbox → Connect → Bastion
     - From jumpbox, run: `az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev`
     - ✅ Secure, persistent access
     - See: How to deploy jumpbox below
     
     **Option C: VPN Connection**
     - Set up VPN/ExpressRoute to connect to your VNet
     - Once connected, DNS will resolve from your local machine
     - ✅ Good for regular development work
   
   - **Error example:** `dial tcp: lookup ola-aks-dev-dns-*.privatelink.uksouth.azmk8s.io: no such host`
   - **Why:** System-managed private DNS zone (`privateDnsZone: "system"`) is only accessible from VNet

3. **"Forbidden" errors**
   - You need Azure AD group membership
   - Contact cluster admin to add you to `AKS-Cluster-Admins`

### How to Deploy Jumpbox + Bastion

If you need persistent access to your private cluster:

1. **Update terraform.tfvars:**
   ```hcl
   # Enable Bastion and Jumpbox
   enable_bastion = true
   bastion_subnet_address_prefixes = ["10.0.3.0/26"]
   jumpbox_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."  # Your SSH public key
   ```

2. **Apply Terraform:**
   ```powershell
   cd infra/terraform
   terraform apply -var-file="envs/dev/terraform.tfvars"
   ```

3. **Connect via Azure Portal:**
   - Go to Virtual Machines → `aks-jumpbox`
   - Click "Connect" → "Bastion"
   - Enter username: `azureuser`
   - Enter password: (get from `terraform output jumpbox_password`)

4. **On Jumpbox, connect to cluster:**
   ```bash
   az login
   az aks get-credentials --resource-group ola-rg-dev --name ola-aks-dev
   kubectl get nodes
   ```

### Documentation

- **Quick Reference:** See `QUICK_REFERENCE.md`
- **Troubleshooting:** See `TROUBLESHOOTING.md`
- **Deployment Guide:** See `DEPLOYMENT.md`

## 🎓 Learning Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Azure Kubernetes Service](https://docs.microsoft.com/azure/aks/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Remember:** Your cluster is private with Azure RBAC. Always use `kubelogin` for authentication!
