# Kubernetes基本概念

この章では、Kubernetesの主要な概念を詳しく説明します。実際に手を動かす前に、用語と概念を理解しておくと、操作がスムーズになります。

## 全体像

Kubernetesは、**宣言的な設定**でアプリケーションを管理します。

- **宣言的**: 「どうやって」ではなく「どういう状態にしたいか」を書く
- **自動化**: Kubernetesが自動でその状態を実現・維持する

```
あなたが書く設定（YAML）
    ↓
kubectl apply
    ↓
Kubernetesが解釈・実行
    ↓
望ましい状態を実現・維持
```

## Pod（ポッド）

### とは

**Pod**は、Kubernetesでコンテナを実行する**最小単位**です。

- 1つ以上のコンテナを含む
- 同じPod内のコンテナは、ネットワークとストレージを共有
- 通常は1つのPodに1つのコンテナ

### 特徴

1. **一時的（エフェメラル）**
   - Podは削除されたり、再作成されたりする
   - IPアドレスが変わる可能性がある

2. **自己完結**
   - アプリケーションとその依存関係を含む
   - どこで実行されても同じ動作

3. **スケーリングの単位**
   - Podを複数作成して負荷分散

### 例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

この設定で、nginxコンテナを実行するPodが作成されます。

### 重要なポイント

- Podは**直接作成することは少ない**
- 通常は**Deployment**を使ってPodを管理する
- Podを削除しても、Deploymentが自動で新しいPodを作成する（Self-healing）

## Deployment（デプロイメント）

### とは

**Deployment**は、Podの**設計図**です。

- いくつのPodを作るか（replicas）
- どのコンテナイメージを使うか
- どのような設定で動かすか

### 特徴

1. **レプリカ管理**
   - `replicas: 3`と書けば、3つのPodを維持
   - Podが削除されても、自動で新しいPodを作成

2. **ロールアウト管理**
   - 新しいバージョンへの更新を管理
   - 問題があれば自動でロールバック

3. **Self-healing（自己修復）**
   - Podが壊れても自動で復旧
   - これがKubernetesの重要な機能

### 例

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1  # Podを1つ作成
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

### DeploymentとPodの関係

```
Deployment (設計図)
    │
    ├─ Pod 1 (実体)
    ├─ Pod 2 (実体)  [replicas: 2の場合]
    └─ Pod 3 (実体)  [replicas: 3の場合]
```

- **Deployment**: 「Podを1つ作って維持する」という設計図
- **Pod**: 実際に動いているコンテナ

### 重要なポイント

- Podを直接削除しても、Deploymentが新しいPodを作成
- これが**Self-healing**の仕組み
- このプロジェクトで体験する重要な機能

## Service（サービス）

### とは

**Service**は、Podへの**アクセスを提供するエンドポイント**です。

### なぜ必要？

**問題**: Podは一時的で、IPアドレスが変わる可能性がある

```
Pod A (IP: 10.0.1.5) ← 削除される
Pod B (IP: 10.0.1.8) ← 新しいIP
```

**解決**: Serviceが安定したアクセスを提供

```
Service (固定IP: 10.0.0.100)
    ↓
    どのPodに転送するか管理
    ↓
Pod A または Pod B
```

### Serviceのタイプ

1. **ClusterIP**（デフォルト）
   - クラスタ内からのみアクセス可能
   - `kubectl port-forward`でローカルからアクセス

2. **NodePort**
   - クラスタ外からもアクセス可能
   - 各ノードの特定ポートで公開

3. **LoadBalancer**
   - クラウドプロバイダーのロードバランサーを使用
   - 本番環境でよく使う

### 例

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx  # このラベルを持つPodに転送
  ports:
  - port: 80
    targetPort: 80
```

### 重要なポイント

- Serviceは**ラベル**でPodを選択
- PodのIPが変わっても、Serviceは自動で新しいPodに接続
- このプロジェクトでは、`port-forward`でServiceにアクセス

## LabelsとSelectors（ラベルとセレクター）

### とは

**Labels**（ラベル）は、リソースに付ける**タグ**です。
**Selectors**（セレクター）は、ラベルでリソースを**選択**する方法です。

### なぜ必要？

Kubernetesクラスタには、多くのPodが存在します：

```
Pod: nginx-abc123 (app=nginx)
Pod: nginx-def456 (app=nginx)
Pod: redis-xyz789 (app=redis)
```

ラベルでグループ化：

```
app=nginx のPod:
  - nginx-abc123
  - nginx-def456

app=redis のPod:
  - redis-xyz789
```

### 例

**Deploymentでラベルを付ける:**
```yaml
spec:
  template:
    metadata:
      labels:
        app: nginx  # このラベルをPodに付与
```

**Serviceでラベルを選択:**
```yaml
spec:
  selector:
    app: nginx  # このラベルを持つPodに転送
