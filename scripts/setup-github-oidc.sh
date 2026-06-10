#!/bin/bash

# Script to set up GitHub Actions OIDC and configure GitHub secrets
# Usage: ./setup-github-oidc.sh <github-repo> <resource-group>

set -e

GITHUB_REPO=${1:-""}
RESOURCE_GROUP=${2:-""}

if [ -z "$GITHUB_REPO" ] || [ -z "$RESOURCE_GROUP" ]; then
    echo "Usage: $0 <github-repo> <resource-group>"
    echo "Example: $0 OlatunbosunIbiyinka/Olatunbosun-portfolio-project ola-rg-prod"
    exit 1
fi

echo "🔐 Setting up GitHub Actions OIDC for repository: $GITHUB_REPO"

# Navigate to Terraform directory
cd infra/terraform

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Get outputs
echo "📋 Getting OIDC configuration from Terraform outputs..."

CLIENT_ID=$(terraform output -raw github_oidc_client_id 2>/dev/null || echo "")
TENANT_ID=$(terraform output -raw github_oidc_tenant_id 2>/dev/null || echo "")
SUBSCRIPTION_ID=$(terraform output -raw github_oidc_subscription_id 2>/dev/null || echo "")

if [ -z "$CLIENT_ID" ] || [ -z "$TENANT_ID" ] || [ -z "$SUBSCRIPTION_ID" ]; then
    echo "❌ Error: OIDC configuration not found in Terraform outputs."
    echo "Please ensure:"
    echo "  1. Terraform has been applied with enable_github_oidc = true"
    echo "  2. github_repository is set in terraform.tfvars"
    echo ""
    echo "Example terraform.tfvars:"
    echo "  enable_github_oidc = true"
    echo "  github_repository  = \"$GITHUB_REPO\""
    exit 1
fi

echo ""
echo "✅ OIDC Configuration:"
echo "  Client ID:      $CLIENT_ID"
echo "  Tenant ID:      $TENANT_ID"
echo "  Subscription ID: $SUBSCRIPTION_ID"
echo ""

echo "📝 Configure the following secrets in GitHub:"
echo ""
echo "Repository: https://github.com/$GITHUB_REPO/settings/secrets/actions"
echo ""
echo "Add the following secrets:"
echo ""
echo "  Name: AZURE_CLIENT_ID"
echo "  Value: $CLIENT_ID"
echo ""
echo "  Name: AZURE_TENANT_ID"
echo "  Value: $TENANT_ID"
echo ""
echo "  Name: AZURE_SUBSCRIPTION_ID"
echo "  Value: $SUBSCRIPTION_ID"
echo ""

# Check if gh CLI is available
if command -v gh &> /dev/null; then
    read -p "Do you want to set these secrets using GitHub CLI? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Setting GitHub secrets..."
        gh secret set AZURE_CLIENT_ID -b "$CLIENT_ID" --repo "$GITHUB_REPO"
        gh secret set AZURE_TENANT_ID -b "$TENANT_ID" --repo "$GITHUB_REPO"
        gh secret set AZURE_SUBSCRIPTION_ID -b "$SUBSCRIPTION_ID" --repo "$GITHUB_REPO"
        echo "✅ Secrets configured successfully!"
    fi
else
    echo "💡 Tip: Install GitHub CLI (gh) to automatically set secrets"
    echo "   brew install gh  # macOS"
    echo "   or visit: https://cli.github.com/"
fi

echo ""
echo "🎉 OIDC setup complete!"
echo ""
echo "Your GitHub Actions workflows can now authenticate to Azure using OIDC"
echo "without storing service principal credentials."
