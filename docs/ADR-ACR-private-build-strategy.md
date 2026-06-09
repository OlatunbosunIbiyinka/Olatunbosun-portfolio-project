# ADR: ACR private network posture and in-VNet image builds

**Status:** Accepted  
**Date:** 2026-04-14  
**Scope:** Dev environment aligned with production-style controls; principles apply to higher environments.

## Context

This project uses **Azure Container Registry (ACR)** with a **private, least-exposure** posture (e.g. private endpoint, restricted or disabled public access). The Kubernetes cluster pulls images over paths consistent with that design.

Container **builds** must still land images in ACR. Different build locations have different network reachability:

- **Microsoft-hosted ACR Tasks** (`az acr build` using shared build agents) and **GitHub-hosted runners** reach the registry from the **public internet** unless the registry allows that path.
- A registry that is **private-only** at the data plane often returns **403 Forbidden** to those builders, which is expected—not a misconfiguration of credentials alone.

Separately, **application runtime** concerns (workload identity, Key Vault CSI, image name/tags, read-only root filesystem) must align with Terraform and Kubernetes manifests.

## Decision

1. **Treat private ACR as intentional.** Prefer **in-VNet** or **private-path** image publication over opening the registry broadly for convenience.

2. **Current pattern (dev / bootstrap):** Use an **operations VM inside the VNet** (same DNS/private endpoint path as other private Azure services) to run **`docker build`** and **`docker push`** after `az login` / ACR authentication. The VM acts as a **controlled build runner** with a clear trust boundary (who can SSH, which identity has `AcrPush`).

3. **Operational requirements for this pattern:**
   - **Docker** must run reliably on the runner (`docker.socket` + `docker.service`, user in `docker` group or equivalent).
   - **Image name and tag** in Kubernetes must match what is pushed (e.g. `ola-portfolio-app:latest` vs wrong repository name).
   - **Workload identity** must match Terraform outputs for both **ServiceAccount** and **SecretProviderClass** when using Key Vault CSI.

4. **Helm / GitOps (Argo CD):** Resolve charts by **explicit repository URL** in Terraform (`helm_release.repository`) so `terraform plan/apply` does not depend on a pre-warmed local Helm CLI cache on developer machines.

## Alternatives considered

| Option | Pros | Cons |
|--------|------|------|
| **A. In-VNet VM or self-hosted runner (chosen baseline)** | Matches private ACR; full control; “dev like prod” | You operate the runner (Docker health, patching, access). |
| **B. ACR Tasks with VNet-attached agent pool (Premium)** | Managed builds inside the network; no public ACR requirement for builders | Extra Azure surface to operate; Premium SKU considerations. |
| **C. Enable public ACR access + strict RBAC / firewall** | Easiest integration with GitHub-hosted runners and cloud `az acr build` | Larger attack surface; must compensate with IAM, Defender, network rules, no admin user. |

## Consequences

- **Positive:** Build and push paths stay consistent with a **private registry** story; fewer accidental dependencies on “the internet can always reach my registry.”
- **Negative:** CI/CD must be explicitly designed (self-hosted runner in VNet, or Option B/C) instead of assuming any hosted builder can push.
- **Risk to mitigate:** A single long-lived VM as a build host should be hardened (AAD SSH, JIT access, patching, least-privilege `AcrPush`, audit).

## Recommended evolution (production-grade)

1. **Short term:** Document and automate build steps on the **in-VNet runner** (scripted build/push, immutable tags, same pipeline checks as prod).
2. **Medium term:** Replace ad-hoc VM usage with a **self-hosted GitHub Actions runner** in the same VNet (same network properties, better automation and RBAC).
3. **Long term / scale:** Evaluate **ACR Tasks with a VNet-attached pool** if you want managed build capacity without broad public registry access.

## Related project artifacts

- `scripts/deploy.sh` — injects image and workload identity values from Terraform outputs.
- `k8s/deployment.yaml` — runtime security (e.g. read-only root with writable `emptyDir` for nginx) must match image behavior.
- `infra/terraform/modules/argocd/` — Argo CD Helm chart via explicit `repository` URL.

---

*This ADR records engineering intent; implementation details may change as Azure features and SKUs evolve.*
