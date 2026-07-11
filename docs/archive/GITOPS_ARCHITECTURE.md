# Enterprise-Grade GitOps Architecture

## Overview

This project uses **ArgoCD GitOps** for enterprise-grade deployments**.

### Key Principles

1. ✅ **CI Only Pushes Images**: GitHub Actions builds and pushes Docker images to ACR
2. ✅ **Cluster Pulls Manifests**: ArgoCD in-cluster watches Git and deploys automatically
3. ✅ **No CI-to-Cluster Access**: CI never talks to Kubernetes cluster
4. ✅ **Git as Source of Truth**: All cluster state managed via Git
5. ✅ **Enterprise Security**: Private clusters, private endpoints, network policies

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CI/CD Pipeline                          │
│                    (GitHub Actions)                              │
│                                                                  │
│  1. Build Docker Image                                          │
│  2. Push to ACR (Azure Container Registry)                    │
│  3. Update Git manifest with new image tag                      │
│                                                                  │
│  ❌ Does NOT access Kubernetes cluster                          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │      ACR      │
                    │   (Images)     │
                    └───────────────┘
                            │
                            │
┌─────────────────────────────────────────────────────────────────┐
│                    Git Repository                               │
│                                                                  │
│  • Kubernetes Manifests (gitops/apps/)                          │
│  • ArgoCD Applications (gitops/apps/*.yaml)                    │
│  • Single Source of Truth                                       │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Watched by
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AKS Cluster                                   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              ArgoCD (In-Cluster)                        │   │
│  │                                                          │   │
│  │  • Watches Git repository                               │   │
│  │  • Detects manifest changes                            │   │
│  │  • Pulls images from ACR                               │   │
│  │  • Deploys to Kubernetes                                │   │
│  │  • Manages application lifecycle                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Application Pods                            │   │
│  │                                                          │   │
│  │  • Deployed by ArgoCD                                    │   │
│  │  • Images from ACR                                       │   │
│  │  • Managed via Git                                       │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Workflow

### 1. Developer Workflow

```bash
# 1. Make code changes
git add .
git commit -m "Add new feature"
git push origin main

# 2. CI automatically:
#    - Builds Docker image
#    - Pushes to ACR
#    - Updates Git manifest (optional)

# 3. ArgoCD automatically:
#    - Detects Git changes
#    - Pulls new image from ACR
#    - Deploys to cluster
```

### 2. CI Pipeline (GitHub Actions)

**File**: `.github/workflows/ci-build-push.yml`

**What it does**:
- ✅ Authenticates to Azure using OIDC (no secrets!)
- ✅ Builds Docker image from `app/` directory
- ✅ Pushes image to ACR with commit SHA tag
- ✅ Pushes `latest` tag

**What it does NOT do**:
- ❌ Does NOT access Kubernetes cluster
- ❌ Does NOT deploy applications
- ❌ Does NOT need kubectl or cluster credentials

### 3. ArgoCD (In-Cluster)

**What it does**:
- ✅ Watches Git repository for changes
- ✅ Detects new image tags in manifests
- ✅ Pulls images from ACR (using Workload Identity)
- ✅ Deploys applications to Kubernetes
- ✅ Manages application lifecycle (updates, rollbacks)
- ✅ Provides UI for monitoring deployments

**Configuration**:
- Installed via Terraform (Helm chart)
- High availability (2+ replicas)
- Enterprise-grade security settings

## Security Benefits

### 1. Least Privilege

- **CI**: Only has `AcrPush` role (can push images)
- **CI**: Does NOT have AKS access
- **ArgoCD**: Runs in-cluster with Workload Identity
- **ArgoCD**: Only needs `AcrPull` and cluster access

### 2. Network Security

- Private AKS cluster (no public API)
- Private ACR endpoints (no public access)
- Network policies (Cilium)
- No CI-to-cluster network path needed

### 3. Audit Trail

- All changes tracked in Git
- ArgoCD audit logs
- Azure Activity Logs
- Complete deployment history

## Comparison: Traditional vs GitOps

### Traditional CI/CD

```
CI → Build → Push → Deploy to Cluster
              │
              └─── Needs cluster credentials
                   Needs kubectl access
                   Security risk
```

### GitOps (This Project)

```
CI → Build → Push to ACR
              │
              └─── No cluster access needed

Git → ArgoCD → Pull from ACR → Deploy
              │
              └─── Runs in-cluster
                   Secure by default
```

## Getting Started

### 1. Deploy Infrastructure

```bash
cd infra/terraform
terraform apply -var-file="envs/dev/terraform.tfvars"
```

This deploys:
- AKS cluster (private)
- ACR (private endpoints)
- ArgoCD (in-cluster)
- GitHub OIDC (CI only has ACR push)

### 2. Access ArgoCD

```bash
# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Access UI
open https://localhost:8080
```

### 3. Create Application

```bash
# ArgoCD Application is already defined
kubectl apply -f gitops/apps/portfolio-app.yaml

# Or use ArgoCD CLI
argocd app create -f gitops/apps/portfolio-app.yaml
```

### 4. Deploy Application

```bash
# Update image tag in manifest
vim gitops/apps/portfolio-app/deployment.yaml

# Commit and push
git add gitops/apps/portfolio-app/deployment.yaml
git commit -m "Deploy new version"
git push

# ArgoCD automatically syncs
```

## Benefits

### ✅ Security
- CI never accesses cluster
- No secrets in CI/CD
- Private endpoints
- Network isolation

### ✅ Reliability
- Git as source of truth
- Automatic rollback
- Self-healing
- Multi-environment support

### ✅ Compliance
- Complete audit trail
- Git-based approvals
- RBAC integration
- Enterprise-grade

### ✅ Developer Experience
- Simple workflow
- Fast feedback
- Easy rollbacks
- Clear visibility

## Troubleshooting

### ArgoCD Not Syncing

```bash
# Check application status
kubectl get application portfolio-app -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Manual sync
argocd app sync portfolio-app
```

### Image Pull Errors

```bash
# Verify ACR credentials
kubectl get secret acr-secret -n portfolio-app

# Check Workload Identity
kubectl describe serviceaccount portfolio-app -n portfolio-app
```

### CI Pipeline Issues

```bash
# Verify OIDC configuration
az ad app show --id $AZURE_CLIENT_ID

# Check ACR permissions
az role assignment list --assignee $AZURE_CLIENT_ID --scope /subscriptions/.../resourceGroups/...
```

## Next Steps

1. ✅ Infrastructure deployed
2. ✅ ArgoCD installed
3. ✅ CI pipeline configured
4. ✅ GitOps manifests created
5. 🔄 Deploy first application
6. 🔄 Set up multi-environment (dev/staging/prod)
7. 🔄 Configure ArgoCD projects and RBAC
8. 🔄 Set up monitoring and alerts

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
