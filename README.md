# Lanuguage Tutor ChatBot

An AI-powered chatbot with robust error handling, and full-stack observability.

This project refactored my containerized application, SpanishTutor, to run on Kubernetes using Helm. By transitioning to Helm-based deployments, the app now benefits from version-controlled, reproducible, and environment-specific configurations — enabling easier scaling, streamlined updates, and more reliable infrastructure management across development and production environments.

![Python](https://img.shields.io/badge/python-3.10%2B-blue)

---

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Features](#features)
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

- **Gradio UI**: Chat-style web interface for learners.
- **FastAPI Backend**: Processes chat messages, handles errors, and exposes Prometheus metrics.
- **Ollama/OpenAI-Compatible LLM**: Local or remote LLM inference for cost-effective, private tutoring.
- **Prometheus & Grafana**: Real-time metrics, dashboards, and alerting.
- **Kubernetes (Kind)**: Local Kubernetes cluster for development and testing.

---

## Features

- Real-time English translation
- Robust error handling with custom exceptions and HTTP status codes
- Automatic retry logic for transient LLM/model failures
- Prometheus metrics for chat usage, latency, error types, and HTTP status codes
- Pre-built Grafana dashboards for usage, performance, and reliability
- Comprehensive test suite for core logic, API, and UI

---


##  Quick Start (Recommended)

### 1. Set up your environment variables
Create a `.env` file in the project root:
```bash
echo "LLM_API_KEY=your-api-key" > .env
echo "LLM_BASE_URL=your-llm-base-url" >> .env
echo "API_URL=http://chatbot-api:8000/chat" >> .env
```

### 2. Build and load the Docker image
```bash
make docker-build
```

### 3. Start your local Kubernetes cluster (Kind)
```bash
make kind-setup
```

### 4. Load the Docker image into Kind
```bash
kind load docker-image chatbot:latest
```

### 5. Generate Helm values file from your .env
```bash
make envsubst-values
```

### 6. Install (or upgrade) the Helm chart
```bash
make helm-install
# If already installed, use:
make helm-upgrade
```

### 7. Restart all services (if needed)
```bash
make restart-services
```

### 8. Port forward to access all services. 
####   You may need to kill ports allready in use (lsof -i :8000 -i :7860 -i :9090 -i :3000) and then kill -9 pid
```bash
make port-forward
```

### 10. To re-deploy a code change
```bash
make stop-ports
make docker-build
kind load docker-image chatbot:latest
make restart-services
make port-forward
```

### 10. Access the app and monitoring
- UI:  http://localhost:7860
- API: http://localhost:8000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

**Note:** If Grafana shows no metrics, ensure the data source is properly configured to connect to `chatbot-prometheus:9090`.
**Note:** All resources are deployed in the `chatbot` namespace. All Makefile commands use this namespace by default.

---

## Localhost Access & Port Forwarding

All services run inside the Kubernetes cluster but are accessible via `localhost` through port-forwarding. This allows you to interact with the application using your local web browser while maintaining the benefits of containerized deployment.

### **Available Localhost Endpoints**

| Service       | Localhost URL                    | Description                           | Default Credentials |
|-------------- |----------------------------------|---------------------------------------|-------------------  |
| **UI**        | http://localhost:7860            | Main chatbot interface                | None required       |
| **API**       | http://localhost:8000            | FastAPI backend (for direct testing)  | None required       |
| **Prometheus**| http://localhost:9090            | Metrics and monitoring                | None required       |
| **Grafana**   | http://localhost:3000            | Dashboards and visualization          | admin/admin         |

### **How Port Forwarding Works**

Port forwarding creates a tunnel between your local machine and the Kubernetes services:

**Use Makefile to forward all services at once:**
```bash
make port-forward
```

### **Service Communication Flow**

```
Your Browser → localhost:7860 → chatbot-ui (K8s) → chatbot-api (K8s) → LLM
```

- **UI to API**: Uses in-cluster DNS (`chatbot-api:8000`)
- **Browser to UI**: Uses port-forward (`localhost:7860`)
- **API to LLM**: Uses your configured `LLM_BASE_URL`


### **Testing the Setup**

1. **UI Interface:**
   - Open http://localhost:7860
   - Select your language
   - Start chatting with the bot

2. **API Direct Testing:**
   ```bash
   curl -X POST http://localhost:8000/chat \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello", "history": []}'
   ```

3. **Health Check:**
   ```bash
   curl http://localhost:8000/health
   ```

4. **Metrics:**
   - View Prometheus metrics: http://localhost:9090
   - View Grafana dashboards: http://localhost:3000

5. **Tests:**
```bash
make test && make test-cov:
```


### **Accessing Grafana Dashboards**

1. **Start Grafana port-forwarding:**
   ```bash
   kubectl port-forward svc/chatbot-grafana 3000:3000 -n chatbot
   ```

2. **Open Grafana:**
   - URL: http://localhost:3000
   - Username: `admin`
   - Password: `admin`

3. **Available Dashboards:**
   - **ChatBot Usage & Performance**: Real-time request rates, latency, and chat metrics
   - **ChatBot Reliability**: Error rates, system health, and availability metrics

4. **Dashboard Features:**
   - **Request Rate**: Number of chat requests per minute
   - **Response Latency**: Average response times
   - **Error Tracking**: HTTP status codes and error types
   - **System Health**: Pod status and resource utilization

5. **If no data appears:**
   ```bash
   # Verify Prometheus is running
   kubectl get pods -n chatbot | grep prometheus
   
   # Check Grafana data source configuration
   kubectl get configmap grafana-ds -n chatbot -o yaml
   ```
   - In Grafana: Go to Configuration → Data Sources → Prometheus
   - Ensure URL is: `http://chatbot-prometheus:9090`
   - Test the connection

### **Troubleshooting Port Forwarding**

#### **Port Already in Use**
```bash
make stop-ports
```

#### **Services Not Accessible**
```bash
# Check if services exist
kubectl get svc -n chatbot

# Check if pods are running
kubectl get pods -n chatbot

# Check service endpoints
kubectl get endpoints -n chatbot
```

#### **Connection Refused**
```bash
# Verify port-forward is running
ps aux | grep "port-forward"

# Restart port-forwarding
make port-forward
```

#### **UI Can't Connect to API**
- Ensure both UI and API are port-forwarded
- Check that `API_URL=http://chatbot-api:8000/chat` in your `.env`
- Verify both services are in the same namespace (`chatbot`)

## How to Restart Services

To restart all deployments (API, UI, Prometheus, Grafana) in the namespace:
```bash
make restart-services
```

## How to Get Everything Running

1. Ensure your `.env` is correct and loaded.
2. Build and load the Docker image: `make docker-build`
3. Start Kind: `make kind-setup`
4. Load the image into Kind: `kind load docker-image chatbot:latest`
5. Generate values: `make envsubst-values`
6. Install/upgrade Helm: `make helm-install` or `make helm-upgrade`
7. Restart services if needed: `make restart-services`
8. Port forward: `make port-forward` (may need to kill ports in use first)
9. Open the UI, API, Prometheus, and Grafana in your browser.

##  Prerequisites

### For Local Development
- Docker
- Python 3.10+
- LLM API credentials (OpenAI, Anthropic, etc. or if using locally)

### For Kubernetes Deployment
- kubectl
- Helm
- Kind (for local testing)

## Development

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


## Monitoring & Observability

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

## API Endpoints

### Health Check
```bash
GET /health
```

### Chat Endpoint
```bash
POST /chat
{
  "message": "Hola como esta?",
  "history": [["user", "Hola"], ["assistant", "Como te llama?"]]
}
```

### Metrics
```bash
GET /metrics
```

##  Testing

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
pytest tests/ --cov=chatbot --cov-report=html
```

##  Security

- API keys and passwords - TODO Will be stored in Kubernetes secrets
- Environment variable configuration
- Health checks and readiness probes
- Resource limits and requests

##  Scaling

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
   make status
   make port-forward
   ```

2. **Pod not starting**
   ```bash
   make logs
   make logs-ui
kubectl describe pod -l app=chatbot-api -n chatbot
   ```

3. **Image not found**
   ```bash
   kind load docker-image chatbot:latest
   ```

4. **Grafana shows no metrics**
   ```bash
   # Check if Prometheus data source is configured correctly
   kubectl get configmap grafana-ds -n chatbot -o yaml
   # Should show: url: http://chatbot-prometheus:9090
   ```

5. **Grafana not accessible**
   ```bash
   # Ensure port forwarding is running
   ps aux | grep "port-forward.*grafana"
   # Restart if needed
kubectl port-forward svc/chatbot-grafana 3000:3000 -n chatbot
   ```

### Useful Commands
```bash
# Check deployment status
make status

# View logs
make logs
make logs-ui

# Scale deployments
kubectl scale deployment chatbot-api --replicas=3 -n chatbot

# Check service endpoints
kubectl get endpoints -n chatbot

# Verify Grafana data source
kubectl get configmap grafana-ds -n chatbot -o yaml
```

##  Documentation

- [Kubernetes Deployment Guide](README-KUBERNETES.md) - Detailed K8s setup
- [Deployment Options](DEPLOYMENT.md) - TODO
- [Helm Chart Documentation](helm/chatbot/README.md) - Chart configuration

---

## Why This Project?

ChatBot explores adding observability, error handling, Docker, and Kubernetes for a project using LLMs.

---

