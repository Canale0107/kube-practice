# セットアップガイド

この章では、Kubernetesを学習するための環境を構築します。macOSとLinuxの両方に対応した手順を説明します。

## 必要なツール

以下の3つのツールが必要です：

1. **Docker** - コンテナを実行する
2. **kind** - ローカルKubernetesクラスタを作成
3. **kubectl** - Kubernetesを操作する

## 1. Dockerのインストール

### macOS

#### 方法1: Docker Desktop（推奨）

1. [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)をダウンロード
2. `.dmg`ファイルを開いてインストール
3. アプリケーションからDocker Desktopを起動
4. メニューバーにDockerアイコンが表示されれば起動完了

#### 方法2: Homebrew

```bash
brew install --cask docker
```

その後、アプリケーションからDocker Desktopを起動してください。

### Linux

#### Ubuntu/Debian

```bash
# 古いバージョンを削除（既にインストールされている場合）
sudo apt-get remove docker docker-engine docker.io containerd runc

# 必要なパッケージをインストール
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Dockerの公式GPGキーを追加
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# リポジトリを追加
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker Engineをインストール
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 現在のユーザーをdockerグループに追加（sudoなしで実行できるように）
sudo usermod -aG docker $USER

# ログアウトして再ログイン（または新しいターミナルを開く）
```

#### その他のLinuxディストリビューション

[公式インストールガイド](https://docs.docker.com/engine/install/)を参照してください。

### 動作確認

```bash
docker --version
docker ps
```

`docker ps`がエラーなく実行できれば、Dockerが正しくインストール・起動されています。

**よくあるエラー:**
- `Cannot connect to the Docker daemon`: Dockerが起動していません。Docker Desktop（macOS）またはDockerサービス（Linux）を起動してください。
- `permission denied`: Linuxの場合、ユーザーをdockerグループに追加し、再ログインしてください。

## 2. kindのインストール

kind（Kubernetes in Docker）は、Dockerコンテナ内にKubernetesクラスタを作成するツールです。

### macOS

#### Homebrew（推奨）

```bash
brew install kind
```

#### 手動インストール

```bash
# 最新バージョンを確認: https://github.com/kubernetes-sigs/kind/releases
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Linux

#### 手動インストール

```bash
# 最新バージョンを確認: https://github.com/kubernetes-sigs/kind/releases
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

#### パッケージマネージャー（一部のディストリビューション）

```bash
# Arch Linux
yay -S kind-bin

# Nix
nix-env -i kind
```

### 動作確認

```bash
kind --version
```

バージョンが表示されれば、インストール成功です。

## 3. kubectlのインストール

kubectlは、Kubernetesクラスタを操作するコマンドラインツールです。

### macOS

#### Homebrew（推奨）

```bash
brew install kubectl
```

#### 手動インストール

```bash
# 最新バージョンを確認: https://kubernetes.io/releases/
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

### Linux

#### 手動インストール

```bash
# 最新バージョンを確認: https://kubernetes.io/releases/
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

#### パッケージマネージャー

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y kubectl

# Red Hat/CentOS
sudo yum install -y kubectl

# Arch Linux
sudo pacman -S kubectl
```

### 動作確認

```bash
kubectl version --client
```

クライアントバージョンが表示されれば、インストール成功です。

## 4. すべてのツールの確認

以下のコマンドで、すべてのツールが正しくインストールされているか確認できます：

```bash
# Docker
docker --version
docker ps

# kind
kind --version

# kubectl
kubectl version --client
```

すべてのコマンドがエラーなく実行できれば、準備完了です！

## 5. テストクラスタの作成（オプション）

環境が正しく構築されているか、簡単なテストを実行できます：

```bash
# テストクラスタを作成
kind create cluster --name test

# クラスタ情報を確認
kubectl cluster-info

# ノードを確認
kubectl get nodes

# テストクラスタを削除
kind delete cluster --name test
```

すべてのコマンドが成功すれば、環境は正しく構築されています。

## トラブルシューティング

### Dockerが起動しない（macOS）

**症状**: `docker ps`でエラーが出る

**解決方法**:
1. Docker Desktopが起動しているか確認（メニューバーのアイコンを確認）
2. アプリケーションからDocker Desktopを再起動
3. システムの再起動を試す

### Dockerの権限エラー（Linux）

**症状**: `permission denied while trying to connect to the Docker daemon socket`

**解決方法**:
```bash
# ユーザーをdockerグループに追加
sudo usermod -aG docker $USER

# ログアウトして再ログイン（または新しいターミナルを開く）
# 確認
groups  # dockerグループが表示されればOK
```

### kindコマンドが見つからない

**症状**: `command not found: kind`

**解決方法**:
1. インストールが完了しているか確認
2. PATHに含まれているか確認: `echo $PATH`
3. 手動でインストールした場合、`/usr/local/bin`に移動したか確認

### kubectlのバージョンが古い

**症状**: 一部のコマンドが動作しない

**解決方法**:
```bash
# 最新版をインストール（上記のインストール手順を再実行）
# または、Homebrewで更新
brew upgrade kubectl
```

## 次のステップ

環境のセットアップが完了したら、Kubernetesの基本概念を学びましょう。

**次のドキュメント**: [Kubernetes基本概念](./03-kubernetes-basics.md)

---

**目次に戻る**: [README](./README.md)
