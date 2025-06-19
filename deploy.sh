#!/bin/bash

# Set the OpenCRVS version
VERSION=${VERSION:-"develop"}

# Check if namespace exists, if not create it
kubectl get namespace opencrvs || kubectl create namespace opencrvs

# Generate keys if they don't exist
if [ ! -f .secrets/private-key.pem ] || [ ! -f .secrets/public-key.pem ]; then
    echo "Generating keys..."
    mkdir -p .secrets
    openssl genrsa -out .secrets/private-key.pem 2048
    openssl rsa -in .secrets/private-key.pem -pubout -out .secrets/public-key.pem
else
    echo "Keys already exist. Skipping key generation."
fi


# Create secrets
echo "Creating secrets..."
kubectl create secret generic opencrvs-public-key --from-file=public-key.pem=.secrets/public-key.pem -n opencrvs --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic opencrvs-private-key --from-file=private-key.pem=.secrets/private-key.pem -n opencrvs --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic hearth-public-key --from-file=.secrets/public-key.pem -n opencrvs --dry-run=client -o yaml | kubectl apply -f -

# Create infrastructureConfig configmaps
echo "Creating infrastructureConfig configmaps..."
kubectl create configmap influxdb-config --from-file=infrastructureConfig/influxdb.conf -n opencrvs --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap hearth-plugins --from-file=infrastructureConfig/hearth-plugins/checkDuplicateTask.js -n opencrvs --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap hearth-config --from-file=infrastructureConfig/hearth-queryparam-extensions.json -n opencrvs --dry-run=client -o yaml | kubectl apply -f -


infras=(
    "mongodb"
    "elasticsearch"
    "influxdb"
    "minio"
    "redis"
    "hearth"
)

echo "Applying infra YAMLs..."
for infra in "${infras[@]}"; do
    echo "Deploying $infra..."
    kubectl apply -f "k8s-infra/$infra.yaml"
done

echo "Waiting for infra to become ready..."
for infra in "${infras[@]}"; do
    echo "Waiting for $infra"
    kubectl wait --for=condition=ready pod -l app=$infra -n opencrvs --timeout=300s
done

# Deploy application services
services=(
  "auth"
  "client"
  "config"
  "dashboards"
  "documents"
  "events"
  "gateway"
  "login"
  "metrics"
  "notification"
  "search"
  "user-mgnt"
  "webhooks"
  "workflow"
)

echo "Applying micro-service YAMLs..."
for service in "${services[@]}"; do
    echo "Deploying $service..."
    sed "s/\${VERSION}/$VERSION/g" "k8s-service-nodePort/$service.yaml" | kubectl apply -f -
done

echo "Waiting for micro-service to become ready..."
for service in "${services[@]}"; do
    echo "Waiting for $service"
    kubectl wait --for=condition=ready pod -l app=$service -n opencrvs --timeout=300s
done

echo "All services deployed successfully!" 