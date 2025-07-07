# 🇪🇸 Spanish Tutor

An AI-powered chatbot with adaptive conversation, robust error handling, and full-stack observability.

![Python](https://img.shields.io/badge/python-3.10%2B-blue)

---

## 📚 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Features](#features)
- [Demo](#demo)
- [Quick Start](#quick-start)
- [API Endpoints](#api-endpoints)
- [Observability](#observability)
- [Error Handling & Reliability](#error-handling--reliability)
- [Testing](#testing)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [Acknowledgments](#acknowledgments)
- [Why This Project?](#why-this-project)

---

## Architecture Overview

- **Gradio UI**: Modern, chat-style web interface for learners.
- **FastAPI Backend**: Processes chat messages, handles errors, and exposes Prometheus metrics.
- **Ollama/OpenAI-Compatible LLM**: Local or remote LLM inference for cost-effective, private tutoring.
- **Prometheus & Grafana**: Real-time metrics, dashboards, and alerting.
- **Kubernetes (Kind)**: Local Kubernetes cluster for development and testing.

---

## Features

- Adaptive conversation practice (A1–C2 levels)
- Real-time English translation
- Robust error handling with custom exceptions and HTTP status codes
- Automatic retry logic for transient LLM/model failures
- Prometheus metrics for chat usage, latency, error types, and HTTP status codes
- Pre-built Grafana dashboards for usage, performance, and reliability
- Comprehensive test suite for core logic, API, and UI

---

## Demo


![Chat Demo](demo.gif)

---

##  Quick Start

### Local Kubernetes (Kind)

1. **Set your API credentials:**
   - Create a `.env` file in the project root:
     ```bash
     echo "LLM_API_KEY=your-api-key" > .env
     echo "LLM_BASE_URL=your-llm-base-url" >> .env
     set -a; source .env; set +a
     ```
2. **Build and load the Docker image:**
   ```bash
   docker build -t spanish-tutor:latest .
   kind create cluster --config kind-config.yaml
   kind load docker-image spanish-tutor:latest
   ```
3. **Install with Helm:**
   ```bash
   helm install spanish-tutor ./helm/spanish-tutor \
     --set image.repository=spanish-tutor \
     --set image.tag=latest \
     --set config.llm.apiKey="$LLM_API_KEY" \
     --set config.llm.baseUrl="$LLM_BASE_URL"
   ```
4. **Port forward to access services:**
   ```bash
   kubectl port-forward svc/spanish-tutor-api 8000:8000 &
   kubectl port-forward svc/spanish-tutor-ui 7860:7860 &
   kubectl port-forward svc/spanish-tutor-prometheus 9090:9090 &
   kubectl port-forward svc/spanish-tutor-grafana 3000:3000 &
   ```
5. **Access the app:**
   - API: http://localhost:8000
   - UI:  http://localhost:7860
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (admin/admin)

---

## 📋 Prerequisites

### For Local Development
- Docker and Docker Compose
- Python 3.10+
- LLM API credentials (OpenAI, Anthropic, etc.)

### For Kubernetes Deployment
- kubectl
- Helm
- Kind (for local testing)
- Terraform (for AWS)
- AWS CLI (for AWS deployment)

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Gradio UI     │    │   FastAPI API   │    │   Prometheus    │
│   (Port 7860)   │◄──►│   (Port 8000)   │◄──►│   (Port 9090)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   LLM Service   │    │     Grafana     │
                       │  (External)     │    │   (Port 3000)   │
                       └─────────────────┘    └─────────────────┘
```

## 🛠️ Development

### Install Dependencies
```bash
make install
```

### Run Tests
```bash
make test
```

### Run Linters
```bash
make lint
```

### Build Docker Image
```bash
make docker-build
```

## 📊 Monitoring & Observability

### Prometheus Metrics
- HTTP request metrics with status codes
- Chat request rates and latency
- Error tracking by type
- Custom application metrics

### Grafana Dashboards
- Real-time request rates and latency
- Error rates and types
- Resource utilization
- Custom application dashboards



## 📁 Project Structure

```
SpansishTutor/
├── spanishtutor/           # Application source code
│   ├── src/
│   │   ├── api/           # FastAPI application
│   │   ├── core/          # Core business logic
│   │   └── main.py        # Gradio UI entry point
│   └── tests/             # Test suite
├── helm/                  # Kubernetes Helm charts
├── grafana/               # Grafana dashboards
├── scripts/               # Deployment scripts
├── Makefile               # Development commands
└── README-*.md           # Detailed documentation
```

## 🔍 API Endpoints

### Health Check
```bash
GET /health
```

### Chat Endpoint
```bash
POST /chat
{
  "message": "Hello, how are you?",
  "history": [["user", "Hi"], ["assistant", "Hello!"]]
}
```

### Metrics
```bash
GET /metrics
```

## 🧪 Testing

### Run All Tests
```bash
make test
```

### Run Specific Tests
```bash
pytest tests/test_api.py -v
pytest tests/test_endpoints.py -v
```

### Test Coverage
```bash
pytest tests/ --cov=spanishtutor --cov-report=html
```

## 🔒 Security

- API keys stored in Kubernetes secrets
- Environment variable configuration
- Health checks and readiness probes
- Resource limits and requests

## 📈 Scaling

### Horizontal Scaling
- Kubernetes Horizontal Pod Autoscaling (HPA)
- Multiple API replicas
- Load balancer distribution

### Vertical Scaling
- Configurable resource limits
- CPU and memory optimization
- Performance monitoring

## 🛠️ Troubleshooting

### Common Issues

1. **Service not accessible**
   ```bash
   # Check service status
   kubectl get svc -n spanish-tutor
   
   # Port forward for debugging
   kubectl port-forward svc/spanish-tutor-api 8000:8000 -n spanish-tutor
   ```

2. **Pod not starting**
   ```bash
   # Check pod logs
   kubectl logs deployment/spanish-tutor-api -n spanish-tutor
   
   # Check pod events
   kubectl describe pod -l app.kubernetes.io/name=spanish-tutor -n spanish-tutor
   ```

3. **Image not found**
   ```bash
   # For Kind
   kind load docker-image spanish-tutor:latest
   
   # For EKS
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REPO_URL
   ```

### Useful Commands
```bash
# Check deployment status
make status

# View logs
make logs
make logs-ui

# Scale deployments
kubectl scale deployment spanish-tutor-api --replicas=3 -n spanish-tutor
```

## 📚 Documentation

- [Kubernetes Deployment Guide](README-KUBERNETES.md) - Detailed K8s setup
- [Deployment Options](DEPLOYMENT.md) - Complete deployment comparison
- [Terraform Documentation](terraform/README.md) - Infrastructure setup
- [Helm Chart Documentation](helm/spanish-tutor/README.md) - Chart configuration


---

## Why This Project?

SpanishTutor explores adding obervability, error handeling, docker and kubernetes for a project using llms.

# Spanish Tutor - Local Kubernetes Deployment (Kind + Monitoring)

This guide describes how to deploy the Spanish Tutor application on Kubernetes using Kind for local development, with Prometheus and Grafana for monitoring.

## Prerequisites
- Docker
- Kind
- kubectl
- Helm

## Local Development (Kind)
1. Create a `.env` file and load it:
   ```bash
   echo "LLM_API_KEY=your-api-key" > .env
   echo "LLM_BASE_URL=your-llm-base-url" >> .env
   set -a; source .env; set +a
   ```
2. Build and load Docker image:
   ```bash
   docker build -t spanish-tutor:latest .
   kind create cluster --config kind-config.yaml
   kind load docker-image spanish-tutor:latest
   ```
3. Install with Helm:
   ```bash
   helm install spanish-tutor ./helm/spanish-tutor \
     --set image.repository=spanish-tutor \
     --set image.tag=latest \
     --set config.llm.apiKey="$LLM_API_KEY" \
     --set config.llm.baseUrl="$LLM_BASE_URL"
   ```
4. Port forward:
   ```bash
   kubectl port-forward svc/spanish-tutor-api 8000:8000 &
   kubectl port-forward svc/spanish-tutor-ui 7860:7860 &
   kubectl port-forward svc/spanish-tutor-prometheus 9090:9090 &
   kubectl port-forward svc/spanish-tutor-grafana 3000:3000 &
   ```
5. Access:
   - API: http://localhost:8000
   - UI:  http://localhost:7860
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (admin/admin)

---

**This setup is intentionally minimal, but includes Prometheus and Grafana for monitoring.**

