#!/bin/bash

# Configuration
IMAGE_NAME="yotta-app"
TAG=$(date +%s)
NAMESPACES=("user1" "user2" "user3")

echo "--- Starting CI/CD Pipeline ---"

# 1. Build Image
echo "Building image ${IMAGE_NAME}:${TAG}..."
eval $(minikube docker-env)
docker build -t ${IMAGE_NAME}:${TAG} ./app
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi
docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:latest

# 2. Deploy per user
for NS in "${NAMESPACES[@]}"; do
    echo "Deploying to namespace: ${NS}..."
    
    # Update deployment image
    kubectl set image deployment/website website=${IMAGE_NAME}:${TAG} -n ${NS}
    
    # Wait for rollout
    echo "Waiting for rollout in ${NS}..."
    kubectl rollout status deployment/website -n ${NS} --timeout=60s
    
    if [ $? -ne 0 ]; then
        echo "Rollback triggered for ${NS}!"
        kubectl rollout undo deployment/website -n ${NS}
        exit 1
    fi
    
    echo "Deployment successful for ${NS}"
    
    # 3. Trigger Kafka Event (Simulated via curl to the app's trigger endpoint)
    # We'll use a temporary pod to curl the service since we're in a multi-tenant setup
    echo "Triggering WebsiteCreated event for ${NS}..."
    kubectl run curl-tmp --image=curlimages/curl --rm -i --restart=Never -n ${NS} \
      -- curl -s http://website-service:80/trigger-event

done

echo "--- CI/CD Pipeline Completed Successfully ---"
