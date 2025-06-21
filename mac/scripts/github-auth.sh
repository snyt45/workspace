#!/usr/bin/env zsh

echo "GitHub CLI認証を設定中..."

# GitHub CLIがインストールされているか確認
if ! command -v gh &> /dev/null; then
    echo "GitHub CLIをインストール中..."
    brew install gh
else
    echo "GitHub CLIは既にインストールされています"
fi

# 既に認証済みかチェック
if gh auth status &>/dev/null; then
    echo "✅ 既にGitHubに認証済みです"
    gh auth status
else
    echo "GitHubにログインします..."
    echo "ブラウザが開きます。指示に従って認証してください。"
    gh auth login
fi

echo "✅ GitHub CLI認証の設定が完了しました"