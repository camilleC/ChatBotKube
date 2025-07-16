# chatBotKube Helm Chart

This directory contains the Helm chart for deploying the chatBotKube application and its monitoring stack (Prometheus and Grafana) on Kubernetes.

**Why Helm?**
- Helm enables reproducible, version-controlled deployments of complex applications on Kubernetes.
- It simplifies configuration management and upgrades for all components (API, UI, Prometheus, Grafana) as a single unit.
- Using Helm ensures that local development and future production deployments are consistent and easy to manage.
- NEXT STEPS: In the future these helm charts will be used along with terraform to create cloud deployments.

For all deployment and usage instructions, see the main project `README.md` in the root directory. 