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
# Mission Control
# システム環境設定 > デスクトップとDock > Mission Control > ウィンドウをアプリケーションごとにグループ化
defaults write com.apple.dock expose-group-apps -bool true

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

# Homebrewインストールチェックと実行
if ! command -v brew &> /dev/null; then
    echo "Homebrewをインストールしています..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 現在のシェルで有効化
    eval "$(/opt/homebrew/bin/brew shellenv)"

    echo "Homebrewのインストールが完了しました"
else
    echo "Homebrewは既にインストールされています"
fi

# install
brew install iterm2
brew install google-chrome
brew install google-japanese-ime
brew install visual-studio-code
brew install slack
brew install zoom
brew install zoxide
brew install --cask alt-tab
brew install --cask docker
brew install --cask dropbox
brew install --cask kap
brew install --cask karabiner-elements
brew install --cask raycast
brew install --cask scroll-reverser
brew install --cask tableplus

DOTFILES_DIR="$HOME/.dotfiles/mac"

# 作業データ共有用のディレクトリ
mkdir -p "$HOME/work/"
# 作業用コンテナで作業時のキャッシュを残すためのディレクトリ
mkdir -p "$HOME/.shared_cache/"

# Gitの設定
if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
    ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
fi

# SSHの設定
mkdir -p "$HOME/.ssh"
if [ -f "$DOTFILES_DIR/ssh/config" ]; then
    ln -sf "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
fi

# Karabiner-Elements設定
mkdir -p "$HOME/.config/karabiner"
if [ -f "$DOTFILES_DIR/karabiner/karabiner.json" ]; then
    ln -sf "$DOTFILES_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
fi

# Zshの設定
if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
fi

echo "セットアップが完了しました。再起動してください。"
