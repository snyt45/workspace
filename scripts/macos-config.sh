#!/usr/bin/env zsh

echo "macOSのシステム設定を構成中..."

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
# システム環境設定 > キーボード > キーボードショートカット > ファンクションキー > F1,F2などのキーを標準のファンクションキーとして使用
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
# キーリピートの反応速度を最大にする
# 設定 > キーボード > キーのリピート速度（最速）
defaults write NSGlobalDomain KeyRepeat -int 2
# キーリピート開始までの時間を最短にする
# 設定 > キーボード > リピート入力認識までの時間（最短）
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Mission Control
# システム環境設定 > デスクトップとDock > Mission Control
# 最新の使用状況に基づいて操作スペースを自動的に並べる
defaults write com.apple.dock mru-spaces -bool true
# ウィンドウをアプリケーションごとにグループ化
defaults write com.apple.dock expose-group-apps -bool true
# ディスプレイごとに個別の操作スペース
defaults write com.apple.spaces spans-displays -bool true
# タイル表示されたウィンドウ間の隙間をオフにする
defaults write com.apple.WindowManager StandardGap -int 0

# ホットコーナー (すべて無効化)
# 左上：なし (1)
defaults write com.apple.dock wvous-tl-corner -int 1
defaults write com.apple.dock wvous-tl-modifier -int 0
# 左下：なし (1)
defaults write com.apple.dock wvous-bl-corner -int 1
defaults write com.apple.dock wvous-bl-modifier -int 0
# 右上：なし (1)
defaults write com.apple.dock wvous-tr-corner -int 1
defaults write com.apple.dock wvous-tr-modifier -int 0
# 右下：なし (1)
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 0

echo "✅ macOSのシステム設定が完了しました"