```

### 重要なポイント

- **ラベル**: リソースを分類・識別する
- **セレクター**: ラベルでリソースを選択
- DeploymentとServiceは、同じラベルで連携

## ConfigMap（コンフィグマップ）

### とは

**ConfigMap**は、**設定データを保存する**リソースです。

- アプリケーションの設定ファイル
- 環境変数
- その他の設定データ

### なぜ必要？

**問題**: 設定をコンテナイメージに埋め込むと、変更のたびにイメージを再ビルドする必要がある

**解決**: ConfigMapで設定を分離

```
ConfigMap (設定)
    ↓
Pod (コンテナ)
    ↓
設定をマウントして使用
```

### 例

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>Hello</title>
    </head>
    <body>
        <h1>Hello from ConfigMap!</h1>
    </body>
    </html>
```

**DeploymentでConfigMapを使用:**
```yaml
spec:
  containers:
  - name: nginx
    volumeMounts:
    - name: nginx-config
      mountPath: /usr/share/nginx/html
  volumes:
  - name: nginx-config
    configMap:
      name: nginx-config
```

### 重要なポイント

- 設定をコンテナイメージから分離
- 設定を変更しても、イメージを再ビルドする必要がない
- このプロジェクトでは、nginxのHTMLをConfigMapで管理

## Self-healing（自己修復）

### とは

**Self-healing**は、Kubernetesが**自動的に問題を修復する**機能です。

### 仕組み

1. **望ましい状態の定義**
   ```yaml
   replicas: 1  # Podを1つ維持したい
   ```

2. **現在の状態の監視**
   ```
   現在: Pod 0個
   望ましい: Pod 1個
   → 1個足りない！
   ```

3. **自動修復**
   ```
   新しいPodを作成
   → 現在: Pod 1個
   → 望ましい: Pod 1個
   → 一致！完了
   ```

### 例

```bash
# Podを削除
kubectl delete pod nginx-abc123

# Deploymentが検知
# → Podが1個足りない
# → 新しいPodを作成
# → 数秒後、新しいPodがRunning状態に
```

### 重要なポイント

- Kubernetesの**核心的な機能**
- 手動で管理する必要がない
- このプロジェクトで実際に体験できる

## リソースの関係図

```
┌─────────────────────────────────────┐
│         ConfigMap                    │
│    (設定データ)                      │
└──────────────┬──────────────────────┘
               │
               │ マウント
               ▼
┌─────────────────────────────────────┐
│         Deployment                  │
│    (設計図: replicas=1)              │
│         ┌─────────────────┐          │
│         │  selector:      │          │
│         │  app=nginx      │          │
│         └─────────────────┘          │
└──────────────┬──────────────────────┘
               │
               │ 作成・管理
               ▼
┌─────────────────────────────────────┐
│         Pod                         │
│    (実体: nginxコンテナ)             │
│         ┌─────────────────┐          │
│         │  labels:        │          │
│         │  app=nginx      │          │
│         └─────────────────┘          │
└──────────────┬──────────────────────┘
               │
               │ ラベルで選択
               ▼
┌─────────────────────────────────────┐
│         Service                     │
│    (エンドポイント)                  │
│         ┌─────────────────┐          │
│         │  selector:      │          │
│         │  app=nginx      │          │
│         └─────────────────┘          │
└─────────────────────────────────────┘
```

## kubectlコマンドの基本

### リソースの作成

```bash
# ファイルから作成
kubectl apply -f deployment.yaml

# ディレクトリ内のすべてのファイルから作成
kubectl apply -f k8s/
```

### リソースの確認

```bash
# 一覧表示
kubectl get pods
kubectl get deployments
kubectl get services

# 詳細表示
kubectl get pods -o wide
kubectl describe pod <pod-name>

# すべてのリソース
kubectl get all
```

### ログの確認

```bash
# ログを表示
kubectl logs <pod-name>

# リアルタイムで追跡
kubectl logs -f <pod-name>
```

### リソースの削除

```bash
# ファイルから削除
kubectl delete -f deployment.yaml

# 名前で削除
kubectl delete pod <pod-name>
kubectl delete deployment nginx
```

## 重要な概念のまとめ

| 概念 | 役割 | 例 |
|------|------|-----|
| **Pod** | コンテナを実行する最小単位 | nginxコンテナを実行 |
| **Deployment** | Podの設計図、管理 | Podを1つ維持 |
| **Service** | Podへのアクセスを提供 | ポート80でアクセス |
| **ConfigMap** | 設定データを保存 | HTMLファイル |
| **Labels** | リソースを分類 | `app=nginx` |
| **Selectors** | ラベルでリソースを選択 | `app=nginx`のPodを選択 |

## 次のステップ

概念を理解したら、実際に手を動かして体験しましょう。

**次のドキュメント**: [ハンズオンガイド](./04-hands-on-guide.md)

---

**目次に戻る**: [README](./README.md)
