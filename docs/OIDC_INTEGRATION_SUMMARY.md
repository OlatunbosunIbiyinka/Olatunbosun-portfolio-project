# GitHub Actions OIDC Integration - Summary

## What Was Done

OIDC (OpenID Connect) authentication has been fully integrated into the CI/CD pipeline, eliminating the need to store service principal credentials as GitHub secrets.

## Changes Made

### 1. Terraform Infrastructure

**New Module**: `infra/terraform/modules/github-oidc/`
- Creates Azure AD Application Registration
- Creates Service Principal
- Configures Federated Identity Credential for GitHub OIDC
- Assigns necessary roles (Contributor, AcrPull, AKS Cluster User)

**Updated Files**:
- `infra/terraform/main.tf` - Added GitHub OIDC module integration
- `infra/terraform/variables.tf` - Added OIDC-related variables
- `infra/terraform/output.tf` - Added OIDC output values
- `infra/terraform/envs/dev/terraform.tfvars.example` - Added OIDC configuration example

### 2. GitHub Actions Workflows

**Updated Workflows**:
- `.github/workflows/ci-build-push.yml` - OIDC login; pushes `ola-portfolio-app` to ACR only (no cluster access)
- `.github/workflows/ci.yml` - Quality gates (SonarCloud); no Azure deploy
- `.github/workflows/security.yml` - OIDC login; Trivy scan after image push

All workflows already had:
- `id-token: write` permission (required for OIDC)
- `azure/login@v1` action with client-id, tenant-id, subscription-id

**No client-secret needed** - this is the key benefit of OIDC!

### 3. Documentation

**New Files**:
- `docs/OIDC_SETUP.md` - Comprehensive setup guide
- `scripts/setup-github-oidc.sh` - Automated setup script

**Updated Files**:
- `README.md` - Added OIDC section to secrets documentation

## Benefits

✅ **Enhanced Security**: No long-lived credentials stored in GitHub
✅ **Automatic Token Rotation**: Tokens are short-lived (1 hour)
✅ **Audit Trail**: All authentications logged in Azure AD
✅ **Scoped Access**: Can restrict to specific branches/environments
✅ **Simplified Management**: No need to rotate service principal secrets

## Setup Process

1. **Configure Terraform**:
   ```hcl
   enable_github_oidc = true
   github_repository  = "owner/repo"
   ```

2. **Apply Terraform**:
   ```bash
   terraform apply
   ```

3. **Get OIDC Values**:
   ```bash
   terraform output github_oidc_client_id
   terraform output github_oidc_tenant_id
   terraform output github_oidc_subscription_id
   ```

4. **Set GitHub Secrets**:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

5. **Workflows Ready**: Your workflows will automatically use OIDC!

## Migration Notes

If you were previously using `AZURE_CREDENTIALS` secret:
- Remove the old secret after OIDC is set up
- The workflows don't need any changes (they already use OIDC)
- Test in a non-production branch first

## Verification

After setup, verify OIDC is working:

1. Check federated credential exists:
   ```bash
   az ad app federated-credential list --id <client-id>
   ```

2. Check role assignments:
   ```bash
   az role assignment list --assignee <service-principal-id>
   ```

3. Run a workflow and check Azure AD sign-in logs

## Next Steps

- [ ] Configure environment-specific subjects for different deployment environments
- [ ] Set up branch protection rules
- [ ] Review and limit role assignments to minimum required
- [ ] Monitor Azure AD sign-in logs
- [ ] Remove old service principal credentials (if any)

## References

- [OIDC Setup Guide](OIDC_SETUP.md)
- [GitHub Actions OIDC Docs](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Azure AD Federated Identity](https://docs.microsoft.com/azure/active-directory/develop/workload-identity-federation)
