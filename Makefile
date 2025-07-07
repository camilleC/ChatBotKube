.PHONY: install test lint build clean docker-build kind-setup kind-deploy helm-install helm-upgrade helm-uninstall port-forward logs logs-ui status dev-setup


#tldr:
# make docker-build        # Build the Docker image again
# make kind-setup          # (If you deleted the cluster, or want to ensure it's running)
# make kind-deploy         # Deploy to Kind (if you have a setup-kind.sh script)
# make helm-install        # Or helm-upgrade if already installed
# make port-forward        # To access the services

# Python development
default: help

install:
	pip install -e .
	pip install pytest pytest-cov flake8 black isort

test:
	pytest tests/ --cov=spanishtutor --cov-report=html --cov-report=term

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
	@if [ -z "$(LLM_API_KEY)" ]; then \
		echo "Error: LLM_API_KEY environment variable is required"; \
		exit 1; \
	fi
	./scripts/setup-kind.sh

# Helm

helm-install:
	@echo "Installing Helm chart..."
	helm install spanish-tutor ./helm/spanish-tutor \
		--set image.repository=spanish-tutor \
		--set image.tag=latest \
		--set config.llm.apiKey="$(LLM_API_KEY)" \
		--set config.llm.baseUrl="$(LLM_BASE_URL)"

helm-upgrade:
	@echo "Upgrading Helm chart..."
	helm upgrade spanish-tutor ./helm/spanish-tutor \
		--set image.repository=spanish-tutor \
		--set image.tag=latest \
		--set config.llm.apiKey="$(LLM_API_KEY)" \
		--set config.llm.baseUrl="$(LLM_BASE_URL)"

helm-uninstall:
	@echo "Uninstalling Helm chart..."
	helm uninstall spanish-tutor

# Development helpers
dev-setup: install kind-setup
	@echo "Development environment is ready!"

port-forward:
	@echo "Setting up port forwarding..."
	kubectl port-forward svc/spanish-tutor-api 8000:8000 &
	kubectl port-forward svc/spanish-tutor-ui 7860:7860 &
	kubectl port-forward svc/spanish-tutor-prometheus 9090:9090 &
	kubectl port-forward svc/spanish-tutor-grafana 3000:3000 &
	@echo "Port forwarding is active:"
	@echo "  API: http://localhost:8000"
	@echo "  UI: http://localhost:7860"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana: http://localhost:3000 (admin/admin)"

logs:
	kubectl logs -f deployment/spanish-tutor-api

logs-ui:
	kubectl logs -f deployment/spanish-tutor-ui

status:
	kubectl get pods,svc 