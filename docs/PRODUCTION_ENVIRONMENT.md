# Production Environment — Target State

> **Purpose:** What we would implement for a full **production** deployment of this platform end-to-end.  
> **Status today:** **Dev** validates the architecture. **Staging** and **prod** are **codified in Terraform** (`envs/staging/`, `envs/prod/`) but not provisioned. Items marked **(codified)** exist in repo config; items marked **(to add)** are planned prod enhancements.

**How to use this document:** Interview and design reference — “dev proves the pattern; this is the production target.”

---

## Summary

| Layer | Dev today | Production target |
|-------|-----------|---------------------|
| **Environments** | `dev` live | `dev` → `staging` → `prod` with isolated state |
| **Infrastructure** | Single RG, uksouth | Hardened prod RG + geo-DR for ACR |
| **CI/CD** | 3 workflows, manual TF apply | + GitHub Environments, approvals, prod OIDC subjects |
| **GitOps** | Slim manifests | Full hardened manifests in GitOps path |
| **Observability** | LAW + optional Prometheus | LAW everywhere + AMA on ops VM + alerts + SLOs |
| **Operations** | Bastion + ops VM | + PIM, patching, backup, runbooks |

---

## 1. Environment & State Management

### Target

| Item | Production implementation |
|------|---------------------------|
| **Three environments** | `dev`, `staging`, `prod` — separate `terraform.tfvars` per env |
| **State isolation** | Separate blob keys: `terraform.tfstate`, `staging/terraform.tfstate`, `prod/terraform.tfstate` via `backends/*.hcl` **(codified)** |
| **Subscription strategy** | Prod in dedicated subscription or management group (org policy) **(to add)** |
| **State hardening** | Blob **versioning + soft delete** on `olaportfolio001`; optional dedicated prod state account **(to add)** |
| **Naming** | `ola-rg-prod`, `ola-aks-prod`, `olaacr01prod`, `ola-kv-prod` **(codified)** |
| **Tags** | `Environment = production`, cost centre, owner, data classification **(codified)** |
| **Destroy protection** | `prevent_deletion_if_contains_resources = true` on RG provider feature; KV purge protection **on** **(codified in prod tfvars)** |

### Apply model

- **CI:** `terraform plan` only (Checkov gate, OIDC to state)
- **Prod apply:** Manual or **Atlantis / Terraform Cloud** from ops VM with **change ticket + approval**
- **Staged deploy:** `enterprise-deploy.ps1` for first prod bootstrap **(exists)**

---

## 2. Infrastructure (Terraform / Azure)

### Network

| Item | Production implementation |
|------|---------------------------|
| **VNet** | `10.0.0.0/16`, dedicated subnets (AKS, PE, Bastion, operations) **(codified)** |
| **Private AKS** | API server VNet-only **(codified)** |
| **Private endpoints** | ACR + Key Vault; public access disabled **(codified)** |
| **NAT Gateway + UDR** | Predictable egress; `userDefinedRouting` aligned with Terraform **(codified)** |
| **NSGs** | PE subnet (HTTPS from AKS only); ops subnet restricted **(codified)** |
| **Private DNS** | `privatelink.azurecr.io`, `privatelink.vaultcore.azure.net` **(codified)** |
| **Hub/spoke or firewall** | Azure Firewall or hub VNet for prod egress filtering **(to add — org dependent)** |
| **DDoS** | DDoS Network Protection on VNet **(to add)** |

### AKS

| Item | Production implementation |
|------|---------------------------|
| **SKU** | Standard tier (SLA) **(codified)** |
| **CNI** | Azure CNI Overlay + Cilium dataplane and network policy **(codified)** |
| **Node pools** | System pool (tainted) + workload pool; min 2 nodes each in prod **(codified in prod tfvars)** |
| **Availability zones** | System and workload pools spread across zones **(to add)** |
| **Azure RBAC** | Enabled; local accounts disabled **(codified)** |
| **Azure Policy** | Add-on enabled **(codified)** |
| **Workload Identity + CSI** | Key Vault secrets provider **(codified)** |
| **Maintenance windows** | Scheduled upgrade windows for control plane and node pools **(to add)** |
| **Uptime SLA** | Standard tier + multi-zone node pools **(to add)** |

### ACR

