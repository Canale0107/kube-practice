#!/bin/bash
set -euo pipefail

# 色付き出力用の関数
green() { echo -e "\033[0;32m$*\033[0m"; }
yellow() { echo -e "\033[0;33m$*\033[0m"; }

CLUSTER_NAME="kube-practice"

# クラスタが存在するか確認
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "✗ Cluster '$CLUSTER_NAME' does not exist"
    echo "  Run ./scripts/bootstrap.sh first"
    exit 1
fi

# コンテキストを確認
CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" != "kind-${CLUSTER_NAME}" ]; then
    kubectl config use-context "kind-${CLUSTER_NAME}"
fi

echo "🔍 Observing Kubernetes resources..."
echo ""

# 1. Pod一覧（簡易表示）
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Pods (simple view)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods
echo ""

# 2. Pod一覧（詳細表示）
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Pods (wide view - shows IP and Node)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods -o wide
echo ""

# 3. Deployment、ReplicaSet、Podをまとめて表示
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Deployment, ReplicaSet, and Pods"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get deploy,rs,pod -l app=nginx
echo ""

# 4. Serviceの確認
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get svc nginx-service
echo ""

# 5. ConfigMapの確認
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. ConfigMap"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get configmap nginx-config
echo ""

# 6. Podの詳細情報（最初のPod）
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD_NAME" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "6. Pod details: $POD_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    kubectl describe pod "$POD_NAME" | head -30
    echo ""
    echo "... (truncated, use 'kubectl describe pod $POD_NAME' for full output)"
    echo ""
    
    # 7. Podのログ（最新10行）
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "7. Pod logs (last 10 lines): $POD_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    kubectl logs "$POD_NAME" --tail=10
    echo ""
else
    yellow "⚠ No Pods found. Run ./scripts/deploy.sh first"
fi

echo ""
green "✓ Observation complete!"
echo ""
echo "Next step: ./scripts/chaos.sh (to test self-healing)"
