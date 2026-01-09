# ハンズオンガイド

この章では、このプロジェクトを使って実際にKubernetesを操作します。各ステップで何が起こっているのか、なぜそのコマンドを実行するのかを詳しく説明します。

## 準備

### プロジェクトの確認

まず、プロジェクトの構造を確認しましょう：

```bash
cd /path/to/kube-practice
ls -la
```

以下のような構造になっているはずです：

```
kube-practice/
├── README.md
├── k8s/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── scripts/
    ├── bootstrap.sh
    ├── deploy.sh
    ├── observe.sh
    ├── chaos.sh
    └── cleanup.sh
```

### 依存関係の確認

すべてのツールがインストールされているか確認：

```bash
./scripts/bootstrap.sh
```

このスクリプトは、依存関係を確認してからクラスタを作成します。エラーが出た場合は、[セットアップガイド](./02-setup.md)を参照してください。

## ステップ1: クラスタの作成

### 実行

```bash
./scripts/bootstrap.sh
```

### 何が起こっているか

1. **依存関係の確認**
   - Docker、kind、kubectlがインストールされているか確認
   - Dockerが起動しているか確認

2. **クラスタの作成**
   ```bash
   kind create cluster --name kube-practice
   ```
   - Dockerコンテナ内にKubernetesクラスタを作成
   - Master NodeとWorker Nodeが作成される

3. **コンテキストの設定**
   ```bash
   kubectl cluster-info --context kind-kube-practice
   ```
   - kubectlがどのクラスタを操作するか設定

### 出力の読み方

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

- `✓`: 成功したステップ
- 各ステップで、クラスタのコンポーネントが準備される

### 確認

クラスタが正しく作成されたか確認：

```bash
kubectl get nodes
```

**期待される出力:**
```
NAME                 STATUS   ROLES           AGE   VERSION
kube-practice-control-plane   Ready    control-plane   30s   v1.27.3
```

- `STATUS: Ready`: ノードが正常に動作している
- `ROLES: control-plane`: Master Node（管理ノード）

## ステップ2: マニフェストファイルの確認

デプロイする前に、マニフェストファイルを確認しましょう。

### ConfigMap

```bash
cat k8s/configmap.yaml
```

**重要なポイント:**
- `data.index.html`: nginxが表示するHTMLファイル
- この設定がPodにマウントされる

### Deployment

```bash
cat k8s/deployment.yaml
```

**重要なポイント:**
- `replicas: 1`: Podを1つ作成
- `selector.matchLabels.app: nginx`: ラベルでPodを選択
- `template.metadata.labels.app: nginx`: Podに付与するラベル
- `volumeMounts`: ConfigMapをマウント

### Service

```bash
cat k8s/service.yaml
```

**重要なポイント:**
- `type: ClusterIP`: クラスタ内からのみアクセス可能
- `selector.app: nginx`: このラベルを持つPodに転送
- `ports.port: 80`: Serviceのポート
- `ports.targetPort: 80`: Podのコンテナポート

## ステップ3: デプロイ

### 実行

```bash
./scripts/deploy.sh
```

### 何が起こっているか

1. **マニフェストの適用**
   ```bash
   kubectl apply -f k8s/
   ```
   - ConfigMap、Deployment、Serviceが作成される
   - Kubernetesが「望ましい状態」を認識

2. **Podの作成**
   - DeploymentがPodを作成
   - コンテナイメージ（nginx）をPull
   - Podが起動

3. **Ready状態の待機**
   ```bash
   kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s
   ```
   - PodがReady状態になるまで待つ
   - タイムアウトは60秒

### 出力の読み方

```
configmap/nginx-config created
deployment.apps/nginx created
service/nginx-service created

Waiting for Pod to be ready...
pod/nginx-xxxxxxxxxx-xxxxx condition met
```

- `created`: リソースが作成された
- `condition met`: PodがReady状態になった

### 確認

リソースが作成されたか確認：

```bash
kubectl get all
```

**期待される出力:**
```
NAME                        READY   STATUS    RESTARTS   AGE
pod/nginx-xxxxxxxxxx-xxxxx  1/1     Running   0          30s

NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/nginx-service   ClusterIP   10.96.xxx.xxx  <none>        80/TCP    30s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           30s
```