| Item | Production implementation |
|------|---------------------------|
| **SKU** | Premium (private endpoint, geo-replication) **(codified)** |
| **Geo-replication** | `northeurope` paired region **(codified in prod tfvars)** |
| **Retention** | Image retention policy; purge untagged manifests **(to add)** |
| **Content trust / signing** | Notation or Cosign signed images in CI **(to add)** |
| **Defender for Containers** | Enabled on subscription/ACR **(to add)** |

### Key Vault

| Item | Production implementation |
|------|---------------------------|
| **RBAC** | No legacy access policies **(codified)** |
| **Purge protection** | `true` **(codified in prod tfvars)** |
| **Soft delete** | 7–90 day retention per policy **(codified)** |
| **Private endpoint** | Network default Deny **(codified)** |
| **Diagnostics** | AuditEvent → Log Analytics **(codified)** |
| **Rotation** | Automated rotation for secrets (ACR tokens, Sonar, etc.) **(to add)** |

### Operations VM (Trusted Execution Zone)

| Item | Production implementation |
|------|---------------------------|
| **Access** | Azure Bastion only; no public IP **(codified)** |
| **Auth** | Azure AD login; VM Admin/User Login via RBAC groups **(codified)** |
| **Managed identity** | Least-privilege roles (AKS admin, AcrPush, KV Secrets User) **(codified)** |
| **Self-hosted runner** | GitHub Actions runner for private ACR builds **(codified)** |
| **Patching** | Azure Update Manager / maintenance configuration **(to add)** |
| **Backup** | Azure Backup for VM OS disk **(to add)** |
| **Hardening** | CIS-aligned baseline; JIT access via PIM where possible **(to add)** |

### Argo CD

| Item | Production implementation |
|------|---------------------------|
| **HA** | 2+ replicas controller/repo-server/server; Redis HA **(codified)** |
| **Projects & RBAC** | Argo CD Projects limiting what apps can deploy where **(to add)** |
| **SSO** | Azure AD SSO for Argo CD UI **(to add)** |

---

## 3. CI/CD Pipelines

### Target (builds on existing three workflows)

| Item | Production implementation |
|------|---------------------------|
| **Quality (`ci.yml`)** | Blocking on PR; SonarCloud quality gate enforced **(partial — gate optional today)** |
| **Release (`ci-build-push.yml`)** | Self-hosted runner; Trivy CRITICAL/HIGH gate; immutable SHA only **(codified)** |
| **IaC (`terraform.yml`)** | fmt, validate, Checkov, plan artifact **(codified)** |
| **GitHub Environments** | `staging`, `production` with required reviewers **(to add)** |
| **OIDC subjects** | `environment:production` for prod federated credential **(codified in prod tfvars)** |
| **Branch protection** | Required PR reviews, status checks, no direct push to `main` **(to add — GitHub settings)** |
| **CODEOWNERS** | `infra/`, `gitops/` require platform team review **(to add)** |
| **Terraform apply in CI** | **No** for prod — apply from ops VM / Atlantis with approval **(by design)** |
| **Plan on PR** | Post plan summary comment; optional OPA/Sentinel policy **(to add)** |
| **Smoke test** | Post-deploy verification; optional **auto-rollback** on failure **(smoke exists; auto-rollback to add)** |
| **Concurrency** | Per-branch cancel-in-progress **(codified)** |
| **Path filters** | Prevent GitOps bot → build loop **(codified)** |

### Supply chain

| Item | Production implementation |
|------|---------------------------|
| **Trivy** | Gate before push **(codified)** |
| **Checkov** | Gate on infra PR/push **(codified)** |
| **SonarCloud** | Blocking quality gate **(to add)** |
| **SBOM** | Generate and store per image (CycloneDX/SPDX) **(to add)** |
| **Image signing** | Cosign sign in CI; verify in admission **(to add)** |
| **Dependency scanning** | Dependabot / Renovate for npm and Terraform providers **(to add)** |

---

## 4. GitOps & Application Delivery

### Target

| Item | Production implementation |
|------|---------------------------|
| **Source of truth** | `gitops/apps/portfolio-app/` on `main` **(codified)** |
| **Argo CD Application** | Automated sync, prune, selfHeal **(codified)** |
| **Immutable tags** | `{git-sha}` only — no `:latest` in CI **(codified)** |
| **Hardened manifests in GitOps** | Merge from `k8s/`: HPA, PDB, network policies, ingress, CSI **(to add)** |
| **Ingress + TLS** | NGINX Ingress or App Gateway + cert-manager / Key Vault certs **(to add)** |
| **WAF** | Application Gateway WAF or Front Door **(to add)** |
| **Multi-env GitOps** | `staging` branch or overlay path; Argo CD apps per env **(to add)** |
| **Rollback** | Git revert + Argo history; documented `kubectl rollout undo` **(documented)** |
| **Progressive delivery** | Argo Rollouts or canary (future) **(to add)** |

