#!/usr/bin/env zsh

echo "herdr 統合をインストール中..."

# 他のセットアップスクリプトと違い、ここは herdr サーバーの起動状態に依存する。
# 未起動・未インストールならエラーにせずスキップし、herdr 起動後の再実行で揃う。
if ! command -v herdr >/dev/null; then
  echo "herdr が未インストールのためスキップ"
  exit 0
fi

# エージェント状態検知の統合 (Claude Code の設定領域にフックを生成)
# ファイル存在ガードだと旧版が更新されないため毎回実行する (冪等)
command -v claude >/dev/null && herdr integration install claude

echo "herdr 統合インストール完了"
