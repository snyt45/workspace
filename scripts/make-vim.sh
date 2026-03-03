#!/usr/bin/env zsh

# ----
# VimのHEADをビルドしてインストールする
# ----

CURRENT_DIR=`dirname $0`
CLONE_DIR=${HOME}/work
ROOT_DIR=${CLONE_DIR}/vim
MAIN_BRANCH=master

# vimリポジトリをクローン
if [ ! -d "${ROOT_DIR}" ]; then
  git clone https://github.com/vim/vim ${ROOT_DIR}
fi

cd ${ROOT_DIR}

# 最新のHEADを取得
git fetch --prune origin
git reset --hard origin/${MAIN_BRANCH}

cd src/

# ビルド環境を完全にクリーンアップ
make distclean

# Vimのビルド設定（/usr/local/binにインストール）
# --enable-cscope: ソースコード解析ツールのサポート
# --enable-fail-if-missing: 安全なビルドのための設定
# --with-features=huge: 最大機能セットでのビルド
# --enable-multibyte: 日本語サポート
# --with-compiledby=snyt45: ビルド者の識別情報
./configure \
  --enable-cscope \
  --enable-fail-if-missing \
  --with-features=huge \
  --enable-multibyte \
  --with-compiledby=snyt45

# ソースコードをコンパイル（~/work/vim/src/vim に実行ファイルを生成）
make

# コンパイル済みファイルを /usr/local/bin/ にコピーしてシステム全体で使用可能にする
# 関連ファイル（ヘルプ、設定等）も /usr/local/share/vim/ にコピーされる
sudo make install

# 元のディレクトリに戻る
cd ${CURRENT_DIR}

# viコマンドでもvimを使えるようにシンボリックリンクを作成（既存のファイルは上書き）
sudo ln -sf /usr/local/bin/vim /usr/local/bin/vi

# インストールされたVimのバージョンと機能を確認
vim --version