### Application runtime

| Item | Production implementation |
|------|---------------------------|
| **Replicas** | Min 2; HPA 2–10 **(reference in k8s/; to add to GitOps)** |
| **PDB** | `minAvailable: 1` **(reference in k8s/)** |
| **Probes** | `/health:8080` aligned with nginx **(codified in GitOps)** |
| **Resources** | Requests/limits on all containers **(codified)** |
| **Pod security** | Restricted PSS; non-root nginx **(reference in k8s/)** |

---

## 5. Observability & Monitoring

### Azure Monitor (platform — primary for ops VM)

| Item | Production implementation |
|------|---------------------------|
| **Log Analytics workspace** | Per env or shared with RBAC **(codified)** |
| **AKS Container Insights** | `oms_agent` → LAW **(codified)** |
| **Key Vault diagnostics** | Audit logs → LAW **(codified)** |
| **Ops VM — AMA + DCR** | Terraform: `AzureMonitorLinuxAgent` + DCR for syslog, perf, custom logs (runner `_diag`) **(to add)** |
| **VM Insights** | Enable via DCR / solutions **(to add)** |
| **Azure Monitor alerts** | Node NotReady, runner service down, disk >80%, Argo OutOfSync, failed pipelines **(to add)** |
| **Action groups** | Email, Teams, PagerDuty/on-call integration **(to add)** |
| **Retention** | 90+ days prod (vs 30 dev) **(to add)** |
| **Microsoft Sentinel** | Optional SIEM on LAW for gov/SOC **(to add — org dependent)** |

### Kubernetes observability (workloads)

| Item | Production implementation |
|------|---------------------------|
| **kube-prometheus-stack** | Prometheus + Grafana + Alertmanager in `monitoring` namespace **(script exists; to add to GitOps/Terraform)** |
| **Grafana dashboards** | Cluster, Argo CD, app golden signals **(to add)** |
| **Cilium Hubble** | Network flow visibility **(optional; values exist)** |
| **ServiceMonitor** | App and Argo CD metrics scraped **(to add)** |
| **SLOs** | Availability on `/health`; error budget alerts **(to add)** |

### CI/CD observability

| Item | Production implementation |
|------|---------------------------|
| **GitHub Actions insights** | Failed runs, queue time on self-hosted runner **(native)** |
| **Smoke test failures** | Alert + ticket; link to LAW runner logs **(to add)** |

---

## 6. Security & Identity

| Item | Production implementation |
|------|---------------------------|
| **GitHub OIDC** | No long-lived `client_secret`; federated credentials per env **(codified)** |
| **CI least privilege** | Reader + AcrPush + state blob; **no AKS access** **(codified)** |
| **Human access** | Azure AD groups → AKS Cluster Admin / Operator; PIM for admin **(partial; PIM to add)** |
| **Workload Identity** | Pods → Key Vault without secrets in manifests **(codified)** |
| **Network policies** | Cilium default-deny + explicit allows **(reference in k8s/; to add to GitOps)** |
| **Azure Policy on AKS** | Block `:latest`, require limits, approved registries **(codified)** |
| **Secret scanning** | GitHub secret scanning; no secrets in tfvars in Git **(gitignored)** |
| **Audit trail** | Git history, Azure Activity Log, KV audit, Argo CD audit **(partial)** |
| **Defender for Cloud** | Secure score, regulatory compliance dashboard **(to add)** |

---

## 7. Disaster Recovery & Business Continuity

| Item | Production implementation |
|------|---------------------------|
| **RTO / RPO** | Documented targets (e.g. RPO 1h state+Git, RTO 4h re-apply) **(to add)** |
| **IaC recovery** | Full platform reproducible from Git + state backup **(by design)** |
| **State backup** | Blob versioning; periodic `terraform state pull` **(to add)** |
| **ACR geo-replication** | `northeurope` **(codified in prod tfvars)** |
| **Application** | Stateless SPA — GitOps SHA tags are runtime source of truth **(by design)** |
| **Key Vault** | Soft delete + purge protection **(codified)** |
| **AKS** | Multi-region active-passive runbook (not active-active) **(to add)** |
| **Velero** | Kubernetes resource backup to storage **(to add)** |
| **DR drill** | Annual destroy-and-rebuild from Git + state **(to add)** |

