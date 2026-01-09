#!/bin/bash
set -euo pipefail

# 色付き出力用の関数
green() { echo -e "\033[0;32m$*\033[0m"; }
red() { echo -e "\033[0;31m$*\033[0m"; }
yellow() { echo -e "\033[0;33m$*\033[0m"; }

CLUSTER_NAME="kube-practice"

# クラスタが存在するか確認
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    red "✗ Cluster '$CLUSTER_NAME' does not exist"
    echo "  Run ./scripts/bootstrap.sh first"
    exit 1
fi

# コンテキストを確認
CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" != "kind-${CLUSTER_NAME}" ]; then
    kubectl config use-context "kind-${CLUSTER_NAME}"
fi

# Podが存在するか確認
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$POD_NAME" ]; then
    red "✗ No Pods found"
    echo "  Run ./scripts/deploy.sh first"
    exit 1
fi

echo "💥 Chaos Engineering: Testing Self-Healing"
echo ""
echo "Current Pod: $POD_NAME"
echo ""

# 現在の状態を表示
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Before deletion:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods -l app=nginx
echo ""

# Podを削除
echo "🗑️  Deleting pod: $POD_NAME"
kubectl delete pod "$POD_NAME" --wait=false

echo ""
echo "⏳ Waiting 2 seconds..."
sleep 2

# 削除直後の状態
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "After deletion (2 seconds):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods -l app=nginx
echo ""

# 少し待ってから再度確認
echo "⏳ Waiting 5 more seconds for new Pod to be created..."
sleep 5

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "After 7 seconds (new Pod should be running):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods -l app=nginx
echo ""

# 新しいPodの状態を確認
NEW_POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$NEW_POD_NAME" ]; then
    NEW_POD_STATUS=$(kubectl get pod "$NEW_POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    
    if [ "$NEW_POD_STATUS" = "Running" ]; then
        green "✓ Self-healing successful!"
        echo "  Old Pod: $POD_NAME (deleted)"
        echo "  New Pod: $NEW_POD_NAME (running)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "What happened:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "1. You deleted the Pod: $POD_NAME"
        echo "2. Deployment controller detected that replicas < desired (0 < 1)"
        echo "3. Deployment automatically created a new Pod: $NEW_POD_NAME"
        echo "4. The new Pod is now Running and serving traffic"
        echo ""
        yellow "💡 This is Kubernetes' self-healing capability!"
    else
        yellow "⚠ New Pod is being created but not yet Running"
        echo "  Status: $NEW_POD_STATUS"
        echo "  Run 'kubectl get pods -w' to watch it become Ready"
    fi
else
    red "✗ No Pods found after deletion"
    echo "  Something went wrong. Check with: kubectl get pods"
fi

echo ""
echo "To watch Pod changes in real-time, run:"
echo "  kubectl get pods -w"
echo ""
echo "Or use watch (if available):"
echo "  watch -n 2 kubectl get pods"
