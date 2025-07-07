#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Spanish Tutor on Kind cluster...${NC}"

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${RED}Kind is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Kubectl is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Helm is not installed. Please install it first.${NC}"
    exit 1
fi

# Create Kind cluster
echo -e "${YELLOW}Creating Kind cluster...${NC}"
kind create cluster --config kind-config.yaml

# Wait for cluster to be ready
echo -e "${YELLOW}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Build and load Docker image
echo -e "${YELLOW}Building and loading Docker image...${NC}"
docker build -t spanish-tutor:latest .
kind load docker-image spanish-tutor:latest

# Create namespace
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl create namespace spanish-tutor --dry-run=client -o yaml | kubectl apply -f -

# Create secret for LLM API key (you'll need to set this)
echo -e "${YELLOW}Creating secrets...${NC}"
if [ -z "$LLM_API_KEY" ]; then
    echo -e "${YELLOW}Warning: LLM_API_KEY environment variable not set. You'll need to create the secret manually.${NC}"
    echo -e "${YELLOW}Run: kubectl create secret generic spanish-tutor-secrets --from-literal=llm-api-key=your-api-key -n spanish-tutor${NC}"
else
    kubectl create secret generic spanish-tutor-secrets \
        --from-literal=llm-api-key="$LLM_API_KEY" \
        -n spanish-tutor \
        --dry-run=client -o yaml | kubectl apply -f -
fi

# Deploy with Helm
echo -e "${YELLOW}Deploying with Helm...${NC}"
helm install spanish-tutor ./helm/spanish-tutor \
    --namespace spanish-tutor \
    --set image.repository=spanish-tutor \
    --set image.tag=latest \
    --set config.llm.apiKey="$LLM_API_KEY" \
    --set config.llm.baseUrl="$LLM_BASE_URL"

# Wait for deployments to be ready
echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/spanish-tutor-api -n spanish-tutor
kubectl wait --for=condition=available --timeout=300s deployment/spanish-tutor-ui -n spanish-tutor

# Get service URLs
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}Services available at:${NC}"
echo -e "${YELLOW}API:${NC} http://localhost:8000"
echo -e "${YELLOW}UI:${NC} http://localhost:7860"
echo -e "${YELLOW}Prometheus:${NC} http://localhost:9090"
echo -e "${YELLOW}Grafana:${NC} http://localhost:3000 (admin/admin)"

# Show pod status
echo -e "${YELLOW}Pod status:${NC}"
kubectl get pods -n spanish-tutor

# Show services
echo -e "${YELLOW}Services:${NC}"
kubectl get svc -n spanish-tutor 