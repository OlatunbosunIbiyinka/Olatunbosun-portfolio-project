#!/bin/bash

# Production deployment script
# Usage: ./deploy.sh <environment> <image-tag>

set -e

ENVIRONMENT=${1:-"dev"}
IMAGE_TAG=${2:-"latest"}

if [ -z "$ENVIRONMENT" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Usage: $0 <environment> <image-tag>"
    echo "Example: $0 dev v1.0.0"
    exit 1
fi

echo "🚀 Deploying to $ENVIRONMENT environment with image tag: $IMAGE_TAG"

# HCL tfvars cannot be sourced as shell; ACR/AKS/RG come from terraform output below.
if [ ! -f "infra/terraform/envs/$ENVIRONMENT/terraform.tfvars" ]; then
    echo "Error: Environment configuration not found: infra/terraform/envs/$ENVIRONMENT/terraform.tfvars"
    exit 1
fi

# Get ACR name and AKS details from Terraform outputs
cd infra/terraform
ACR_NAME=$(terraform output -raw acr_login_server | cut -d'.' -f1)
AKS_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
cd ../..

# Get AKS credentials
echo "📋 Getting AKS credentials..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --overwrite-existing

# Update deployment manifest with image
echo "📝 Updating deployment manifest..."
FULL_IMAGE_NAME="$ACR_NAME.azurecr.io/ola-portfolio-app:$IMAGE_TAG"

# Update deployment.yaml
sed -i.bak "s|IMAGE_PLACEHOLDER|$FULL_IMAGE_NAME|g" k8s/deployment.yaml

# Apply Kubernetes manifests
echo "☸️  Applying Kubernetes manifests..."

kubectl apply -f k8s/serviceaccount.yaml
kubectl apply -f k8s/secretproviderclass.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
kubectl apply -f k8s/networkpolicy.yaml

# Wait for rollout
echo "⏳ Waiting for deployment rollout..."
kubectl rollout status deployment/ola-portfolio-app --timeout=5m

# Verify deployment
echo "✅ Verifying deployment..."
kubectl get pods -l app=ola-portfolio-app
kubectl get svc ola-portfolio-service

# Restore original deployment.yaml
mv k8s/deployment.yaml.bak k8s/deployment.yaml

echo "🎉 Deployment completed successfully!"
echo ""
echo "Application is available at:"
kubectl get svc ola-portfolio-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

