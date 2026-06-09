# 🔐 GitHub Actions OIDC Setup Guide

This guide explains how to set up OpenID Connect (OIDC) authentication for GitHub Actions to authenticate with Azure without storing service principal credentials.

## Overview

OIDC allows GitHub Actions to authenticate directly to Azure using short-lived tokens, eliminating the need to store long-lived service principal credentials as secrets. This is more secure and follows Azure best practices.

## Architecture

```
┌─────────────────┐
│  GitHub Actions │
│   (Workflow)    │
└────────┬────────┘
         │
         │ 1. Request OIDC Token
         ▼
┌─────────────────┐
│  GitHub OIDC    │
│   Provider     │
└────────┬────────┘
         │
         │ 2. Issue Token
         ▼
┌─────────────────┐
│  Azure AD       │
│  (Federated     │
│   Credential)   │
└────────┬────────┘
         │
         │ 3. Validate & Issue Azure Token
         ▼
┌─────────────────┐
│  Azure          │
│  Resources      │
└─────────────────┘
```

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.0 installed
- GitHub repository
- Azure CLI installed and configured

## Step 1: Configure Terraform Variables

Edit `infra/terraform/envs/dev/terraform.tfvars`:

```hcl
# Enable GitHub OIDC
enable_github_oidc = true

# GitHub repository (format: owner/repo)
github_repository = "OlatunbosunIbiyinka/Olatunbosun-portfolio-project"

# GitHub branch (default: main)
github_branch = "main"

# Optional: Additional subjects for environments or pull requests
github_oidc_additional_subjects = [
  "repo:OlatunbosunIbiyinka/Olatunbosun-portfolio-project:pull_request",
  "repo:OlatunbosunIbiyinka/Olatunbosun-portfolio-project:environment:production"
]

# Role assignments for the service principal
github_oidc_role_assignments = ["Contributor"]
```

## Step 2: Apply Terraform Configuration

```bash
cd infra/terraform
terraform init
terraform plan -var-file=envs/dev/terraform.tfvars
terraform apply -var-file=envs/dev/terraform.tfvars
```

This will create:
- Azure AD Application Registration
- Service Principal
- Federated Identity Credential
- Role assignments

## Step 3: Get OIDC Configuration

```bash
# Get the values from Terraform outputs
cd infra/terraform
terraform output github_oidc_client_id
terraform output github_oidc_tenant_id
terraform output github_oidc_subscription_id
```

Or use the setup script:

```bash
chmod +x scripts/setup-github-oidc.sh
./scripts/setup-github-oidc.sh OlatunbosunIbiyinka/Olatunbosun-portfolio-project ola-rg-prod
```

## Step 4: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

1. Go to: `https://github.com/<owner>/<repo>/settings/secrets/actions`
2. Click "New repository secret"
3. Add the following secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AZURE_CLIENT_ID` | From Terraform output | Application (client) ID |
| `AZURE_TENANT_ID` | From Terraform output | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | From Terraform output | Azure subscription ID |

### Using GitHub CLI

```bash
gh secret set AZURE_CLIENT_ID -b "<client-id>" --repo "<owner>/<repo>"
gh secret set AZURE_TENANT_ID -b "<tenant-id>" --repo "<owner>/<repo>"
gh secret set AZURE_SUBSCRIPTION_ID -b "<subscription-id>" --repo "<owner>/<repo>"
```

## Step 5: Update GitHub Actions Workflows

The workflows are already configured to use OIDC. Ensure they have:

```yaml
permissions:
  contents: read
  id-token: write  # Required for OIDC
  actions: read
```

And the Azure login step:

```yaml
- name: Azure Login (OIDC)
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**Note**: No `client-secret` is needed with OIDC!

## How It Works

1. **GitHub Actions** requests an OIDC token from GitHub's OIDC provider
2. **GitHub** issues a JWT token with repository/branch information
3. **Azure AD** validates the token against the federated credential
4. **Azure AD** issues an Azure access token
5. **GitHub Actions** uses the token to access Azure resources

## Security Benefits

✅ **No Long-Lived Credentials**: Tokens are short-lived (1 hour)
✅ **Scoped Access**: Tokens are scoped to specific repositories/branches
✅ **Audit Trail**: All authentications are logged in Azure AD
✅ **Automatic Rotation**: No need to rotate service principal secrets
✅ **Least Privilege**: Can restrict to specific branches or environments

## Advanced Configuration

### Environment-Specific Subjects

For different environments (dev, staging, prod), you can create separate subjects:

```hcl
github_oidc_additional_subjects = [
  "repo:owner/repo:environment:development",
  "repo:owner/repo:environment:staging",
  "repo:owner/repo:environment:production"
]
```

Then in your workflow:

```yaml
jobs:
  deploy:
    environment: production  # Matches the subject
    steps:
      - name: Azure Login (OIDC)
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Pull Request Subjects

To allow pull requests to authenticate:

```hcl
github_oidc_additional_subjects = [
  "repo:owner/repo:pull_request"
]
```

### Custom Role Assignments

Limit permissions by assigning specific roles:

```hcl
github_oidc_role_assignments = [
  "Reader",
  "AcrPull",
  "Azure Kubernetes Service Cluster User Role"
]
```

## Troubleshooting

### Authentication Fails

1. **Check Federated Credential**: Verify the subject matches your repository/branch
   ```bash
   az ad app federated-credential list --id <client-id>
   ```

2. **Check Role Assignments**: Ensure the service principal has required permissions
   ```bash
   az role assignment list --assignee <service-principal-id>
   ```

3. **Check GitHub Secrets**: Verify secrets are set correctly
   ```bash
   gh secret list --repo <owner>/<repo>
   ```

### Token Validation Errors

- Ensure `id-token: write` permission is set in the workflow
- Verify the subject in the federated credential matches the workflow context
- Check Azure AD logs for authentication attempts

### Permission Denied

- Verify role assignments are correct
- Check if the service principal has access to the resource
- Ensure the scope in role assignments includes the target resource

## Verification

Test the OIDC authentication:

```bash
# In a GitHub Actions workflow, add:
- name: Verify Azure Authentication
  run: |
    az account show
    az account list
```

## Migration from Service Principal

If you're currently using service principal credentials:

1. Set up OIDC (follow steps above)
2. Update workflows to use OIDC (remove `client-secret`)
3. Test in a non-production branch
4. Remove old `AZURE_CREDENTIALS` secret
5. Monitor for any authentication issues

## Best Practices

1. **Use Environment-Specific Subjects**: Create separate subjects for different environments
2. **Limit Role Assignments**: Grant only necessary permissions
3. **Monitor Access**: Review Azure AD sign-in logs regularly
4. **Use Branch Protection**: Restrict OIDC to protected branches
5. **Regular Audits**: Review and remove unused federated credentials

## References

- [GitHub Actions OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Azure AD Federated Identity Credentials](https://docs.microsoft.com/azure/active-directory/develop/workload-identity-federation)
- [Azure Login Action](https://github.com/azure/login)
