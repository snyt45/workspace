#!/usr/bin/env zsh

echo "macOS システム設定..."
./scripts/macos.sh

echo "Rosetta 2 インストール..."
/usr/bin/pgrep -q oahd || softwareupdate --install-rosetta --agree-to-license

echo "GitHub CLI 認証..."
gh auth status 2>/dev/null || gh auth login

echo "システム設定完了"
