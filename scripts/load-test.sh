#!/bin/bash

MINIKUBE_IP=$(minikube ip)
echo "Starting load test on user1.example.com..."

# Run a horizontal pod autoscaler stress test
for i in {1..500}; do
    curl -s -k -H "Host: user1.example.com" https://$MINIKUBE_IP > /dev/null &
done

echo "Load generated. Checking HPA status..."
sleep 10
kubectl get hpa -n user1
