cat > README.md <<'EOF'
# DevOps Portfolio Project for Olatunbosun Ibiyinka
## CI/CD Pipeline Status

| Workflow | Status | Description |
|-----------|--------|-------------|
| **CI Pipeline** | ![CI Pipeline](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml/badge.svg) | Runs tests, Sonar scan, builds & pushes Docker image |
| **Security Scans** | ![Security Scans](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/security.yml/badge.svg) | Runs SonarCloud & Trivy vulnerability checks |
| **CD Deploy** | ![CD Deploy](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/deploy.yml/badge.svg) | Deploys the app to Azure Kubernetes Service |


This repository contains a hands-on DevOps project designed to showcase end-to-end skills across infrastructure, automation, monitoring, and security.

---

## Project Goals
- Provision cloud infrastructure with **Terraform (Azure)**
- Deploy workloads on **Kubernetes (AKS + ACR)**
- Automate builds & deployments with **GitHub Actions**
- Implement observability with **Prometheus & Grafana**
- Add security scanning (SonarCloud, Trivy)

---

## Roadmap (14 Days)
- **Day 1** → Setup repo & documentation ✅
- **Day 2–4** → Terraform infra (AKS + ACR)✅ 
- **Day 5–7** → Sample app + Dockerize + push to ACR✅
- **Day 8–9** → Kubernetes manifests + deploy to AKS✅
- **Day 10–11** → CI/CD with GitHub Actions✅
- **Day 12–13** → Monitoring with Prometheus + Grafana✅
- **Day 14** → Security & policies✅


## Terraform Deployment: ACR & AKS

This project now includes Terraform code to provision:

- **Azure Container Registry (ACR)**
- **Azure Kubernetes Service (AKS)**

### Key Points

- Remote backend is used for Terraform state storage.
- Modules structure:
  - `modules/acr` → Creates ACR
  - `modules/aks` → Creates AKS cluster and attaches ACR
- Resource Group is managed by Terraform.
- Local state and sensitive files (`*.tfstate`, `*.tfvars`) are ignored via `.gitignore`.

### Usage

1. Initialize Terraform: `terraform init`
2. Plan deployment: `terraform plan -var-file=terraform.tfvars`
3. Apply deployment: `terraform apply -var-file=terraform.tfvars`
4. View outputs: `terraform output`

🧰 Tech Stack
Category	Tools / Technologies
Cloud	Microsoft Azure
Infrastructure as Code	Terraform
Containerization	Docker
Orchestration	Kubernetes (AKS)
CI/CD	GitHub Actions
Monitoring	Prometheus, Grafana
Security	SonarCloud, Trivy
Registry	Azure Container Registry (ACR)

📈 Monitoring & Observability

Prometheus collects metrics from the AKS cluster and application pods.

Grafana visualizes metrics using custom dashboards for performance and health insights.

Alerts can be configured to trigger on key metrics (CPU, memory, error rate, etc.).

🔒 Security Integration

SonarCloud analyzes code quality and detects vulnerabilities.

Trivy scans Docker images for known CVEs and misconfigurations.

GitHub Action workflows enforce quality gates and security checks before deployment.

🧠 Lessons Learned

Automated infrastructure provisioning improves repeatability and scalability.

CI/CD integration ensures fast, reliable deployments.

Observability and security are critical components of production-ready DevOps workflows.

📫 Contact

Author: Olatunbosun Ibiyinka
LinkedIn: linkedin.com/in/olatunbosunibiyinka
GitHub: github.com/olatunbosunibiyinka
