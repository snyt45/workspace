# docker

作業用コンテナの環境構築スクリプト。

## 前提条件

- Docker Desktop

## コンテナ構成

docker-outside-of-docker を採用している。
ホストマシンとホストマシン上の作業コンテナで別々の Docker 環境があり、ホストマシン上の作業コンテナから docker.sock を通じてホストマシン上の Docker を操作する構成にしている。

Dockerfile はマルチステージ構成にしている。ステージは 2 階層に分けており、base ステージと workbench ステージが存在する。workbench ステージは base ステージを継承している。
マルチステージビルドはビルドした成果物を最終イメージのみに含めて最終イメージを軽量化する目的に使用されるが、ここでは単純にレイヤーを分けて変更が少ない箇所と多い箇所を分けることが目的。変更が入ると後続のキャッシュが効かなくなるので base ステージは極力変更が入らないレイヤーにする。

- 共通ステージ
  - base
- 作業ステージ
  - workbench

## 使い方

```
cd ~/.dotfiles/docker
```

作業コンテナのイメージをビルド

```
make build target="workbench"
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

プロジェクト毎に Git の設定を行う。

```
git config --local user.name "pj.tarou"
git config --local user.email "pj@example.com"
```
