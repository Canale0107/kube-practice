#!/bin/bash
set -euo pipefail

# 色付き出力用の関数
green() { echo -e "\033[0;32m$*\033[0m"; }
red() { echo -e "\033[0;31m$*\033[0m"; }
yellow() { echo -e "\033[0;33m$*\033[0m"; }

CLUSTER_NAME="kube-practice"

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
K8S_DIR="$PROJECT_ROOT/k8s"

# クラスタが存在するか確認
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    red "✗ Cluster '$CLUSTER_NAME' does not exist"
    echo "  Run ./scripts/bootstrap.sh first"
    exit 1
fi

# コンテキストを確認
CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" != "kind-${CLUSTER_NAME}" ]; then
    yellow "⚠ Current context is '$CURRENT_CONTEXT', switching to 'kind-${CLUSTER_NAME}'"
    kubectl config use-context "kind-${CLUSTER_NAME}"
fi

echo "📦 Deploying manifests from $K8S_DIR"

# マニフェストを適用
kubectl apply -f "$K8S_DIR/"

echo ""
green "✓ Deployment created"
echo ""
echo "Waiting for Pod to be ready..."
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s

echo ""
green "✓ Deployment is ready!"
echo ""
echo "Next step: ./scripts/observe.sh"
