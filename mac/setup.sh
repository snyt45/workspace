#!/usr/bin/env zsh

# Mac Setting
# Finder: パスバーを表示
defaults write com.apple.finder ShowPathbar -bool true
# Finder: 隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -bool true
# Finder: 拡張子を表示
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# メニューバーにサウンドを表示する
# システム環境設定 > コントロールセンター > サウンド > メニューバーに常に表示
defaults -currentHost write com.apple.controlcenter Sound -int 18
defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true
defaults write com.apple.controlcenter "NSStatusItem Preferred Position Sound" -float 100
# ファンクションキーを有効にする
# システム環境設定 > キーボード > キーボードショートカット > ファンクションキー > 
# F1,F2などのキーを標準のファンクションキーとして使用
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
# キーリピートの反応速度を最大にする
# 設定 > キーボード > キーのリピート速度（最速）
defaults write NSGlobalDomain KeyRepeat -int 2
# キーリピート開始までの時間を最短にする
# 設定 > キーボード > リピート入力認識までの時間（最短）
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Mission Control
# システム環境設定 > デスクトップとDock > Mission Control > ウィンドウをアプリケーションごとにグループ化
defaults write com.apple.dock expose-group-apps -bool true
# タイル表示されたウィンドウ間の隙間をオフにする
defaults write com.apple.WindowManager StandardGap -int 0

# Intel用アプリのためにRosettaをインストール
echo "Rosettaをインストール中..."
arch_name="$(uname -m)"
if [ "${arch_name}" = "arm64" ]; then
    # Rosettaがインストールされているか確認
    if ! /usr/bin/pgrep -q oahd; then
        echo "Rosettaをインストールしています..."
        softwareupdate --install-rosetta --agree-to-license
    else
        echo "Rosettaは既にインストールされています"
    fi
else
    echo "Intel Macのため、Rosettaのインストールは不要です"
fi

# install
brew install asdf
brew install diff-so-fancy
brew install fzf
brew install warp
brew install google-chrome
brew install google-japanese-ime
brew install visual-studio-code
brew install ripgrep
brew install slack
brew install tmux
brew install zoom
brew install zoxide
brew install socat
brew install starship
brew install --cask alt-tab
brew install --cask deepl
brew install --cask docker
brew install --cask dropbox
brew install --cask gather
brew install --cask kap
brew install --cask karabiner-elements
brew install --cask raycast
brew install --cask scroll-reverser
brew install --cask tableplus

# node
asdf plugin add nodejs
asdf install nodejs 14.21.0
asdf install nodejs 16.20.2
# yarn を使えるようにする
corepack enable
asdf reshim nodejs
# ruby
asdf plugin add ruby
asdf install ruby 2.7.2
# python
asdf plugin add python
asdf install python 2.7.18

DOTFILES_DIR="$HOME/.dotfiles/mac"

# 作業データ共有用のディレクトリ
mkdir -p "$HOME/work/"
# 作業用コンテナで作業時のキャッシュを残すためのディレクトリ
mkdir -p "$HOME/.shared_cache/"

# Gitの設定
cp "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# SSHの設定
mkdir -p "$HOME/.ssh"
cp "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"

# Vimの設定
mkdir -p "$HOME/.vim"
mkdir -p "$HOME/.vim/autoload/"
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p "$HOME/.vim/config/"
ln -sf "$DOTFILES_DIR/.vim/vimrc" "$HOME/.vim/"
ln -sf "$DOTFILES_DIR/.vim/config/.ctrlp-launcher" "$HOME/.vim/config/"

# Tmuxの設定
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Karabiner-Elements設定
mkdir -p "$HOME/.config/karabiner"
ln -sf "$DOTFILES_DIR/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

# Zshの設定
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# bin
mkdir -p "$HOME/bin"
ln -sf "$DOTFILES_DIR/bin/ide" "$HOME/bin/"

echo "セットアップが完了しました。再起動してください。"
