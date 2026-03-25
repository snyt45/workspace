#!/usr/bin/env zsh

echo "Claude Code MCPサーバを設定中..."

# context7 (ライブラリドキュメント検索)
# APIキーは https://context7.com/dashboard で取得
if ! grep -q '"context7"' ~/.claude.json 2>/dev/null; then
  echo "context7: APIキーを入力してください（未取得なら https://context7.com/dashboard）"
  read -r "api_key?API Key: "
  claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key "$api_key"
else
  echo "context7: 設定済みのためスキップ"
fi

# figma (Figmaデザインデータ取得)
# APIキーは1Password経由で解決（op://Development/figma/credential）
if ! grep -q '"figma"' ~/.claude.json 2>/dev/null; then
  claude mcp add figma -s user -e FIGMA_API_KEY=op://Development/figma/credential -- op run --no-masking -- npx -y figma-developer-mcp --stdio
  echo "figma: 設定完了"
else
  echo "figma: 設定済みのためスキップ"
fi

echo "Claude Code MCPサーバ設定完了"
