#!/bin/bash
NS="user1"
BAD_IMAGE="yotta-app:non-existent-tag"

echo "--- Simulating Failed Deployment for ${NS} ---"
echo "Updating deployment with invalid image: ${BAD_IMAGE}"

kubectl set image deployment/website website=${BAD_IMAGE} -n ${NS}

echo "Waiting for rollout (this should time out)..."
kubectl rollout status deployment/website -n ${NS} --timeout=15s

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed as expected!"
    echo "🔄 Triggering ROLLBACK (kubectl rollout undo)..."
    kubectl rollout undo deployment/website -n ${NS}
    echo "✅ Rollback initiated."
    kubectl rollout status deployment/website -n ${NS}
fi
