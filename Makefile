.PHONY: install test-cov test lint build clean docker-build kind-setup kind-deploy helm-install helm-upgrade helm-uninstall port-forward logs logs-ui status dev-setup envsubst-values restart-services

# Python development
default: help

install:
	pip install -e .
	pip install pytest pytest-cov flake8 black isort

test-cov:
	pytest spanishtutor/tests/ --cov=spanishtutor --cov-report=html --cov-report=term

test:
	pytest spanishtutor/tests/

lint:
	flake8 spanishtutor/
	black --check spanishtutor/
	isort --check-only spanishtutor/

build:
	python setup.py build

clean:
	rm -rf build/ dist/ *.egg-info/ htmlcov/ .coverage
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete

# Docker

docker-build:
	docker build -t spanish-tutor:latest .

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

helm-install:
	helm install spanish-tutor ./helm/spanish-tutor -f /tmp/values.yaml -n spanish-tutor --create-namespace

helm-upgrade:
	helm upgrade spanish-tutor ./helm/spanish-tutor -f /tmp/values.yaml -n spanish-tutor

helm-uninstall:
	helm uninstall spanish-tutor -n spanish-tutor

# Dev helpers
dev-setup: install kind-setup
	@echo "Development environment is ready!"

# Restart all deployments in the namespace
restart-services:
	kubectl rollout restart deployment/spanish-tutor-api -n spanish-tutor
	kubectl rollout restart deployment/spanish-tutor-ui -n spanish-tutor
	kubectl rollout restart deployment/spanish-tutor-prometheus -n spanish-tutor || true
	kubectl rollout restart deployment/grafana -n spanish-tutor || true

# Port forwarding for all services
port-forward:
	@echo "⏳ Waiting for Spanish Tutor pods to be ready..."
	kubectl wait --for=condition=ready pod -l app=spanish-tutor-api -n spanish-tutor --timeout=90s
	kubectl wait --for=condition=ready pod -l app=spanish-tutor-ui -n spanish-tutor --timeout=90s
	@echo "✅ API and UI pods are ready."
	@echo "🔍 Checking for Prometheus and Grafana pods..."
	kubectl wait --for=condition=ready pod -l app=spanish-tutor-prometheus -n spanish-tutor --timeout=90s || true
	kubectl wait --for=condition=ready pod -l app=grafana -n spanish-tutor --timeout=90s || true
	@echo "🚀 Starting port forwarding..."
	@echo "🔁 Port-forwarding API (localhost:8000)..."
	kubectl port-forward svc/spanish-tutor-api 8000:8000 -n spanish-tutor &
	@echo "🔁 Port-forwarding UI (localhost:7860)..."
	kubectl port-forward svc/spanish-tutor-ui 7860:7860 -n spanish-tutor &
	@echo "🔁 Port-forwarding Prometheus (localhost:9090)..."
	kubectl port-forward svc/spanish-tutor-prometheus 9090:9090 -n spanish-tutor &
	@echo "🔁 Port-forwarding Grafana (localhost:3000)..."
	kubectl port-forward svc/spanish-tutor-grafana 3000:3000 -n spanish-tutor &
	@echo "All port-forwards started."

logs:
	kubectl logs -f deployment/spanish-tutor-api -n spanish-tutor

logs-ui:
	kubectl logs -f deployment/spanish-tutor-ui -n spanish-tutor

status:
	kubectl get pods,svc -n spanish-tutor

envsubst-values:
	@echo "Generating /tmp/values.yaml from helm/spanish-tutor/values.yaml using .env values..."
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found."; \
		exit 1; \
	fi
	export $$(grep -v '^#' .env | xargs) && envsubst < helm/spanish-tutor/values.yaml > /tmp/values.yaml
