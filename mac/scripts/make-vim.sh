#!/usr/bin/env zsh

# ----
# VimのHEADをビルドしてインストールする
# ----

# Variables {{{

CURRENT_DIR=`dirname $0`
CLONE_DIR=${HOME}/work
ROOT_DIR=${CLONE_DIR}/vim
MAIN_BRANCH=master

# }}}

# Main {{{

if [ ! -d "${ROOT_DIR}" ]; then
  git clone https://github.com/vim/vim ${ROOT_DIR}
fi

cd ${ROOT_DIR}

git fetch --prune origin
git rebase origin/${MAIN_BRANCH}

cd src/

make distclean

# prefixを指定しない場合は/usr/local/binにインストールされる
./configure \
  --enable-cscope \
  --enable-fail-if-missing \
  --with-features=huge \
  --enable-multibyte \
  --with-compiledby=snyt45 \

make

sudo make install

cd ${CURRENT_DIR}

sudo ln -s /usr/local/bin/vim /usr/local/bin/vi

vim --version

# }}}
