# 📖 Quick Reference Guide

Quick commands and references for common operations.

## Terraform Commands

```bash
# Initialize
terraform init

# Plan
terraform plan -var-file=envs/dev/terraform.tfvars

# Apply
terraform apply -var-file=envs/dev/terraform.tfvars

# Outputs
terraform output
terraform output -raw key_vault_name
terraform output -raw aks_cluster_name

# Destroy
terraform destroy -var-file=envs/dev/terraform.tfvars
```

## Azure CLI Commands

```bash
# Login
az login

# Set subscription
az account set --subscription "<subscription-id>"

# Get AKS credentials
az aks get-credentials --resource-group <rg-name> --name <aks-name>

# List AKS clusters
az aks list

# Get Key Vault secrets
az keyvault secret show --vault-name <kv-name> --name <secret-name>

# Set Key Vault secret
az keyvault secret set --vault-name <kv-name> --name <secret-name> --value <value>

# List ACR repositories
az acr repository list --name <acr-name>

# ACR login
az acr login --name <acr-name>
```

## Kubernetes Commands

```bash
# Get pods
kubectl get pods
kubectl get pods -l app=ola-portfolio-app
kubectl get pods -o wide

# Describe pod
kubectl describe pod <pod-name>

# Get logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>

# Get services
kubectl get svc
kubectl get svc ola-portfolio-service

# Get deployments
kubectl get deployments
kubectl describe deployment ola-portfolio-app

# Get HPA
kubectl get hpa
kubectl describe hpa ola-portfolio-app-hpa

# Scale deployment
kubectl scale deployment ola-portfolio-app --replicas=3

# Rollout status
kubectl rollout status deployment/ola-portfolio-app

# Rollout history
kubectl rollout history deployment/ola-portfolio-app

# Rollback
kubectl rollout undo deployment/ola-portfolio-app

# Get secrets
kubectl get secrets
kubectl describe secret <secret-name>

# Get SecretProviderClass
kubectl get secretproviderclass
kubectl describe secretproviderclass azure-kv-secrets

# Get ServiceAccount
kubectl get serviceaccount
kubectl describe serviceaccount workload-identity-sa

# Get network policies
kubectl get networkpolicies
kubectl describe networkpolicy ola-portfolio-app-netpol

# Exec into pod
kubectl exec -it <pod-name> -- /bin/sh

# Port forward
kubectl port-forward svc/ola-portfolio-service 8080:80
```

## Docker Commands

```bash
# Build image
docker build -t <acr-name>.azurecr.io/ola-portfolio-app:latest .

# Tag image
docker tag <image-id> <acr-name>.azurecr.io/ola-portfolio-app:v1.0.0

# Push image
docker push <acr-name>.azurecr.io/ola-portfolio-app:latest

# List images
docker images

# Remove image
docker rmi <image-id>
```

## Key Vault Operations

```bash
# List secrets
az keyvault secret list --vault-name <kv-name>

# Get secret value
az keyvault secret show --vault-name <kv-name> --name <secret-name> --query value -o tsv

# Set secret
az keyvault secret set --vault-name <kv-name> --name <secret-name> --value <value>

# Delete secret
az keyvault secret delete --vault-name <kv-name> --name <secret-name>

# List Key Vaults
az keyvault list
```

## Troubleshooting Commands

```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n default --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods

# Check API server
kubectl cluster-info

# Check CSI driver
kubectl get pods -n kube-system | grep csi-secrets-store
kubectl logs -n kube-system -l app=secrets-store-csi-driver

# Verify ACR access
az aks check-acr --name <aks-name> --resource-group <rg-name> --acr <acr-name>
```

## Environment Variables

```bash
# Set from Terraform outputs
export KEY_VAULT_NAME=$(cd infra/terraform && terraform output -raw key_vault_name)
export AKS_NAME=$(cd infra/terraform && terraform output -raw aks_cluster_name)
export ACR_NAME=$(cd infra/terraform && terraform output -raw acr_login_server | cut -d'.' -f1)
export WORKLOAD_IDENTITY_CLIENT_ID=$(cd infra/terraform && terraform output -raw workload_identity_client_id)
```

## Common Workflows

### Deploy New Version

```bash
# 1. Build and push image
cd app
docker build -t $ACR_NAME.azurecr.io/ola-portfolio-app:v1.0.0 .
az acr login --name $ACR_NAME
docker push $ACR_NAME.azurecr.io/ola-portfolio-app:v1.0.0

# 2. Update deployment
kubectl set image deployment/ola-portfolio-app \
  ola-portfolio-app=$ACR_NAME.azurecr.io/ola-portfolio-app:v1.0.0

# 3. Monitor rollout
kubectl rollout status deployment/ola-portfolio-app
```

### Update Secrets

```bash
# Update in Key Vault
az keyvault secret set --vault-name $KEY_VAULT_NAME --name <secret-name> --value <new-value>

# Restart pods to pick up new secrets
kubectl rollout restart deployment/ola-portfolio-app
```

### Scale Application

```bash
# Manual scaling
kubectl scale deployment ola-portfolio-app --replicas=5

# Check HPA
kubectl get hpa ola-portfolio-app-hpa
```

## Useful Links

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/azure/aks/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

