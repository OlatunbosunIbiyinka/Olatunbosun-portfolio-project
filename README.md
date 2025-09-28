cat > README.md <<'EOF'
# DevOps Portfolio Project for Olatunbosun Ibiyinka

This repository contains a hands-on DevOps project designed to showcase end-to-end skills across infrastructure, automation, monitoring, and security.

---

## Project Goals
- Provision cloud infrastructure with **Terraform (Azure)**
- Deploy workloads on **Kubernetes (AKS + ACR)**
- Automate builds & deployments with **GitHub Actions**
- Implement observability with **Prometheus & Grafana**
- Add security scanning (SonarCloud, Trivy, OWASP ZAP)

---

## Roadmap (14 Days)
- **Day 1** → Setup repo & documentation ✅
- **Day 2–4** → Terraform infra (AKS + ACR)✅ 
- **Day 5–7** → Sample app + Dockerize + push to ACR✅
- **Day 8–9** → Kubernetes manifests + deploy to AKS✅
- **Day 10–11** → CI/CD with GitHub Actions
- **Day 12–13** → Monitoring with Prometheus + Grafana
- **Day 14** → Security & policies


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
