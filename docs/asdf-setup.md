# プログラミング言語のセットアップ

asdf でプロジェクトごとに必要な言語・バージョンを管理する。
バージョンは各リポジトリの `.tool-versions` に従う。

## asdf プラグインの追加

```sh
# 必要なプラグインを追加
asdf plugin add nodejs
asdf plugin add ruby
asdf plugin add python
asdf plugin add golang
```

## バージョンのインストール

```sh
# .tool-versions があるプロジェクトの場合
cd /path/to/project
asdf install

# .tool-versions がない場合（手動で指定）
asdf install nodejs 20.19.0
asdf set nodejs 20.19.0          # カレントディレクトリの .tool-versions に書く
asdf set --home nodejs 20.19.0   # ~/.tool-versions に書く（グローバルのデフォルト）
```

## Node.js 固有の設定

```sh
# corepack を有効化（yarn 等を使う場合）
corepack enable
asdf reshim nodejs
```
