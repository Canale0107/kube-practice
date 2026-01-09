# トラブルシューティング

この章では、Kubernetesを操作する際によく遭遇する問題と、その解決方法を詳しく説明します。

## トラブルシューティングの基本アプローチ

### 1. エラーメッセージを読む

エラーメッセージには、問題の原因が含まれています。まずはエラーメッセージをよく読みましょう。

### 2. リソースの状態を確認

```bash
# すべてのリソースを確認
kubectl get all

# 特定のリソースを確認
kubectl get pods
kubectl get deployments
kubectl get services
```

### 3. 詳細情報を確認

```bash
# Podの詳細
kubectl describe pod <pod-name>

# Deploymentの詳細
kubectl describe deployment <deployment-name>

# イベントを確認
kubectl get events --sort-by='.lastTimestamp'
```

### 4. ログを確認

```bash
# Podのログ
kubectl logs <pod-name>

# 前回のクラッシュのログ
kubectl logs <pod-name> --previous
```

## よくある問題と解決方法

### 問題1: Dockerが起動していない

#### 症状

```bash
$ docker ps
Cannot connect to the Docker daemon. Is the docker daemon running?
```

または

```bash
$ kind create cluster
ERROR: failed to create cluster: docker: "docker" not found in PATH
```

#### 原因

Docker Desktop（macOS）またはDockerサービス（Linux）が起動していない。

#### 解決方法

**macOS:**
1. アプリケーションからDocker Desktopを起動
2. メニューバーにDockerアイコンが表示されるまで待つ
3. 確認: `docker ps`

**Linux:**
```bash
# Dockerサービスを起動
sudo systemctl start docker

# 自動起動を有効化（オプション）
sudo systemctl enable docker

# 確認
docker ps
```

### 問題2: kindクラスタが見つからない

#### 症状

```bash
$ kubectl get pods
error: the server doesn't have a resource type "pods"
```

または

```bash
$ kubectl get nodes
The connection to the server localhost:8080 was refused
```

#### 原因

- クラスタが作成されていない
- 間違ったコンテキストを使用している

#### 解決方法

**1. クラスタの存在確認:**
```bash
kind get clusters
```

**2. コンテキストの確認:**
```bash
# 現在のコンテキストを確認
kubectl config current-context

# 利用可能なコンテキストを確認
kubectl config get-contexts
```

**3. コンテキストの切り替え:**
```bash
kubectl config use-context kind-kube-practice
```

**4. クラスタが存在しない場合:**
```bash
./scripts/bootstrap.sh
```

### 問題3: イメージのPullに失敗

#### 症状

```bash
$ kubectl get pods
NAME                    READY   STATUS         RESTARTS   AGE
nginx-xxxxxxxxxx-xxxxx  0/1     ImagePullBackOff   0          30s
```

または

```bash
$ kubectl describe pod <pod-name>
Events:
  Warning  Failed      Error: ErrImagePull
  Warning  Failed      Error: ImagePullBackOff
```

#### 原因

- イメージが存在しない
- ネットワークの問題
- イメージレジストリへのアクセス不可

#### 解決方法

**1. イメージを手動でPull:**
```bash
docker pull nginx:latest
```

**2. kindクラスタにイメージをロード:**
```bash
kind load docker-image nginx:latest --name kube-practice
```

**3. イメージの存在確認:**
```bash
docker images | grep nginx
```

**4. ネットワーク接続の確認:**
```bash
# Dockerがインターネットに接続できるか
docker pull nginx:latest
```

### 問題4: PodがPending状態のまま

#### 症状

```bash
$ kubectl get pods
NAME                    READY   STATUS    RESTARTS   AGE
nginx-xxxxxxxxxx-xxxxx  0/1     Pending   0          5m
```

#### 原因

- リソース不足（メモリ・CPU）
- ノードの準備ができていない
- イメージのPullに失敗

#### 解決方法

**1. Podの詳細を確認:**
```bash
kubectl describe pod <pod-name>
```

**2. イベントを確認:**
```bash
kubectl get events --sort-by='.lastTimestamp'
```

**3. ノードの状態を確認:**
```bash
kubectl get nodes
kubectl describe node <node-name>
```

**4. リソース不足の場合:**
- Docker Desktopのリソース設定を確認（macOS）
- 他のアプリケーションを終了

