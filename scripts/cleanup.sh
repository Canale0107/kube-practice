#!/bin/bash
set -euo pipefail

# 色付き出力用の関数
green() { echo -e "\033[0;32m$*\033[0m"; }
red() { echo -e "\033[0;31m$*\033[0m"; }
yellow() { echo -e "\033[0;33m$*\033[0m"; }

CLUSTER_NAME="kube-practice"

echo "🧹 Cleaning up Kubernetes cluster..."

# クラスタが存在するか確認
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    yellow "⚠ Cluster '$CLUSTER_NAME' does not exist"
    echo "  Nothing to clean up."
    exit 0
fi

# 確認プロンプト
read -p "Are you sure you want to delete cluster '$CLUSTER_NAME'? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# クラスタを削除
echo "🗑️  Deleting cluster: $CLUSTER_NAME"
kind delete cluster --name "$CLUSTER_NAME"

green "✓ Cluster '$CLUSTER_NAME' has been deleted"
echo ""
echo "To create a new cluster, run: ./scripts/bootstrap.sh"
