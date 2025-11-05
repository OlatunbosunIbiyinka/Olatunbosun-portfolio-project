cat > README.md <<'EOF'
# My CV — As a Production System
## CI/CD Pipeline Status

| Workflow | Status | Description |
|-----------|--------|-------------|
| **CI Pipeline** | ![CI Pipeline](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/ci.yml/badge.svg) | Runs tests, Sonar scan, builds & pushes Docker image |
| **Security Scans** | ![Security Scans](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/security.yml/badge.svg) | Runs SonarCloud & Trivy vulnerability checks |
| **CD Deploy** | ![CD Deploy](https://github.com/OlatunbosunIbiyinka/Olatunbosun-portfolio-project/actions/workflows/deploy.yml/badge.svg) | Deploys the app to Azure Kubernetes Service |

I got tired of explaining what I do — so I deployed it.
For years, my résumé was just a neat little PDF trying to summarize automation, resilience, and scale into bullet points.
It always felt wrong.
How do you write DevOps on paper?
You can’t. You have to run it.

💡 The Idea
Instead of describing my skills, I built them — as infrastructure.
This project is my CV, deployed like a real production system. From scratch. End-to-end. Fully automated.

🧩 The Stack
When I push a new commit, the pipeline wakes up:


Terraform provisions a fresh Azure environment (AKS + ACR + networking)

Docker packages and runs my CV web app

Deploy workloads on Kubernetes (AKS+ACR)

GitHub Actions runs linting, tests, and security scans (SonarCloud + Trivy)

Prometheus + Grafana monitor performance and metrics

Alertmanager emails me if anything breaks

Yes — even my CV has dashboards and uptime alerts.

⚙️ The Philosophy
Recruiters often ask:

“Can you handle production-grade environments?”

This project answers that question before they ever send the email.
When you visit my CV, you’re not reading about uptime, IaC, or observability —
you’re experiencing it.
Every word, every deployment, every alert says the same thing:

This engineer doesn’t describe DevOps — he lives it.

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

##SCREENSHOTS

<img width="1096" height="681" alt="MyArchitechture drawio (1)" src="https://github.com/user-attachments/assets/3ada42df-0a67-4b78-9d65-20cb2b7499ae" />

<img width="1086" height="430" alt="Screenshot 2025-11-03 093734" src="https://github.com/user-attachments/assets/9e4b7032-30ea-475b-a873-d17770e21584" />
<img width="1321" height="529" alt="Screenshot 2025-11-03 094538" src="https://github.com/user-attachments/assets/24cbc692-bc84-4f03-a833-8d95721b27c4" />

<img width="1919" height="1079" alt="Screenshot 2025-10-27 141712" src="https://github.com/user-attachments/assets/31a00bf1-27f7-40f1-b5c3-43675c79891e" />

<img width="1919" height="1079" alt="Screenshot 2025-10-27 125320" src="https://github.com/user-attachments/assets/f5415ba3-d301-4f8b-aa12-9a691d30c39a" />

<img width="1919" height="1079" alt="Screenshot 2025-10-27 145829" src="https://github.com/user-attachments/assets/510ab293-1a8e-4d2f-be05-ad34bb9b97fa" />

<img width="1919" height="1077" alt="Screenshot 2025-10-27 145915" src="https://github.com/user-attachments/assets/40f6900c-d487-414e-82f5-f7e022f4b7d0" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 150629" src="https://github.com/user-attachments/assets/595ab4c7-208d-4f41-9599-0e2d917b4c28" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 151357" src="https://github.com/user-attachments/assets/cb1e3292-ded7-4358-88b1-df098fb45350" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 115238" src="https://github.com/user-attachments/assets/d00f145f-8c71-49f0-878a-fffa9f29f7e6" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 115643" src="https://github.com/user-attachments/assets/41479b1b-e899-496a-8c77-5e9907f1cd68" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 131057" src="https://github.com/user-attachments/assets/06db843b-8ff5-4e4a-8cf7-2f4d13c0dc4a" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 143749" src="https://github.com/user-attachments/assets/1066df29-acbf-4c59-8d4f-947f2d421e33" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 151846" src="https://github.com/user-attachments/assets/080a67b9-1012-434b-9a66-2d9f330e5b91" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 152019" src="https://github.com/user-attachments/assets/a3017fd7-fbc9-4853-b495-afd36abd52cc" />
<img width="1918" height="1079" alt="Screenshot 2025-10-27 152209" src="https://github.com/user-attachments/assets/af355778-70fa-4895-a4af-97edb4da8e9d" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 152302" src="https://github.com/user-attachments/assets/d1b428a4-e526-4ae7-ab76-d26b45a3c260" />
<img width="1919" height="1066" alt="Screenshot 2025-10-27 162552" src="https://github.com/user-attachments/assets/a74df91e-c373-4980-80b9-daea6073ac38" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 162615" src="https://github.com/user-attachments/assets/363212b9-1aba-4022-b921-902e95126022" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 162710" src="https://github.com/user-attachments/assets/20a32748-41bf-48c8-8d07-53a264450e9f" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 162842" src="https://github.com/user-attachments/assets/b9d9ed56-d4fd-48f4-a988-d888571347f1" />
<img width="1919" height="1079" alt="Screenshot 2025-10-27 164834" src="https://github.com/user-attachments/assets/9c063497-ee2f-4dff-8d4a-2e9f9c458308" />
