#!/usr/bin/env zsh

echo "herdr プラグイン・統合をインストール中..."

# 他のセットアップスクリプトと違い、ここは herdr サーバーの起動状態に依存する。
# 未起動・未インストールならエラーにせずスキップし、herdr 起動後の再実行で揃う。
if ! command -v herdr >/dev/null; then
  echo "herdr が未インストールのためスキップ"
  exit 0
fi

# herdr-browser (herdrペイン内にChromiumを描画するプラグイン、bunが必要)
plugins=$(herdr plugin list 2>&1) || {
  echo "herdr サーバー未起動のため herdr-browser をスキップ (herdr起動後に再実行)"
  plugins=
}
if [ -n "$plugins" ] && ! echo "$plugins" | grep -q "browser"; then
  herdr plugin install ogulcancelik/herdr-browser --yes
fi

# エージェント状態検知の統合 (各エージェントの設定領域にフック/拡張を生成)
# ファイル存在ガードだと旧版が更新されないため毎回実行する (冪等)
for agent in claude opencode pi; do
  command -v "$agent" >/dev/null && herdr integration install "$agent"
done

echo "herdr プラグイン・統合インストール完了"
