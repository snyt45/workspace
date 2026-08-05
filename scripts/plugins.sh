#!/usr/bin/env zsh

echo "Claude Code プラグイン..."
./scripts/claude-plugins.sh

echo "Plannotator インストール..."
command -v plannotator >/dev/null || curl -fsSL https://plannotator.ai/install.sh | bash

echo "herdr プラグイン・統合..."
./scripts/herdr.sh

echo "プラグイン設定完了"
