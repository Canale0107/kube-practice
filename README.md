# kubectl基本操作体験プロジェクト

このプロジェクトは、ローカルKubernetes環境（kind）を使ってkubectlの基本操作を体験するための超ミニプロジェクトです。

## 📚 詳細な学習ドキュメント

**Kubernetesを初めて学ぶ方向け**に、段階的に学習できる詳細なドキュメントを用意しました。

👉 **[docs/README.md](docs/README.md)** から始めましょう！

### ドキュメント一覧

- **[イントロダクション](docs/00-introduction.md)** - Kubernetesとは何か、なぜ学ぶのか
- **[前提知識](docs/01-prerequisites.md)** - コンテナ、Dockerの基礎
- **[セットアップガイド](docs/02-setup.md)** - 詳細なインストール手順
- **[Kubernetes基本概念](docs/03-kubernetes-basics.md)** - Pod、Deployment、Serviceなどの詳細解説
- **[ハンズオンガイド](docs/04-hands-on-guide.md)** - このプロジェクトを使った実践的な学習
- **[トラブルシューティング](docs/05-troubleshooting.md)** - よくある問題と解決方法
- **[次のステップ](docs/06-next-steps.md)** - さらに学ぶためのリソース

## 前提条件

### 必要なツール

1. **Docker Desktop**（macOS）または **Docker Engine**（Linux）
   - Dockerが起動している必要があります
   - 確認: `docker ps`

