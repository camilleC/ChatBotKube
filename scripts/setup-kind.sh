#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}▶ Starting deployment to Kind...${NC}"

# Load environment variables from .env
if [ -f .env ]; then
  echo -e "${YELLOW} Loading environment variables from .env...${NC}"
  export $(grep -v '^#' .env | xargs)
else
  echo -e "${RED}❌ .env file not found. Please create one.${NC}"
  exit 1
fi

# Create namespace if it doesn't exist
echo -e "${YELLOW}🔧 Creating namespace 'chatbotkube' if needed...${NC}"
kubectl create namespace chatbotkube --dry-run=client -o yaml | kubectl apply -f -

# Create secret for LLM API key
if [ -z "${LLM_API_KEY:-}" ]; then
  echo -e "${RED}❌ LLM_API_KEY is not set. Please export it or include it in your .env file.${NC}"
  exit 1
fi

echo -e "${YELLOW} Creating secret for LLM API key...${NC}"
kubectl create secret generic chatbotkube-secrets \
  --from-literal=llm-api-key="$LLM_API_KEY" \
  -n chatbotkube \
  --dry-run=client -o yaml | kubectl apply -f -

# Generate values.yaml from envsubst
echo -e "${YELLOW} Generating /tmp/values.yaml from helm/chatbot/values.yaml...${NC}"
envsubst < helm/chatbot/values.yaml > /tmp/values.yaml

# Deploy with Helm
if helm status chatbot -n chatbot >/dev/null 2>&1; then
  echo -e "${YELLOW} Upgrading existing Helm release...${NC}"
  helm upgrade chatbot ./helm/chatbot \
    --namespace chatbot \
    -f /tmp/values.yaml
else
  echo -e "${YELLOW} Installing new Helm release...${NC}"
  helm install chatbot ./helm/chatbot \
    --namespace chatbot \
    -f /tmp/values.yaml
fi

# Wait for deployments to become available
echo -e "${YELLOW}⏳ Waiting for API and UI deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/chatbot-api -n chatbot
kubectl wait --for=condition=available --timeout=300s deployment/chatbot-ui -n chatbot

echo -e "${GREEN}✅ Tutor successfully deployed to Kind!${NC}"