**5. イメージPull失敗の場合:**
- [問題3](#問題3-イメージのpullに失敗)を参照

### 問題5: PodがCrashLoopBackOff状態

#### 症状

```bash
$ kubectl get pods
NAME                    READY   STATUS             RESTARTS   AGE
nginx-xxxxxxxxxx-xxxxx  0/1     CrashLoopBackOff   3          2m
```

#### 原因

- アプリケーションがエラーで終了
- 設定ファイルのエラー
- 依存関係の問題

#### 解決方法

**1. ログを確認:**
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # 前回のクラッシュのログ
```

**2. Podの詳細を確認:**
```bash
kubectl describe pod <pod-name>
```

**3. イベントを確認:**
```bash
kubectl get events --sort-by='.lastTimestamp'
```

**4. よくある原因:**
- 設定ファイルの構文エラー
- 必要なファイルが存在しない
- ポートの競合

### 問題6: port-forwardが接続できない

#### 症状

```bash
$ kubectl port-forward service/nginx-service 8080:80
error: unable to forward port because pod is not running. Current status=Pending
```

または

```bash
$ curl http://localhost:8080
curl: (7) Failed to connect to localhost port 8080: Connection refused
```

#### 原因

- PodがRunning状態ではない
- Serviceが存在しない
- ポートが既に使用されている

#### 解決方法

**1. Podの状態を確認:**
```bash
kubectl get pods
```

PodがRunning状態でない場合、[問題4](#問題4-podがpending状態のまま)または[問題5](#問題5-podがcrashloopbackoff状態)を参照。

**2. Serviceの存在確認:**
```bash
kubectl get svc
```

**3. ポートの使用状況確認:**
```bash
# macOS
lsof -i :8080

# Linux
netstat -tuln | grep 8080
# または
ss -tuln | grep 8080
```

**4. 別のポートを使用:**
```bash
kubectl port-forward service/nginx-service 8081:80
```

**5. Podに直接port-forward:**
```bash
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward pod/$POD_NAME 8080:80
```

### 問題7: リソースが削除できない

#### 症状

```bash
$ kubectl delete pod <pod-name>
pod "<pod-name>" deleted
# しかし、すぐに新しいPodが作成される
```

#### 原因

DeploymentがPodを管理しているため、Podを削除しても自動で再作成される。

#### 解決方法

**Podを削除する場合（再作成される）:**
```bash
kubectl delete pod <pod-name>
# 新しいPodが自動で作成される（正常な動作）
```

**Deploymentごと削除する場合:**
```bash
kubectl delete deployment nginx
# Podも一緒に削除される
```

**すべてのリソースを削除:**
```bash
kubectl delete -f k8s/
```

### 問題8: 権限エラー（Linux）

#### 症状

```bash
$ docker ps
permission denied while trying to connect to the Docker daemon socket
```

#### 原因

現在のユーザーがdockerグループに属していない。

#### 解決方法

```bash
# ユーザーをdockerグループに追加
sudo usermod -aG docker $USER

# ログアウトして再ログイン（または新しいターミナルを開く）

# 確認
groups  # dockerグループが表示されればOK
```

### 問題9: コンテキストの混乱

#### 症状

複数のKubernetesクラスタを使用している場合、間違ったクラスタを操作してしまう。

#### 解決方法

**1. 現在のコンテキストを確認:**
```bash
kubectl config current-context
```

**2. 利用可能なコンテキストを確認:**
```bash
kubectl config get-contexts
```

**3. コンテキストを切り替え:**
```bash
kubectl config use-context kind-kube-practice
```

**4. デフォルトのコンテキストを設定:**
```bash
kubectl config set-context kind-kube-practice
```

## デバッグのコマンド集

### リソースの状態確認

```bash
# すべてのリソース
kubectl get all

# 特定のリソース
kubectl get pods,deployments,services

# 詳細表示
kubectl get pods -o wide

# YAML形式で表示
kubectl get pod <pod-name> -o yaml

# JSON形式で表示
kubectl get pod <pod-name> -o json
```

### 詳細情報の確認

```bash
# Podの詳細
kubectl describe pod <pod-name>

# Deploymentの詳細
kubectl describe deployment <deployment-name>

# Serviceの詳細
kubectl describe service <service-name>

# ノードの詳細
kubectl describe node <node-name>
```

### ログの確認

```bash
# 最新のログ
kubectl logs <pod-name>

# リアルタイムで追跡
kubectl logs -f <pod-name>

# 前回のクラッシュのログ
kubectl logs <pod-name> --previous

# 複数コンテナがある場合
kubectl logs <pod-name> -c <container-name>
```

### イベントの確認

```bash
# すべてのイベント
kubectl get events

# 時系列でソート
kubectl get events --sort-by='.lastTimestamp'

# 特定のリソースのイベント
kubectl get events --field-selector involvedObject.name=<pod-name>
```

### コンテナ内でのデバッグ

```bash
# コンテナ内に入る
kubectl exec -it <pod-name> -- /bin/bash

# コマンドを実行
kubectl exec <pod-name> -- ls -la

# 複数コンテナがある場合
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash
```

### ネットワークの確認

```bash
# Serviceのエンドポイントを確認
kubectl get endpoints <service-name>

# Serviceの詳細
kubectl describe service <service-name>

# PodのIPアドレスを確認
kubectl get pods -o wide
```

## エラーメッセージの読み方

### よくあるエラーメッセージ

#### `ImagePullBackOff`

**意味**: イメージのPullに失敗

**対処:**
- イメージ名が正しいか確認
- ネットワーク接続を確認
- イメージを手動でPull

#### `CrashLoopBackOff`

**意味**: コンテナが繰り返しクラッシュ

**対処:**
- ログを確認
- 設定ファイルを確認
- 依存関係を確認

#### `Pending`

**意味**: Podがスケジュールされていない

**対処:**
- リソース不足を確認
- ノードの状態を確認
- イメージのPullを確認

#### `ErrImagePull`

**意味**: イメージのPullエラー

**対処:**
- イメージ名が正しいか確認
- ネットワーク接続を確認
- イメージレジストリへのアクセスを確認

## 予防策

### 1. 定期的な確認

```bash
# リソースの状態を定期的に確認
kubectl get all

# イベントを確認
kubectl get events --sort-by='.lastTimestamp'
```

### 2. ログの監視

```bash
# リアルタイムでログを監視
kubectl logs -f <pod-name>
```

### 3. リソースのクリーンアップ

```bash
# 不要なリソースを削除
kubectl delete -f k8s/

# クラスタを削除
kind delete cluster --name kube-practice
```

## 次のステップ

トラブルシューティングの基礎を学んだら、さらに詳しい情報が必要な場合は公式ドキュメントを参照しましょう。

**次のドキュメント**: [次のステップ](./06-next-steps.md)

---

**目次に戻る**: [README](./README.md)
