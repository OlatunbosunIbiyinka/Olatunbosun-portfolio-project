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

This project implements a production-grade CI/CD pipeline using GitHub Actions, Azure Container Registry (ACR), and Azure Kubernetes Service (AKS).
It automates the entire process — from building and testing the app to deploying it on a live Kubernetes cluster.
🧩 Pipeline Overview

The CI/CD process is split into two workflows:

🧱 1. CI Pipeline (.github/workflows/ci.yml)

Triggered on every push or pull request to the main branch.

Steps performed:

Checkout Code – Pulls the latest code from the repository.

Setup Node.js Environment – Installs dependencies using npm ci.

Static Code Analysis – Runs a SonarCloud scan for code quality and security checks.

Build & Push Docker Image –

Builds the app Docker image.

Tags it with the GitHub run number (e.g., v45).

Pushes it to the Azure Container Registry (ACR).

Save Metadata – Saves the image tag (image-tag.txt) and uploads it as an artifact for the CD pipeline to use.

Example image tag:

olaacr01.azurecr.io/ola-portfolio-app:v45

🚀 2. CD Pipeline (.github/workflows/cd.yml)

Automatically triggered when the CI pipeline completes successfully.

Steps performed:

Download Image Artifact – Retrieves the image tag from the CI pipeline.

Azure Login – Authenticates securely to Azure using service principal credentials.

Fetch AKS Credentials – Connects to the AKS cluster using az aks get-credentials.

Update Kubernetes Manifest –
Dynamically replaces IMAGE_PLACEHOLDER in k8s/deployment.yaml with the new image tag.

Deploy to AKS – Applies the updated Kubernetes manifests using kubectl apply.

Monitor Rollout & Health –

Monitors the deployment rollout (kubectl rollout status).

Rolls back automatically if deployment fails.

Checks pod health and readiness before marking success.

Cluster Cleanup (Manual) – Old ReplicaSets are pruned periodically to keep the environment clean.

🧠 Key Features

✅ Fully automated build → test → deploy pipeline

🔄 Automatic rollback on deployment failure

🧩 Dynamic image versioning via GitHub Actions environment variables

🧠 Integrated SonarCloud static analysis

🔒 Secure ACR login with GitHub Secrets

☁️ Zero manual intervention — complete GitOps-style workflow

🔑 Environment Variables & Secrets
Variable / Secret	Description
ACR_USERNAME	Azure Container Registry username
ACR_PASSWORD	Azure Container Registry password
AZURE_CREDENTIALS	Azure service principal credentials (JSON)
SONAR_TOKEN	Authentication token for SonarCloud
REGISTRY	ACR login server (e.g., olaacr01.azurecr.io)
IMAGE_NAME	Docker image name (e.g., ola-portfolio-app)
RESOURCE_GROUP	Azure resource group name
CLUSTER_NAME	AKS cluster name
NAMESPACE	Kubernetes namespace (default)
🧾 Deployment Flow Summary

Developer pushes code to main.

CI pipeline builds the app → runs tests → pushes image to ACR → uploads image tag.

CD pipeline retrieves the image tag → updates the manifest → deploys to AKS.

Rollout is verified → pods are checked for health → automatic rollback if needed.

🌍 Deployment Target

Environment: production

App URL: http://4.250.217.126

Cluster: ola-aks

Registry: olaacr01.azurecr.io


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