# docker

作業用コンテナの環境構築スクリプト。

## 前提条件

- Docker Desktop

## コンテナ構成

- docker-outside-of-docker を採用
  - ホストマシンとホストマシン上の作業コンテナで別々の Docker 環境があり、ホストマシン上の作業コンテナから docker.sock を通じてホストマシン上の Docker を操作する構成にしている。
- Dockerfile はマルチステージ構成
  - マルチステージビルドはビルドした成果物を最終イメージのみに含めて最終イメージを軽量化している。
  - また、並列実行されるので高速にビルドできる。

## 使い方

```
cd ~/.dotfiles/docker
```

作業コンテナのイメージをビルド

```
make build target="workbench"

# Build with --no-cache option
make build target=workbench nocache="true"
```

作業用コンテナを起動

```
make target="workbench"

# 開放portを指定
make target="workbench" port=3030
```

作業用コンテナのイメージを削除

```
make clean target="workbench"
```

全ての docker image を削除

```
make allrmi
```

全ての docker container を削除

```
make allrm
```

make コマンドのヘルプを表示

```
make help
```
