#!/usr/bin/env zsh

# Finder > パスバー表示 / 隠しファイル表示 / 拡張子表示
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# コントロールセンター > サウンド > メニューバーに常に表示
defaults -currentHost write com.apple.controlcenter Sound -int 18
defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool true
defaults write com.apple.controlcenter "NSStatusItem Preferred Position Sound" -float 100

# キーボード > F1,F2などを標準のファンクションキーとして使用
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
# キーボード > リピート速度（最速）/ 認識までの時間（最短）
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# デスクトップとDock > Mission Control
# 使用状況に基づいてスペースを並べ替え / アプリごとにグループ化 / ディスプレイごとに個別スペース / タイル間の隙間なし
defaults write com.apple.dock mru-spaces -bool true
defaults write com.apple.dock expose-group-apps -bool true
defaults write com.apple.spaces spans-displays -bool false
defaults write com.apple.WindowManager StandardGap -int 0

# ホットコーナー（すべて無効化）
for corner in tl bl tr br; do
  defaults write com.apple.dock "wvous-${corner}-corner" -int 1
  defaults write com.apple.dock "wvous-${corner}-modifier" -int 0
done
