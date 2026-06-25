# GitOps Configuration

Enterprise-grade GitOps workflow using ArgoCD.

## Architecture

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   GitHub    │         │     ACR     │         │    AKS      │
│  (CI/CD)    │────────▶│  (Images)   │         │  (Cluster)  │
└─────────────┘         └──────────────┘         └─────────────┘
      │                                              ▲
      │                                              │
      └──────────────────────────────────────────────┘
                    (Git Repository)
                         │
                         ▼
                  ┌──────────────┐
                  │   ArgoCD     │
                  │  (GitOps)    │
                  └──────────────┘
```

## Workflow

1. **CI Pipeline** (`.github/workflows/ci-build-push.yml`):
   - Builds Docker image from application code
   - Pushes image to Azure Container Registry (ACR)
   - **Does NOT access Kubernetes cluster**

2. **ArgoCD** (In-cluster):
   - Watches Git repository for manifest changes
   - Detects new image tags
   - Automatically deploys to AKS cluster
   - Manages application lifecycle

3. **Git Repository**:
   - Contains Kubernetes manifests
   - ArgoCD Application definitions
   - Single source of truth for cluster state

## Directory Structure

```
gitops/
├── apps/
│   ├── portfolio-app.yaml          # ArgoCD Application definition
│   └── portfolio-app/
│       ├── deployment.yaml         # Kubernetes Deployment + Service
│       ├── ingress.yaml            # olatunbosun.dev public ingress
│       └── networkpolicy-ingress.yaml
├── platform/
│   └── cluster-issuer.yaml         # cert-manager Let's Encrypt (apply once on cluster)
└── README.md                       # This file
```

Public URL setup: see **`docs/DOMAIN_SETUP.md`**.

## Getting Started

### 1. Deploy Infrastructure

```bash
cd infra/terraform
terraform apply -var-file="envs/dev/terraform.tfvars"
```

This will:
- Create AKS cluster
- Install ArgoCD in-cluster
- Configure GitHub OIDC (CI only has ACR push access)

### 2. Access ArgoCD UI

```bash
# Port-forward to ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access UI
open https://localhost:8080
```

### 3. Create ArgoCD Application

The application is already defined in `gitops/apps/portfolio-app.yaml`. ArgoCD will automatically sync it.

Or create manually:

```bash
kubectl apply -f gitops/apps/portfolio-app.yaml
```

### 4. CI/CD Workflow

When you push application code to `main` (or `develop`):

1. **CI - Quality** (`ci.yml`) — lint, build, test, SonarCloud (GitHub-hosted)
2. **CI - Build and Push** (`ci-build-push.yml`) — Buildx build, Trivy gate, push immutable SHA to ACR (self-hosted runner)
3. CI commits the SHA tag to `gitops/apps/portfolio-app/deployment.yaml`
4. Argo CD detects the Git change and deploys automatically

**Security gates:** Trivy (CRITICAL/HIGH) blocks image push; Checkov runs on `infra/**` changes via `terraform.yml`.

## Benefits

✅ **Security**: CI never accesses Kubernetes cluster  
✅ **Separation of Concerns**: Build vs Deploy  
✅ **Audit Trail**: All changes tracked in Git  
✅ **Rollback**: Easy to revert via Git  
✅ **Multi-Environment**: Same workflow for dev/staging/prod  
✅ **Compliance**: GitOps meets enterprise security requirements

## Updating Application

### Update Image Tag

After CI pushes a new image, the GitOps manifest is updated automatically with the commit SHA.
To deploy a specific version manually:

```bash
# Update to a known good SHA from ACR
sed -i 's|image:.*ola-portfolio-app:.*|image: olaacr01dev.azurecr.io/ola-portfolio-app:COMMIT_SHA|' gitops/apps/portfolio-app/deployment.yaml

git add gitops/apps/portfolio-app/deployment.yaml
git commit -m "chore(gitops): deploy ola-portfolio-app@COMMIT_SHA"
git push
```

ArgoCD will automatically sync the change.

### Manual Sync

```bash
# Trigger manual sync via ArgoCD CLI
argocd app sync portfolio-app

# Or via kubectl
kubectl patch application portfolio-app -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

## Troubleshooting

### ArgoCD Not Syncing

```bash
# Check application status
kubectl get application portfolio-app -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Image Pull Errors

```bash
# Verify ACR credentials
kubectl get secret acr-secret -n portfolio-app

# Check image pull secrets
kubectl describe deployment portfolio-app -n portfolio-app
```

## Enterprise-Grade Features

- ✅ Private AKS cluster (no public API server)
- ✅ Private ACR (private endpoints)
- ✅ Network policies (Cilium)
- ✅ RBAC (Azure AD integration)
- ✅ Workload Identity (no secrets in pods)
- ✅ GitOps (ArgoCD)
- ✅ CI/CD separation (CI only pushes images)
