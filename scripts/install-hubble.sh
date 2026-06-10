#!/bin/bash
# Enterprise-grade: Cilium Hubble Installation Script
# This script installs Hubble for network observability with best practices

set -e

echo "🚀 Installing Cilium Hubble for network observability..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ helm is not installed. Please install helm first.${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Get cluster name and resource group from environment or ask user
CLUSTER_NAME="${AKS_CLUSTER_NAME:-ola-aks-dev}"
RESOURCE_GROUP="${AKS_RESOURCE_GROUP:-ola-rg-dev}"

echo -e "${YELLOW}📋 Cluster: ${CLUSTER_NAME}${NC}"
echo -e "${YELLOW}📋 Resource Group: ${RESOURCE_GROUP}${NC}"

# Step 1: Add Cilium Helm repository
echo ""
echo -e "${YELLOW}📦 Adding Cilium Helm repository...${NC}"
helm repo add cilium https://helm.cilium.io/ || echo "Repository already exists"
helm repo update

# Step 2: Check if Cilium is already installed
echo ""
echo -e "${YELLOW}🔍 Checking if Cilium is installed...${NC}"
if kubectl get daemonset -n kube-system cilium &> /dev/null; then
    echo -e "${GREEN}✅ Cilium is already installed${NC}"
else
    echo -e "${RED}❌ Cilium is not installed. Please ensure Cilium network policy is enabled in AKS.${NC}"
    echo -e "${YELLOW}💡 Cilium should be automatically installed when network_policy = 'cilium' is set in AKS.${NC}"
    exit 1
fi

# Step 3: Check Cilium version
CILIUM_VERSION=$(kubectl get daemonset -n kube-system cilium -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d':' -f2)
echo -e "${GREEN}✅ Cilium version: ${CILIUM_VERSION}${NC}"

# Step 4: Install Hubble using Helm
echo ""
echo -e "${YELLOW}📦 Installing Hubble...${NC}"

# Use the values file if it exists, otherwise use inline values
VALUES_FILE="k8s/hubble-values.yaml"
if [ -f "$VALUES_FILE" ]; then
    echo -e "${GREEN}✅ Using values file: ${VALUES_FILE}${NC}"
    helm upgrade --install hubble \
        --namespace kube-system \
        --create-namespace \
        -f "$VALUES_FILE" \
        cilium/cilium
else
    echo -e "${YELLOW}⚠️  Values file not found, using default values${NC}"
    helm upgrade --install hubble \
        --namespace kube-system \
        --create-namespace \
        --set hubble.relay.enabled=true \
        --set hubble.ui.enabled=true \
        --set hubble.metrics.enabled=true \
        --set hubble.tls.auto.method=cronJob \
        --set hubble.relay.service.type=LoadBalancer \
        --set hubble.ui.service.type=LoadBalancer \
        --set prometheus.enabled=true \
        --set operator.prometheus.enabled=true \
        cilium/cilium
fi

# Step 5: Wait for Hubble to be ready
echo ""
echo -e "${YELLOW}⏳ Waiting for Hubble to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/hubble-relay -n kube-system || true
kubectl wait --for=condition=available --timeout=300s deployment/hubble-ui -n kube-system || true

# Step 6: Get Hubble UI service details
echo ""
echo -e "${GREEN}✅ Hubble installation complete!${NC}"
echo ""
echo -e "${YELLOW}📊 Hubble Services:${NC}"
kubectl get svc -n kube-system | grep hubble

echo ""
echo -e "${YELLOW}🔗 Access Hubble UI:${NC}"
HUBBLE_UI_IP=$(kubectl get svc -n kube-system hubble-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
if [ "$HUBBLE_UI_IP" != "Pending..." ] && [ -n "$HUBBLE_UI_IP" ]; then
    echo -e "${GREEN}   http://${HUBBLE_UI_IP}${NC}"
else
    echo -e "${YELLOW}   LoadBalancer IP is still being provisioned. Check with:${NC}"
    echo -e "${YELLOW}   kubectl get svc -n kube-system hubble-ui${NC}"
fi

echo ""
echo -e "${YELLOW}🔗 Access Hubble Relay API:${NC}"
HUBBLE_RELAY_IP=$(kubectl get svc -n kube-system hubble-relay -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
if [ "$HUBBLE_RELAY_IP" != "Pending..." ] && [ -n "$HUBBLE_RELAY_IP" ]; then
    echo -e "${GREEN}   hubble-relay: ${HUBBLE_RELAY_IP}:4245${NC}"
else
    echo -e "${YELLOW}   LoadBalancer IP is still being provisioned. Check with:${NC}"
    echo -e "${YELLOW}   kubectl get svc -n kube-system hubble-relay${NC}"
fi

echo ""
echo -e "${YELLOW}📊 Verify Hubble pods:${NC}"
kubectl get pods -n kube-system | grep hubble

echo ""
echo -e "${GREEN}✅ Hubble installation and configuration complete!${NC}"
echo ""
echo -e "${YELLOW}📚 Next steps:${NC}"
echo -e "   1. Access Hubble UI to view network flows"
echo -e "   2. Configure Prometheus to scrape Hubble metrics"
echo -e "   3. Set up alerts based on Hubble metrics"
echo -e "   4. Review network policies using Hubble observability"