2. **kind**（Kubernetes in Docker）
   - macOS: `brew install kind`
   - Linux: [公式インストール手順](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

3. **kubectl**（Kubernetes CLI）
   - macOS: `brew install kubectl`
   - Linux: [公式インストール手順](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

### 依存確認

```bash
# すべてのコマンドが利用可能か確認
command -v docker && echo "✓ Docker found" || echo "✗ Docker not found"
command -v kind && echo "✓ kind found" || echo "✗ kind not found"
command -v kubectl && echo "✓ kubectl found" || echo "✗ kubectl not found"
```

## 0. Quickstart（最短手順）

```bash
# 1. クラスタ作成とデプロイ
./scripts/bootstrap.sh
./scripts/deploy.sh

# 2. 観測（Podの状態確認）
./scripts/observe.sh

# 3. Self-healing体験（Pod削除→復活確認）
./scripts/chaos.sh

# 4. アクセス確認（別ターミナルで実行）
kubectl port-forward service/nginx-service 8080:80
# ブラウザで http://localhost:8080 にアクセス、または
curl http://localhost:8080

# 5. 後片付け
./scripts/cleanup.sh
```

## 1. クラスタ作成

kindを使ってローカルKubernetesクラスタを作成します。

```bash
./scripts/bootstrap.sh
```

または手動で：

```bash
kind create cluster --name kube-practice
kubectl cluster-info --context kind-kube-practice
```

**出力例:**
```
Creating cluster "kube-practice" ...
 ✓ Ensuring node image (kindest/node:v1.27.3) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-kube-practice"
```

**なぜこれが必要？**
- Kubernetesクラスタは、コンテナを実行するための環境です
- kindは、Dockerコンテナ内にKubernetesクラスタを作成するツールです
- 本番環境と同じ操作をローカルで安全に体験できます

## 2. デプロイ

nginxのDeploymentとServiceをデプロイします。

```bash
./scripts/deploy.sh
```

または手動で：

```bash
kubectl apply -f k8s/
```

**出力例:**
```
configmap/nginx-config created
deployment.apps/nginx created
service/nginx-service created
```

**なぜこれが必要？**
- `kubectl apply`は、マニフェストファイル（YAML）に書かれた「望ましい状態」をクラスタに反映します
- Deploymentは「Podを1つ作って維持する」という設計図です
- Serviceは、Podへのアクセスを提供するエンドポイントです

## 3. 観測

kubectlを使ってリソースの状態を確認します。

```bash
./scripts/observe.sh
```

または手動で：

```bash
# Pod一覧（簡易表示）
kubectl get pods

# Pod一覧（詳細表示：IPアドレス、ノード名など）
kubectl get pods -o wide

# Deployment、ReplicaSet、Podをまとめて表示
kubectl get deploy,rs,pod

# 特定のPodの詳細情報
kubectl describe pod <pod-name>

# Podのログを確認
kubectl logs <pod-name>

# リアルタイムでログを追跡
kubectl logs -f <pod-name>
```

**出力例:**
```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-xxxxxxxxxx-xxxxx  1/1     Running   0          30s
```

**なぜこれが必要？**
- `kubectl get`は、リソースの現在の状態を一覧表示します
- `kubectl describe`は、リソースの詳細情報（イベント、設定など）を表示します
- `kubectl logs`は、コンテナの標準出力を確認できます
- これらは、トラブルシューティングの基本ツールです

## 4. 変化の観測

Podの状態変化をリアルタイムで観測します。

### watchコマンドがある場合

```bash
watch -n 2 kubectl get pods
```

### watchコマンドがない場合（macOSデフォルト）

```bash
# ループで定期的に表示
while true; do
  clear
  kubectl get pods
  sleep 2
done
```

または、別ターミナルで：

```bash
kubectl get pods -w
```

**なぜこれが必要？**
- Kubernetesは常に「望ましい状態」を維持しようとします
- Podが削除されたり、失敗したりすると、自動的に復元されます
- この動作をリアルタイムで観測することで、Kubernetesの自律性を理解できます

## 5. Self-healing体験

Podを削除して、Deploymentが自動的に復元する様子を確認します。

```bash
./scripts/chaos.sh
```

または手動で：

```bash
# 現在のPod名を取得
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
echo "Deleting pod: $POD_NAME"

# Podを削除
kubectl delete pod $POD_NAME

# すぐにPod一覧を確認（削除されたPodと新しいPodが両方見える場合がある）
kubectl get pods

# 数秒待ってから再度確認（新しいPodがRunningになっている）
sleep 5
kubectl get pods
```

**出力例:**
```
pod "nginx-xxxxxxxxxx-xxxxx" deleted
NAME                    READY   STATUS        RESTARTS   AGE
nginx-xxxxxxxxxx-yyyyy  0/1     ContainerCreating   0          1s
nginx-xxxxxxxxxx-xxxxx  1/1     Terminating         0          30s
```

数秒後：
```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-xxxxxxxxxx-yyyyy  1/1     Running   0          5s
```

**なぜこれが起こる？**
- Deploymentは「replicas: 1」という設定を持っています
- Podが削除されると、Deploymentコントローラーが「Podが1つ足りない」と検知します
- 自動的に新しいPodを作成して、望ましい状態（1つのPodがRunning）を維持します
- これがKubernetesの**Self-healing**（自己修復）機能です

## 6. アクセス確認

デプロイしたnginxにアクセスして、動作を確認します。

### 方法1: port-forward（推奨）

```bash
# 別ターミナルで実行（フォアグラウンドで実行される）
kubectl port-forward service/nginx-service 8080:80
```

別のターミナルで：

```bash
curl http://localhost:8080
```

またはブラウザで `http://localhost:8080` にアクセス。

**出力例:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Kubernetes Practice</title>
</head>
<body>
    <h1>Hello from Kubernetes!</h1>
    <p>This is served from a ConfigMap.</p>
</body>
</html>
```

### 方法2: NodePort（kindの場合、外部IPは取得できないためport-forward推奨）

ServiceのタイプをNodePortに変更している場合：

```bash
# NodePortのポート番号を確認
kubectl get svc nginx-service

# ポート番号が30080の場合
curl http://localhost:30080
```

**なぜこれが必要？**
- Serviceは、Podへのアクセスを抽象化します
- port-forwardは、ローカルマシンのポートをServiceに転送します
- これにより、クラスタ内のPodに簡単にアクセスできます

## 7. 後片付け

作成したクラスタを削除します。

```bash
./scripts/cleanup.sh
```

または手動で：

```bash
kind delete cluster --name kube-practice
```

**出力例:**
```
Deleting cluster "kube-practice" ...
```

## 学習のポイント

### 重要な概念

1. **Deployment（デプロイメント）**
   - Podの設計図。replicas数、コンテナイメージ、環境変数などを定義
   - Podを削除しても、Deploymentが自動的に新しいPodを作成

2. **Pod（ポッド）**
   - コンテナを実行する最小単位
   - 1つのPodには1つ以上のコンテナが含まれる（この例ではnginxコンテナ1つ）

3. **Service（サービス）**
   - Podへのアクセスを提供するエンドポイント
   - PodはIPアドレスが変わる可能性があるが、Serviceは安定したアクセスを提供

4. **ConfigMap（コンフィグマップ）**
   - 設定データを保存するリソース
   - この例では、nginxのindex.htmlをConfigMapからマウント

5. **LabelsとSelectors（ラベルとセレクター）**
   - リソースをグループ化・選択するためのメタデータ
   - `app=nginx`というラベルで、DeploymentとServiceが関連付けられる

### 便利なコマンド

```bash
# すべてのリソースを表示
kubectl get all

# YAML形式でリソースを表示
kubectl get pod <pod-name> -o yaml

# リソースのイベントを確認
kubectl get events --sort-by='.lastTimestamp'

# リソースの説明を表示
kubectl explain pod
```

## トラブルシュート

### Dockerが起動していない

**エラー:**
```
ERROR: failed to create cluster: docker: "docker" not found in PATH
```

**解決:**
```bash
# Docker Desktopを起動（macOS）
open -a Docker

# Dockerが起動しているか確認
docker ps
```

### kindクラスタが見つからない

**エラー:**
```
error: the server doesn't have a resource type "pods"
```

**解決:**
```bash
# 現在のコンテキストを確認
kubectl config current-context

# kindクラスタのコンテキストに切り替え
kubectl config use-context kind-kube-practice

# クラスタが存在するか確認
kind get clusters
```

### イメージのPullに失敗

**エラー:**
```
Failed to pull image "nginx:latest": rpc error: code = Unknown desc = failed to pull and unpack image
```

**解決:**
```bash
# Dockerが起動しているか確認
docker ps

# イメージを手動でPull
docker pull nginx:latest

# kindクラスタにイメージをロード（既にPull済みの場合）
kind load docker-image nginx:latest --name kube-practice
```

### PodがPending状態のまま

**確認:**
```bash
# Podの詳細を確認
kubectl describe pod <pod-name>

# イベントを確認
kubectl get events --sort-by='.lastTimestamp'
```

**よくある原因:**
- リソース不足（メモリ・CPU）
- イメージPull失敗
- ノードの準備ができていない

### port-forwardが接続できない

**確認:**
```bash
# Serviceが存在するか確認
kubectl get svc

# PodがRunning状態か確認
kubectl get pods

# port-forwardを再実行
kubectl port-forward service/nginx-service 8080:80
```

## 次のステップ

- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/home/)
- [kubectlチートシート](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kind公式ドキュメント](https://kind.sigs.k8s.io/)

## ライセンス

このプロジェクトは学習目的のためのサンプルです。
