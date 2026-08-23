#!/usr/bin/env zsh

echo "herdr プラグイン・統合をインストール中..."

# 他のセットアップスクリプトと違い、ここは herdr サーバーの起動状態に依存する。
# 未起動・未インストールならエラーにせずスキップし、herdr 起動後の再実行で揃う。
if ! command -v herdr >/dev/null; then
  echo "herdr が未インストールのためスキップ"
  exit 0
fi

# terminal-code / terminal-browser (herdrペイン内でVS Code/ブラウザを開くプラグイン)
# プラグインのビルド時に実体 (tode / terminal-browser) が ~/.local/bin へ自動インストールされる
plugins=$(herdr plugin list 2>&1) || {
  echo "herdr サーバー未起動のためプラグインをスキップ (herdr起動後に再実行)"
  plugins=
}
if [ -n "$plugins" ]; then
  echo "$plugins" | grep -q "zenbu-labs.tode" || herdr plugin install zenbu-labs/terminal-code/herdr-plugin --yes
  echo "$plugins" | grep -q "zenbu-labs.terminal-browser" || herdr plugin install zenbu-labs/terminal-browser/herdr-plugin --yes
fi

# エージェント状態検知の統合 (各エージェントの設定領域にフック/拡張を生成)
# ファイル存在ガードだと旧版が更新されないため毎回実行する (冪等)
for agent in claude opencode pi; do
  command -v "$agent" >/dev/null && herdr integration install "$agent"
done

echo "herdr プラグイン・統合インストール完了"
