#!/bin/bash

# Script to set up secrets in Azure Key Vault
# Usage: ./setup-keyvault-secrets.sh <key-vault-name>

set -e

KEY_VAULT_NAME=${1:-""}

if [ -z "$KEY_VAULT_NAME" ]; then
    echo "Usage: $0 <key-vault-name>"
    echo "Example: $0 ola-kv-prod"
    exit 1
fi

echo "Setting up secrets in Key Vault: $KEY_VAULT_NAME"

# Check if Key Vault exists
if ! az keyvault show --name "$KEY_VAULT_NAME" &>/dev/null; then
    echo "Error: Key Vault '$KEY_VAULT_NAME' not found"
    exit 1
fi

# Prompt for secrets (in production, use environment variables or Azure DevOps variables)
read -sp "Enter ACR Username: " ACR_USERNAME
echo
read -sp "Enter ACR Password: " ACR_PASSWORD
echo
read -sp "Enter SonarCloud Token: " SONAR_TOKEN
echo

# Store secrets in Key Vault
echo "Storing secrets..."

az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "acr-username" \
    --value "$ACR_USERNAME" \
    --output none

az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "acr-password" \
    --value "$ACR_PASSWORD" \
    --output none

az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "sonar-token" \
    --value "$SONAR_TOKEN" \
    --output none

echo "✅ Secrets stored successfully in Key Vault: $KEY_VAULT_NAME"
echo ""
echo "Stored secrets:"
echo "  - acr-username"
echo "  - acr-password"
echo "  - sonar-token"

