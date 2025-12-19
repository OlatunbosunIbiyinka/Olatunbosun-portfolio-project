## 🚀 CI/CD Pipeline Status
| Workflow | Status | Description |
|-----------|--------|-------------|
| **CI Pipeline** | ![CI Pipeline](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml/badge.svg) | Runs tests, Sonar scan, builds & pushes Docker image |
| **Security Scans** | ![Security Scans](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/security.yml/badge.svg) | Runs SonarCloud & Trivy vulnerability checks |
| **CD Deploy** | ![CD Deploy](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/deploy.yml/badge.svg) | Deploys the app to Azure Kubernetes Service |

## 🎯 Project Goals

- ✅ Provision cloud infrastructure with **Terraform (Azure)**
- ✅ Deploy workloads on **Kubernetes (AKS + ACR)**
- ✅ Automate builds & deployments with **GitHub Actions (CI/CD)**
- ✅ Implement observability with **Prometheus & Grafana**
- ✅ Add security scanning with **SonarCloud** and **Trivy**

---

## 🗓️ Roadmap (14 Days)

| Day | Task | Status |
|-----|------|--------|
| 1 | Setup repo & documentation | ✅ |
| 2–4 | Terraform infra (AKS + ACR) | ✅ |
| 5–7 | Sample app + Dockerize + push to ACR | ✅ |
| 8–9 | Kubernetes manifests + deploy to AKS | ✅ |
| 10–11 | CI/CD with GitHub Actions | ✅ |
| 12–13 | Monitoring with Prometheus + Grafana | ✅ |
| 14 | Security & policies | ✅ |

---

## 🏗️ Terraform Deployment: ACR & AKS

This project provisions and configures core infrastructure on **Azure** using Terraform.

### 🔹 Resources
- Azure Container Registry (**ACR**)  
- Azure Kubernetes Service (**AKS**)  

### 📁 Structure
terraform/
├── modules/
│ ├── acr/ # Creates ACR
│ └── aks/ # Creates AKS cluster and attaches ACR
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars

csharp
Copy code

### ⚙️ Usage
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file=terraform.tfvars

# Apply deployment
terraform apply -var-file=terraform.tfvars

# View outputs
terraform output
Note: Remote backend is configured for state storage. Sensitive files (*.tfstate, *.tfvars) are excluded via .gitignore.


⚙️ Continuous Integration & Continuous Deployment (CI/CD)

CI/CD Pipeline – Automated Build, Security, and Deployment to Azure AKS

This project implements a fully automated end-to-end CI/CD pipeline using GitHub Actions, Terraform, Azure Container Registry (ACR), and Azure Kubernetes Service (AKS).
The pipeline builds, tests, secures, packages, and deploys a containerized portfolio application following enterprise-grade DevOps and RBAC controls.

📌 Architecture Overview
Developer Commit  →  GitHub CI Pipeline
          → Build + Test + Security Scan
          → Build Docker Image + Push to ACR
          → GitHub CD Pipeline Triggered
          → Deploy Updated Manifest to AKS
          → Rollout Status + Automated Rollback

1️⃣ CI Pipeline (Continuous Integration)

The CI pipeline executes on every commit/PR and performs:

✔ 1. Code checkout & dependency installation

Ensures the environment matches production.

✔ 2. Unit tests & linting

Guarantees code quality and security compliance.

✔ 3. Build optimized React application

Uses Node.js to create a production-ready build.

✔ 4. Docker image creation

Built from the /app directory using a multi-stage Dockerfile.

✔ 5. Push image to ACR

The image is tagged dynamically:

<registry>/<image-name>:v<build-number>


The CI pipeline uploads an artifact called image-tag.txt, which the CD pipeline consumes.

2️⃣ CD Pipeline (Continuous Deployment)

Triggered only when CI completes successfully.

✔ 1. OIDC Federated Azure Login

No secrets stored — GitHub uses workload identity federation to authenticate securely.

✔ 2. Get AKS credentials

The CD pipeline fetches cluster credentials using:

az aks get-credentials --resource-group <rg> --name <aks-name>

✔ 3. Manifest rendering

The deployment manifest (deployment.yaml) contains:

image: IMAGE_PLACEHOLDER


The pipeline dynamically replaces it with the latest built image:

sed "s|IMAGE_PLACEHOLDER|$IMAGE|g"


This ensures Kubernetes always deploys the correct version.

✔ 4. Apply manifest to AKS
kubectl apply -f rendered/deployment.yaml

✔ 5. Monitor rollout

The pipeline waits for AKS to report success:

kubectl rollout status deployment/ola-portfolio-app

✔ 6. Automatic rollback on failure

If a pod enters CrashLoopBackoff or ImagePullBackOff:

kubectl rollout undo deployment/ola-portfolio-app

✔ 7. Health verification

Ensures at least one READY pod exists before succeeding the deployment.

3️⃣ RBAC & Security Controls
✔ ACR Access Control

Two roles were assigned to ensure secure image management:

Role	Purpose
AcrPush (GitHub CI identity)	Allows pipeline to push images into ACR
AcrPull (AKS kubelet identity)	Allows nodes to pull private images from ACR

This prevents unauthorized registry access.

✔ Cluster Access Control

The GitHub CD workload identity was granted:

Azure Kubernetes Service RBAC Writer
→ Allows deployments, pod updates, rollouts.

AKS Cluster Admin (when troubleshooting required)
→ Full access, but only temporarily.

This demonstrates least-privilege access in a real environment.

4️⃣ Terraform Infrastructure Automation

Terraform provisions:

✔ Resource Group
✔ Azure Container Registry
✔ Azure Kubernetes Service
✔ Managed Identity bindings
✔ Role assignments (ACR Pull, ACR Push)

Remote backend uses Azure Storage with state locking.

5️⃣ Kubernetes Deployment

The deployment uses:

✔ 1 replica (scalable)
✔ NGINX static file serving
✔ Image supplied by pipeline
✔ Port 80 exposed to a Service

Example:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: ola-portfolio-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ola-portfolio-app
  template:
    metadata:
      labels:
        app: ola-portfolio-app
    spec:
      containers:
      - name: ola-portfolio-app
        image: IMAGE_PLACEHOLDER
        ports:
        - containerPort: 80

6️⃣ Deployment Verification

After each rollout:

kubectl get pods
kubectl describe pod <pod>
kubectl logs <pod>


AKS validates:

Pod readiness

Image pull success

No CrashLoopBackOff

Service endpoint functioning

Application responds at public IP

✅ Key Outcomes
🔹 Fully automated CI/CD from commit → AKS deployment
🔹 Zero manual image tagging
🔹 Secure access using Azure OIDC (no passwords)
🔹 Automatic rollback protects production
🔹 RBAC governance aligned with enterprise policy
🔹 Terraform IaC ensures repeatable cloud environments


📊 Observability

Prometheus and Grafana are configured for:

Real-time metrics on application and cluster performance

Alerting and visualization dashboards

Email notifications are configured via Alertmanager SMTP.

🛡️ Security

Integrated with:

SonarCloud → Code quality and static analysis

Trivy → Container vulnerability scanning

GitHub Secrets → Secure management of credentials (ACR, Sonar, Azure)

🧰 Tech Stack
Category	Tool
Cloud	Azure
IaC	Terraform
Containerization	Docker
Orchestration	Kubernetes (AKS)
CI/CD	GitHub Actions
Security	SonarCloud, Trivy
Monitoring	Prometheus, Grafana
👨‍💻 Maintainer

Olatunbosun Ibiyinka
🔗 LinkedIn
 | GitHub
