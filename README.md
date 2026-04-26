# 🚀 Multi-Tenant Kubernetes Web Hosting Platform

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Kafka](https://img.shields.io/badge/Apache_Kafka-231F20?style=for-the-badge&logo=apache-kafka&logoColor=white)](https://kafka.apache.org/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)

This repository implements a production-ready, event-driven multi-tenant hosting platform. It is designed to host isolated tenant websites with automated CI/CD, dynamic scaling, and deep observability.

---

## 🏗️ System Architecture

![Platform Architecture Diagram](./architecture.png)

---


## 🛠 Project Objectives & Implementation

### 1. Multi-Tenant Deployment & Dynamic Domain Mapping
*   **Tenant Isolation**: Users (`user1`, `user2`, `user3`) are deployed in separate namespaces with dedicated **Resource Quotas** and **Network Policies**.
*   **Infrastructure**: Each tenant deployment includes healthy readiness/liveness probes and resource requests/limits.
*   **Dynamic Mapping**: Utilizes host-based routing via NGINX Ingress. New domains can be mapped to new namespaces dynamically by applying tenant-specific Ingress manifests without cluster-wide changes.
*   **TLS**: Automated TLS termination is configured for all ingress points.

### 2. CI/CD Pipeline with Rollback & Event Trigger
*   **Automated Workflow**: High-performance pipeline (GitHub Actions & Bash) that builds Docker images and deploys them across tenant namespaces.
*   **Self-Healing**: Implements `kubectl rollout status` checks. On detection of failing deployments (e.g., image errors), it automatically executes a `kubectl rollout undo`.
*   **Event Hooks**: Post-deployment, the pipeline triggers a `WebsiteCreated` event via the application's event-bus endpoint.

### 3. Scaling, Resource Optimization & Observability
*   **Autoscaling**: Configured **Horizontal Pod Autoscaling (HPA)** targeting 50% CPU usage, scaling per-tenant pods from 1 to 5.
*   **Availability**: `PodDisruptionBudgets` (PDB) are enforced to maintain minimum uptime during cluster updates.
*   **Observability Stack**: Integrated Prometheus and Grafana with a custom multi-tenant dashboard visualizing:
    *   Tenant CPU/Memory usage.
    *   Ingress Request rates.
    *   Kafka Consumer Lag.

### 4. Kafka Event-Driven Pipeline
*   **Infrastructure**: Single-node Kafka/Zookeeper cluster deployed within the environment.
*   **Producer**: Node.js app publishes real-time JSON events (`WebsiteCreated`) to the `deployment-events` topic.
*   **Automation**: Integrated event publishing into the CI/CD pipeline for automated notifications and downstream processing tracking.

---

## 📂 Repository Structure

*   `app/`: Node.js application source and Dockerfile.
*   `k8s/`: All Kubernetes manifests (Namespaces, Quotas, NetworkPolicies, Ingress, HPA/PDB).
*   `ci-cd/`: Pipeline scripts for local and automated deployment.
*   `monitoring/`: Prometheus/Grafana configurations and the Tenant Dashboard.
*   `scripts/`: Testing utilities for load simulation and rollback verification.

---

## 🚀 Getting Started

### 1. Initialization
```bash
minikube start --cpus 4 --memory 8192
minikube addons enable ingress metrics-server
```

### 2. Deployment
Apply infrastructure and run the deployment pipeline:
```bash
kubectl apply -f k8s/
eval $(minikube docker-env)
docker build -t yotta-app:latest ./app
./ci-cd/pipeline.sh
```

### 3. Monitoring Access
*   **Grafana**: `http://$(minikube ip):32000` (`admin`/`admin`)
*   **Dashboard**: Select the **"Multi-Tenant Platform Overview"** to see live resource and traffic data.

---

## ✅ Verification Proofs

*   **Website Access**: Map your hosts and visit `https://user1.example.com`.
*   **Scaling Demo**: Run `./scripts/load-test.sh` to trigger HPA scaling.
*   **Rollback Demo**: Run `./scripts/simulate-failure.sh` to see the automated fallback logic.
*   **Kafka Events**: `kubectl exec deployment/kafka -- kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic deployment-events`
