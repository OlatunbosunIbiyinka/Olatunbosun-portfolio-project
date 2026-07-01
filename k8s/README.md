# Cluster bootstrap manifests

**Not used for application deploys.** The portfolio app is deployed only via GitOps:

- `gitops/apps/portfolio-app/` — Argo CD source of truth (deployment, service, ingress, HPA, PDB, network policy)

Manifests in this folder are applied **once** during cluster setup from the ops VM (Cilium network policies, Hubble, Azure Policy examples). They are not part of the `portfolio-app` Argo CD application.

| File | Purpose |
|------|---------|
| `hubble-values.yaml`, `hubble-install.yaml` | Cilium Hubble observability |
| `networkpolicy-*.yaml` | Namespace/cluster network policy baselines |
| `azure-policy-constraints.yaml` | Gatekeeper constraint examples |
