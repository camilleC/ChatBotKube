.PHONY: install test-cov test lint build clean docker-build kind-setup kind-deploy helm-install helm-upgrade helm-uninstall port-forward logs logs-ui status dev-setup envsubst-values restart-services prometheus-install grafana-install grafana-configmaps restart-local

# Python development
default: help

install:
	pip install -e .
	pip install pytest pytest-cov flake8 black isort

test-cov:
	pytest chatbot/tests/ --cov=chatbot --cov-report=html --cov-report=term

test:
	pytest chatbot/tests/

lint:
	flake8 chatbot/
	black --check chatbot/
	isort --check-only chatbot/

build:
	python setup.py build

clean:
	rm -rf build/ dist/ *.egg-info/ htmlcov/ .coverage
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete

# Docker

docker-build:
	docker build -t chatbot:latest .

# Kind cluster

kind-setup:
	@echo "Setting up Kind cluster..."
	kind create cluster --config kind-config.yaml
	kubectl wait --for=condition=Ready nodes --all --timeout=300s
	@echo "Kind cluster is ready!"

kind-deploy:
	@echo "Deploying to Kind cluster..."
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found. Please create it first."; \
		exit 1; \
	fi
	./scripts/setup-kind.sh

# Helm

NAMESPACE := chatbot

helm-install:
	helm install chatbot ./helm/chatbot -f /tmp/values.yaml -n $(NAMESPACE) --create-namespace

helm-upgrade:
	helm upgrade chatbot ./helm/chatbot -f /tmp/values.yaml -n $(NAMESPACE)

helm-uninstall:
	helm uninstall chatbot -n $(NAMESPACE)

# Dev helpers
dev-setup: install kind-setup
	@echo "Development environment is ready!"

# Restart all deployments in the namespace
restart-services:
	kubectl rollout restart deployment/chatbot-api -n $(NAMESPACE)
	kubectl rollout restart deployment/chatbot-ui -n $(NAMESPACE)
	kubectl rollout restart deployment/chatbot-prometheus -n $(NAMESPACE) || true
	kubectl rollout restart deployment/chatbot-grafana -n $(NAMESPACE) || true

# Restart locally while developing
restart-local:
	lsof -ti:8000 -ti:7860 -ti:9090 -ti:3000 | xargs kill -9 || true
	make restart-services
	make port-forward
# Port forwarding for all services
port-forward:
	@echo "⏳ Waiting for ChatBot pods to be ready..."
	kubectl wait --for=condition=ready pod -l app=chatbot-api -n $(NAMESPACE) --timeout=90s
	kubectl wait --for=condition=ready pod -l app=chatbot-ui -n $(NAMESPACE) --timeout=90s
	@echo "✅ API and UI pods are ready."
	@echo "🔍 Checking for Prometheus and Grafana pods..."
	kubectl wait --for=condition=ready pod -l app=chatbot-prometheus -n $(NAMESPACE) --timeout=90s || true
	kubectl wait --for=condition=ready pod -l app=chatbot-grafana -n $(NAMESPACE) --timeout=90s || true
	@echo "🚀 Starting port forwarding..."
	@echo "🔁 Port-forwarding API (localhost:8000)..."
	kubectl port-forward svc/chatbot-api 8000:8000 -n $(NAMESPACE) &
	@echo "🔁 Port-forwarding UI (localhost:7860)..."
	kubectl port-forward svc/chatbot-ui 7860:7860 -n $(NAMESPACE) &
	@echo "🔁 Port-forwarding Prometheus (localhost:9090)..."
	kubectl port-forward svc/chatbot-prometheus 9090:9090 -n $(NAMESPACE) &
	@echo "🔁 Port-forwarding Grafana (localhost:3000)..."
	kubectl port-forward svc/chatbot-grafana 3000:3000 -n $(NAMESPACE) &
	@echo "All port-forwards started."

logs:
	kubectl logs -f deployment/chatbot-api -n $(NAMESPACE)