- `pod/nginx-...`: 実行中のPod
- `service/nginx-service`: Service
- `deployment.apps/nginx`: Deployment

## ステップ4: 観測

### 実行

```bash
./scripts/observe.sh
```

### 何が起こっているか

このスクリプトは、以下のコマンドを順番に実行します：

1. **Pod一覧（簡易）**
   ```bash
   kubectl get pods
   ```
   - 基本的な情報を表示

2. **Pod一覧（詳細）**
   ```bash
   kubectl get pods -o wide
   ```
   - IPアドレス、ノード名なども表示

3. **関連リソース一覧**
   ```bash
   kubectl get deploy,rs,pod -l app=nginx
   ```
   - Deployment、ReplicaSet、Podをまとめて表示
   - ラベルでフィルタリング

4. **Serviceの確認**
   ```bash
   kubectl get svc nginx-service
   ```
   - Serviceの状態を確認

5. **ConfigMapの確認**
   ```bash
   kubectl get configmap nginx-config
   ```
   - ConfigMapの存在を確認

6. **Podの詳細**
   ```bash
   kubectl describe pod <pod-name>
   ```
   - イベント、設定、状態などの詳細情報

7. **ログの確認**
   ```bash
   kubectl logs <pod-name> --tail=10
   ```
   - 最新10行のログを表示

### 出力の読み方

**Pod一覧:**
```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-xxxxxxxxxx-xxxxx  1/1     Running   0          30s
```

- `NAME`: Podの名前
- `READY: 1/1`: 1つのコンテナがReady状態（1つ中1つ）
- `STATUS: Running`: Podが実行中
- `RESTARTS: 0`: 再起動回数
- `AGE: 30s`: 作成からの経過時間

**Pod詳細（-o wide）:**
```
NAME                    READY   STATUS    IP          NODE
nginx-xxxxxxxxxx-xxxxx  1/1     Running   10.244.0.5  kube-practice-control-plane
```

- `IP: 10.244.0.5`: PodのIPアドレス
- `NODE: kube-practice-control-plane`: 実行されているノード

**Service:**
```
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
nginx-service   ClusterIP   10.96.xxx.xxx  <none>        80/TCP    30s
```

- `CLUSTER-IP: 10.96.xxx.xxx`: クラスタ内でのIPアドレス
- `PORT(S): 80/TCP`: ポート80でTCP接続を受け付ける

## ステップ5: Self-healingの体験

### 実行

```bash
./scripts/chaos.sh
```

### 何が起こっているか

1. **現在のPodを確認**
   ```bash
   kubectl get pods -l app=nginx
   ```
   - 実行中のPodを確認

2. **Podを削除**
   ```bash
   kubectl delete pod <pod-name>
   ```
   - Podを強制的に削除

3. **Deploymentの反応**
   - Deploymentが「Podが1個足りない」と検知
   - 自動的に新しいPodを作成

4. **新しいPodの起動**
   - 数秒後、新しいPodがRunning状態に

### 出力の読み方

**削除直後:**
```
NAME                    READY   STATUS        RESTARTS   AGE
nginx-xxxxxxxxxx-yyyyy  0/1     ContainerCreating   0          1s
nginx-xxxxxxxxxx-xxxxx  1/1     Terminating         0          30s
```

- `Terminating`: 削除中のPod
- `ContainerCreating`: 作成中の新しいPod

**数秒後:**
```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-xxxxxxxxxx-yyyyy  1/1     Running   0          5s
```

- `Running`: 新しいPodが実行中
- 古いPodは消えている

### なぜこれが重要か

- **Self-healing**: Kubernetesの核心的な機能
- **高可用性**: アプリケーションが自動的に復旧
- **運用の自動化**: 手動で対応する必要がない

## ステップ6: リアルタイム観測（オプション）

### watchコマンドがある場合

```bash
watch -n 2 kubectl get pods
```

- 2秒ごとにPodの状態を更新表示
- `Ctrl+C`で終了

### watchコマンドがない場合

```bash
kubectl get pods -w
```

- 状態が変わるたびに更新表示
- `Ctrl+C`で終了

### ループで代替

```bash
while true; do
  clear
  kubectl get pods
  sleep 2
done
```

- 2秒ごとに画面をクリアして再表示
- `Ctrl+C`で終了

## ステップ7: アクセス確認

