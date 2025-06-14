# OpenCRVS Kubernetes NodePort Deployment

This project provides a Kubernetes-based deployment for OpenCRVS, with services exposed via NodePort for easy external access, especially useful for development and testing environments.

## Key Features

- **Self-Signed Certificates:**
  - Uses `openssl` to generate self-signed certificates for secure communication between services.
  - Acts as a lightweight cert-manager for local and test environments.

- **NodePort Exposure:**
  - Some microservices are exposed using Kubernetes NodePort, making them accessible from outside the cluster (e.g., your local machine or test network).
  - This approach is based on the service exposure pattern in `docker-compose.dev.yaml`, ensuring parity between Docker Compose and Kubernetes setups for development.

## Deployment Overview

The main deployment script is [`deploy.sh`](./deploy.sh), which automates the following steps:

1. **Namespace Management:**
   - Ensures the `opencrvs` namespace exists in your Kubernetes cluster.

2. **Certificate Generation:**
   - Checks for existing keys in `.secrets/`.
   - If not present, generates a new RSA private key and corresponding public key using `openssl`.

3. **Secrets and ConfigMaps:**
   - Creates Kubernetes secrets for the generated keys.
   - Sets up configmaps for infrastructure components using files from `infrastructureConfig/`.

4. **Infrastructure Deployment:**
   - Deploys core infrastructure services:
     - MongoDB
     - Elasticsearch
     - InfluxDB
     - Minio
     - Redis
     - Hearth
   - Manifests are located in [`k8s-infra/`](./k8s-infra/).

5. **Application Microservices Deployment:**
   - Deploys all OpenCRVS microservices, including:
     - auth, client, config, dashboards, documents, events, gateway, login, metrics, notification, search, user-mgnt, webhooks, workflow
   - Manifests are located in [`k8s-service-nodePort/`](./k8s-service-nodePort/).
   - The script replaces the `${VERSION}` variable in service manifests with the desired version (default: `phase-3`).

6. **Readiness Checks:**
   - Waits for all infrastructure and microservice pods to become ready before completing the deployment.

## Project Structure

```
├── deploy.sh                  # Main deployment script
├── k8s-infra/                 # Infrastructure Kubernetes manifests
├── k8s-service-nodePort/      # Microservice Kubernetes manifests (NodePort)
├── infrastructureConfig/      # Config files for configmaps
│   ├── influxdb.conf
│   ├── hearth-queryparam-extensions.json
│   └── hearth-plugins/
│       └── checkDuplicateTask.js
├── .secrets/                  # Generated self-signed certificates (created at runtime)
└── namespace.yaml             # Namespace manifest (optional)
```

## Prerequisites

- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [openssl](https://www.openssl.org/)
- Access to a Kubernetes cluster (e.g., Minikube, Docker Desktop, or remote cluster)

## Usage

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd opencrvs-k8s-nodePort
   ```
2. **Run the deployment script:**
   ```sh
   bash deploy.sh
   ```
   - This will set up all infrastructure and application services in the `opencrvs` namespace.
   - Services will be accessible via NodePort on your cluster nodes.

3. **Accessing Services:**
   - Use `kubectl get svc -n opencrvs` to find the NodePort for each service.
   - Access services using `<NodeIP>:<NodePort>` in your browser or API client.

## Notes

- The deployment is intended for development and testing. For production, consider using Ingress and a proper certificate manager (e.g., cert-manager).
- If you have a `docker-compose.dev.yaml`, you can compare the exposed services and ports to ensure parity with this Kubernetes setup.

## Troubleshooting

- If pods are not becoming ready, check logs with:
  ```sh
  kubectl logs <pod-name> -n opencrvs
  ```
- Ensure your Kubernetes cluster allows NodePort access from your machine/network.

---

For more information, refer to the OpenCRVS documentation or contact the maintainers. 