logs-ui:
	kubectl logs -f deployment/chatbot-ui -n $(NAMESPACE)

status:
	kubectl get pods,svc -n $(NAMESPACE)

envsubst-values:
	@echo "Generating /tmp/values.yaml from helm/chatbot/values.yaml using .env values..."
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found."; \
		exit 1; \
	fi
	export $$(grep -v '^#' .env | xargs) && envsubst < helm/chatbot/values.yaml > /tmp/values.yaml

prometheus-install:
	@echo "📊 Installing Prometheus into $(NAMESPACE)..."
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install prometheus prometheus-community/prometheus \
		--namespace $(NAMESPACE) --create-namespace \
		--set server.service.type=ClusterIP \
		--set server.service.servicePort=9090 \
		--set alertmanager.enabled=true \
		--set pushgateway.enabled=true \
		--set kube-state-metrics.enabled=true \
		--set nodeExporter.enabled=true \
		--set server.retention=7d
	@echo "✅ Prometheus installed successfully!"

grafana-install:
	@echo "📊 Installing Grafana into $(NAMESPACE)..."
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade --install grafana grafana/grafana \
		--namespace $(NAMESPACE) --create-namespace \
		--set service.port=80 \
		--set service.targetPort=3000 \
		--set adminUser=admin \
		--set adminPassword=admin \
		--set sidecar.dashboards.enabled=true \
		--set sidecar.dashboards.label=grafana_dashboard \
		--set sidecar.datasources.enabled=true \
		--set sidecar.datasources.label=grafana_datasource
	@echo "✅ Grafana installed successfully!"

grafana-configmaps:
	@echo "Creating Grafana datasource ConfigMap..."
	kubectl -n $(NAMESPACE) create configmap grafana-ds --from-file=datasources.yaml=./grafana/provisioning/datasources/datasources.yaml --dry-run=client -o yaml | kubectl apply -f -
	kubectl label configmap grafana-ds grafana_datasource=1 -n $(NAMESPACE) --overwrite
	@echo "Creating Grafana dashboards provisioning ConfigMap..."
	kubectl -n $(NAMESPACE) create configmap grafana-dashboards-provisioning --from-file=dashboards.yaml=./grafana/provisioning/dashboards/dashboards.yaml --dry-run=client -o yaml | kubectl apply -f -
	@echo "Creating Grafana usage-performance dashboard ConfigMap..."
	kubectl -n $(NAMESPACE) create configmap grafana-dashboard-usage-performance --from-file=chatbot-usage-performance.json=./grafana/dashboards/chatbot-usage-performance.json --dry-run=client -o yaml | kubectl apply -f -
	kubectl label configmap grafana-dashboard-usage-performance grafana_dashboard=1 -n $(NAMESPACE) --overwrite
	@echo "Creating Grafana reliability dashboard ConfigMap..."
	kubectl -n $(NAMESPACE) create configmap grafana-dashboard-reliability --from-file=chatbot-reliability.json=./grafana/dashboards/chatbot-reliability.json --dry-run=client -o yaml | kubectl apply -f -
	kubectl label configmap grafana-dashboard-reliability grafana_dashboard=1 -n $(NAMESPACE) --overwrite
	@echo "✅ Grafana ConfigMaps created/updated."

help:
	@echo "Available targets:"
	@echo "  install         - Install Python dependencies"
	@echo "  test           - Run tests"
	@echo "  test-cov       - Run tests with coverage"
	@echo "  lint           - Run linters"
	@echo "  docker-build   - Build Docker image"
	@echo "  kind-setup     - Setup Kind cluster"
	@echo "  helm-install   - Install Helm chart"
	@echo "  helm-upgrade   - Upgrade Helm chart"
	@echo "  port-forward   - Forward ports for all services"
	@echo "  status         - Check deployment status"
	@echo "  logs           - View API logs"
	@echo "  logs-ui        - View UI logs"