### port-forwardの実行

**別ターミナルで実行:**

```bash
kubectl port-forward service/nginx-service 8080:80
```

### 何が起こっているか

- ローカルマシンのポート8080を、Serviceのポート80に転送
- ブラウザやcurlで`http://localhost:8080`にアクセスできる

### アクセス

**curlで確認:**
```bash
curl http://localhost:8080
```

**ブラウザで確認:**
- `http://localhost:8080`にアクセス
- ConfigMapで定義したHTMLが表示される

### 出力の確認

HTMLが正しく表示されれば成功です。文字化けしている場合は、ConfigMapに`<meta charset="UTF-8">`が含まれているか確認してください。

## ステップ8: 手動操作の練習

### Podの詳細を確認

```bash
# Pod名を取得
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
echo $POD_NAME

# 詳細を確認
kubectl describe pod $POD_NAME
```

**重要な情報:**
- `Events`: Podの作成・起動に関するイベント
- `Containers`: コンテナの状態
- `Volumes`: マウントされているボリューム

### ログの確認

```bash
kubectl logs $POD_NAME
kubectl logs $POD_NAME -f  # リアルタイム追跡
```

**ログの内容:**
- nginxのアクセスログ
- エラーログ（あれば）

### コンテナ内に入る（オプション）

```bash
kubectl exec -it $POD_NAME -- /bin/bash
```

**コンテナ内で実行できること:**
```bash
# ファイルの確認
ls -la /usr/share/nginx/html/

# HTMLファイルの確認
cat /usr/share/nginx/html/index.html

# 終了
exit
```

### YAML形式で確認

```bash
# Podの設定をYAML形式で表示
kubectl get pod $POD_NAME -o yaml

# Deploymentの設定をYAML形式で表示
kubectl get deployment nginx -o yaml
```

**用途:**
- 実際の設定を確認
- 設定の理解を深める
- トラブルシューティング

## ステップ9: 変更の体験

### ConfigMapの変更

1. **ConfigMapを編集**
   ```bash
   # エディタで開く
   nano k8s/configmap.yaml
   # または
   code k8s/configmap.yaml
   ```

2. **HTMLを変更**
   ```yaml
   data:
     index.html: |
       <!DOCTYPE html>
       <html>
       <head>
           <meta charset="UTF-8">
           <title>Changed!</title>
       </head>
       <body>
           <h1>I changed this!</h1>
       </body>
       </html>
   ```

3. **適用**
   ```bash
   kubectl apply -f k8s/configmap.yaml
   ```

4. **Podを再起動**
   ```bash
   kubectl rollout restart deployment/nginx
   ```

5. **確認**
   - ブラウザをリロード
   - 変更が反映されているか確認

### なぜPodを再起動する必要があるか

- ConfigMapはボリュームとしてマウントされる
- 既存のPodは古いConfigMapを参照している
- 新しいPodを作成すると、新しいConfigMapが反映される

## ステップ10: 後片付け

### 実行

```bash
./scripts/cleanup.sh
```

### 何が起こっているか

1. **確認プロンプト**
   - クラスタを削除してよいか確認

2. **クラスタの削除**
   ```bash
   kind delete cluster --name kube-practice
   ```
   - すべてのリソースが削除される
   - Dockerコンテナも削除される

### 確認

```bash
kind get clusters
```

何も表示されなければ、クラスタは削除されています。

## よくある質問

### Q: PodがPending状態のまま

**確認:**
```bash
kubectl describe pod <pod-name>
```

**よくある原因:**
- イメージのPullに失敗
- リソース不足
- ノードの準備ができていない

### Q: Serviceに接続できない

**確認:**
```bash
# Serviceが存在するか
kubectl get svc

# PodがRunningか
kubectl get pods

# port-forwardを再実行
kubectl port-forward service/nginx-service 8080:80
```

### Q: ログが見えない

**確認:**
```bash
# PodがRunningか
kubectl get pods

# ログを確認
kubectl logs <pod-name>

# リアルタイムで確認
kubectl logs -f <pod-name>
```

## 次のステップ

ハンズオンが完了したら、トラブルシューティングの詳細を学びましょう。

**次のドキュメント**: [トラブルシューティング](./05-troubleshooting.md)

---

**目次に戻る**: [README](./README.md)
