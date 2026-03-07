# nvm で Node 14 をセットアップする（Apple Silicon）

Node 14 は Apple Silicon (arm64) 向けのプリビルドバイナリが存在しない。
ソースビルドも現在の Xcode (Clang 16) と非互換でコンパイルエラーになる。
x64 バイナリを手動で配置し、Rosetta 2 経由で動かす方法で対処する。

## 前提

- macOS (Apple Silicon)
- Rosetta 2 がインストール済み
- Homebrew がインストール済み

Rosetta 2 が未インストールの場合:

```bash
softwareupdate --install-rosetta
```

## 手順

### 1. nvm のインストール

```bash
brew install nvm
mkdir -p ~/.nvm
```

### 2. シェル設定に追記

`.zshrc` に以下を追加:

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
```

追加後、設定を反映:

```bash
source ~/.zshrc
```

### 3. Node 14 の x64 バイナリを手動で配置

`nvm install 14` は arm64 バイナリがないためソースビルドに回り失敗する。
x64 バイナリを直接ダウンロードして nvm のディレクトリに配置する。

```bash
mkdir -p ~/.nvm/versions/node/v14.19.3
curl -L https://nodejs.org/dist/v14.19.3/node-v14.19.3-darwin-x64.tar.gz \
  | tar xz --strip-components=1 -C ~/.nvm/versions/node/v14.19.3
```

### 4. 動作確認

```bash
nvm use 14.19.3
node --version  # v14.19.3
```

## なぜ通常の方法では入らないか

- arm64 プリビルドバイナリ: Node 14 には存在しない
- ソースビルド: Python 3.10 以下にすれば configure は通るが、Clang 16 の C++ コンパイルで V8 エンジンのビルドが失敗する（-Wenum-constexpr-conversion エラー）
- nvm の `--architecture x64` オプション: バイナリが見つからないとソースビルドにフォールバックして同じ問題が起きる

## プロジェクトごとの Node バージョン切替

### .nvmrc の配置

Node 14 を使うプロジェクトのルートに `.nvmrc` を置く:

```
14.19.3
```

これでプロジェクトディレクトリに移動してから `nvm use` を実行すると `.nvmrc` を読んで切り替わる。

### nvm と mise の切替

nvm を読み込むと PATH に nvm の Node が入るため、他のディレクトリでも nvm の Node が使われてしまう。
mise 管理の Node に戻したい場合は `nvm deactivate` を実行する。

```bash
# Node 14 プロジェクトで作業開始
cd ~/work/toypo4store-web
nvm use           # .nvmrc を読んで v14.19.3 に切替

# 別プロジェクトに移動して mise の Node に戻す
cd ~/work/other-project
nvm deactivate    # nvm の Node を PATH から外す
```

## mise との併用

`.tool-versions` に `nodejs` を記載すると mise が管理しようとして失敗する。
Node 14 は nvm で管理し、`.tool-versions` からは `nodejs` の行を外しておく。
