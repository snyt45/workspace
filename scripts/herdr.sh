#!/usr/bin/env zsh

echo "herdr プラグイン・統合をインストール中..."

# 他のセットアップスクリプトと違い、ここは herdr サーバーの起動状態に依存する。
# 未起動・未インストールならエラーにせずスキップし、herdr 起動後の再実行で揃う。
if ! command -v herdr >/dev/null; then
  echo "herdr が未インストールのためスキップ"
  exit 0
fi

# herdr-browser (herdrペイン内にChromiumを描画するプラグイン、bunが必要)
if ! herdr plugin list >/dev/null 2>&1; then
  echo "herdr サーバー未起動のため herdr-browser をスキップ (herdr起動後に再実行)"
elif ! herdr plugin list 2>/dev/null | grep -q "browser"; then
  herdr plugin install ogulcancelik/herdr-browser --yes
fi

# piの状態検知統合 (~/.pi/agent/extensions/herdr-agent-state.ts を生成)
if command -v pi >/dev/null; then
  mkdir -p "$HOME/.pi/agent/extensions"
  [[ -f "$HOME/.pi/agent/extensions/herdr-agent-state.ts" ]] || herdr integration install pi
fi

echo "herdr プラグイン・統合インストール完了"
