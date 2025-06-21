#!/usr/bin/env zsh

echo "Rosetta 2をインストール中..."

# Intel用アプリのためにRosettaをインストール
arch_name="$(uname -m)"
if [ "${arch_name}" = "arm64" ]; then
    # Rosettaがインストールされているか確認
    if ! /usr/bin/pgrep -q oahd; then
        echo "Rosettaをインストールしています..."
        softwareupdate --install-rosetta --agree-to-license
    else
        echo "Rosettaは既にインストールされています"
    fi
else
    echo "Intel Macのため、Rosettaのインストールは不要です"
fi

echo "✅ Rosetta 2の設定が完了しました"