---

## 8. Governance & Operations

| Item | Production implementation |
|------|---------------------------|
| **Change management** | PR → review → merge → automated deploy; infra apply with ticket **(to add)** |
| **Runbooks** | Argo sync failure, rollback, node NotReady, OIDC failure, state lock **(partial in TROUBLESHOOTING.md)** |
| **On-call** | Rotation, escalation, severity definitions **(to add)** |
| **Cost management** | Budget alerts per RG; right-sizing reviews **(to add)** |
| **Patching** | AKS auto-upgrade channel; VM maintenance window **(to add)** |
| **Access reviews** | Quarterly RBAC and Key Vault access review **(to add)** |

---

## 9. End-to-End Production Flow

```text
Developer
  → PR to main (branch protection, ci.yml quality + Checkov on infra)
  → Review + approval
  → Merge

Release (app change)
  → ci-build-push.yml on self-hosted runner (OIDC → ACR)
  → Trivy gate → push SHA → GitOps commit
  → Argo CD sync (prod cluster)
  → Smoke test → alert on failure

Infrastructure change
  → terraform.yml plan on PR/push
  → Platform engineer review plan artifact
  → Approved apply from ops VM (staging first, then prod)
  → Post-apply verification (nodes Ready, Argo healthy)

Operations
  → All investigation in Log Analytics (AKS + KV + ops VM AMA)
  → Grafana for Kubernetes metrics
  → Alerts → on-call → runbook
```

---

## 10. Implementation Priority (suggested)

| Phase | Focus | Key deliverables |
|-------|-------|------------------|
| **P0 — Codified, apply prod** | Environments | `prod/terraform.tfvars`, `backends/prod.hcl`, state versioning |
| **P1 — Security & delivery** | GitOps hardening | HPA/PDB/netpol/ingress in GitOps; GitHub Environments; branch protection |
| **P2 — Observability** | Ops VM + alerts | AMA + DCR Terraform; Azure Monitor alert rules; Grafana in GitOps |
| **P3 — Resilience** | DR | DR drill; Velero; documented RTO/RPO |
| **P4 — Supply chain** | Advanced | Image signing, SBOM, blocking Sonar gate |

---

## 11. What Dev Proves vs What Prod Adds

**Dev proves (implemented and demonstrated):**

- Private AKS platform provisioned via Terraform modules  
- Three CI/CD pipelines with security gates  
- GitOps delivery with immutable SHA tags  
- OIDC passwordless CI to private ACR  
- Separation of duties (CI does not deploy to cluster)  
- Multi-env tfvars and DR settings codified  

**Prod adds (this document):**

- Isolated prod state and hardened tfvars applied to live subscription  
- Full GitOps manifest parity with hardened `k8s/` reference  
- Central ops VM visibility (AMA + DCR) and production alerting  
- Governance: approvals, PIM, runbooks, DR drills, signing, retention  

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE_AND_INTERVIEW_PRESENTATION.md](ARCHITECTURE_AND_INTERVIEW_PRESENTATION.md) | End-to-end architecture and presentation |
| [infra/terraform/envs/README.md](../infra/terraform/envs/README.md) | Multi-environment Terraform workflow |
| [envs/prod/terraform.tfvars.example](../infra/terraform/envs/prod/terraform.tfvars.example) | Prod parameter baseline |
| [PRODUCTION_CHECKLIST.md](../PRODUCTION_CHECKLIST.md) | Pre-deploy verification checklist |
| [ADR-ACR-private-build-strategy.md](ADR-ACR-private-build-strategy.md) | Private ACR / self-hosted runner decision |
| [GITOPS_ARCHITECTURE.md](../GITOPS_ARCHITECTURE.md) | GitOps principles |

---

## Interview one-liner

> “Dev validates the full pattern — private Azure platform, three pipelines, GitOps, OIDC. Production is the same architecture with **isolated state, hardened tfvars, AMA on the ops VM, GitHub Environment approvals, full GitOps manifests, geo-replicated ACR, and operational runbooks** — all codified or documented; prod is an apply and governance layer away, not a redesign.”

---

*Last updated: June 2026*
