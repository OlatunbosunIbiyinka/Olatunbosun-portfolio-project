#!/bin/bash
# Deprecated: application deploys are GitOps-only (Argo CD + ci-build-push.yml).
# Use: push to main → CI builds image → updates gitops/apps/portfolio-app/deployment.yaml → Argo CD syncs.
#
# This script remains for documentation compatibility only.

set -e

echo "Application deploys use GitOps — not kubectl apply from k8s/."
echo ""
echo "  1. Push app changes to main"
echo "  2. CI (ci-build-push.yml) builds, scans, and pushes the image to ACR"
echo "  3. CI updates gitops/apps/portfolio-app/deployment.yaml with the commit SHA"
echo "  4. Argo CD syncs gitops/apps/portfolio-app/ to the portfolio-app namespace"
echo ""
echo "See GITOPS_ARCHITECTURE.md and gitops/README.md"
exit 1
