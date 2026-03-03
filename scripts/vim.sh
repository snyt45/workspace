#!/usr/bin/env zsh
set -e

VIM_DIR="$HOME/work/vim"

if [[ ! -d "$VIM_DIR" ]]; then
  git clone https://github.com/vim/vim "$VIM_DIR"
fi

cd "$VIM_DIR"
git fetch --prune origin
git reset --hard origin/master

cd src/
make distclean

./configure \
  --enable-cscope \
  --enable-fail-if-missing \
  --with-features=huge \
  --enable-multibyte \
  --with-compiledby=snyt45

make
sudo make install
sudo ln -sf /usr/local/bin/vim /usr/local/bin/vi

vim --version | head -1
