#!/bin/bash
set -euo pipefail

# 色付き出力用の関数
green() { echo -e "\033[0;32m$*\033[0m"; }
red() { echo -e "\033[0;31m$*\033[0m"; }
yellow() { echo -e "\033[0;33m$*\033[0m"; }

CLUSTER_NAME="kube-practice"

echo "🔍 Checking dependencies..."

# Dockerの確認
if ! command -v docker &> /dev/null; then
    red "✗ Docker is not installed or not in PATH"
    echo "  macOS: Install Docker Desktop from https://www.docker.com/products/docker-desktop"
    echo "  Linux: Install Docker Engine - https://docs.docker.com/engine/install/"
    exit 1
fi

# Dockerが起動しているか確認
if ! docker ps &> /dev/null; then
    red "✗ Docker is not running"
    echo "  Please start Docker Desktop (macOS) or Docker daemon (Linux)"
    exit 1
fi
green "✓ Docker is running"

# kindの確認
if ! command -v kind &> /dev/null; then
    red "✗ kind is not installed"
    echo "  macOS: brew install kind"
    echo "  Linux: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi
green "✓ kind is installed"

# kubectlの確認
if ! command -v kubectl &> /dev/null; then
    red "✗ kubectl is not installed"
    echo "  macOS: brew install kubectl"
    echo "  Linux: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
    exit 1
fi
green "✓ kubectl is installed"

echo ""
echo "🚀 Creating kind cluster: $CLUSTER_NAME"

# 既存のクラスタがあるか確認
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    yellow "⚠ Cluster '$CLUSTER_NAME' already exists"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing cluster..."
        kind delete cluster --name "$CLUSTER_NAME"
    else
        echo "Using existing cluster."
        kubectl cluster-info --context "kind-${CLUSTER_NAME}"
        exit 0
    fi
fi

# クラスタ作成
kind create cluster --name "$CLUSTER_NAME"

# コンテキストの確認
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

green "✓ Cluster '$CLUSTER_NAME' is ready!"
echo ""
echo "Next step: ./scripts/deploy.sh"
