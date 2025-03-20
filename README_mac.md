# mac 用の構築手順

## 前提条件

- MacBookPro(M4)
- macOS Sequoia 15 系

## 1. リストア手順

1. システム環境設定 > 一般 > 転送またはリセット > すべてのコンテンツと設定を消去
2. Mac をアクティブ化するために Wi-Fi を選択し、再起動をクリックします。
3. 再起動後、セットアップアシスタントに従って Mac をセットアップしてください。

## 2. Mac の環境構築

homebrew をインストールする。

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Mac ホスト用のセットアップを行うため、Git をインストールする。

```
brew install git
git config --global user.name "yuta.sano"
git config --global user.email "snyt45@gmail.com"
```

Mac ホスト用のセットアップを行うため、リポジトリをクローンする。

```
git clone https://github.com/snyt45/workspace.git $HOME/.dotfiles
```

Mac ホスト用の設定とツール群のインストールを行う。

```
cd $HOME/.dotfiles/mac
./setup.sh
```

GitHub の SSH key の設定を行う。

```
# `~/.ssh`にSSH keyをコピー
# 適切なパーミッションに設定
chmod 600 <SSH key>

# 接続確認
ssh -T git@<user name>
```

### 手動インストール

#### Ankerwork

Anker の WEB カメラ「Anker PowerConf C300」のアプリ。

Mac を選択してダウンロードする。

https://us.ankerwork.com/pages/download-software

#### KensingtonWorks

SlimBlade Pro トラックボールのアプリ。

ページ下部の「マニュアル＆サポート」の「Kensington Konnect Trackballs for Mac 1.0.0」からダウンロードする。

https://www.kensington.com/ja-jp/p/%E8%A3%BD%E5%93%81/%E3%82%B3%E3%83%B3%E3%83%88%E3%83%AD%E3%83%BC%E3%83%AB/%E3%83%88%E3%83%A9%E3%83%83%E3%82%AF%E3%83%9C%E3%83%BC%E3%83%AB/slimblade-pro%E3%83%88%E3%83%A9%E3%83%83%E3%82%AF%E3%83%9C%E3%83%BC%E3%83%AB3/

#### Tana

公式ホームページから直接ダウンロードする。

https://tana.inc/

### ソフトウェアの設定

※★ はセットアップ時の優先度

#### Alt Tab（★）

- 環境設定 > ショートカットキー 1
  - 起動ショートカット
    - [Command] and [Tab]

#### Ankerwork

- 解像度を「720P」、画角とフレームを「78°」にする

#### Docker Desktop for Mac

- 起動する
- Settings > General > Start Docker Desktop when you sign in your computer を on

#### Dropbox

- ファイルの同期方法を選択する > ファイルを`ローカル`に設定する
- PC をバックアップしないで続ける

#### Karabiner Elements（★★）

- 起動する

#### Google Chrome（★）

- 規定のアプリに設定
- 各アカウントでサインイン
- 設定 > プライバシーとセキュリティ > 広告プライバシー > 広告のトピック > OFF

#### Google 日本語入力（★★）

- システム環境設定 > キーボード > 入力ソース > 編集
  - 「+」ボタンで日本語の入力ソースを追加
    - カタカナ（Google）
    - ひらがな（Google）
    - 全角英数（Google）
    - 半角カナ（Google）
  - 「+」ボタンで英語の入力ソースを追加
    - 英数（Google）
  - 「-」ボタンでデフォルトの日本語の入力ソースを削除
- 右上の IME アイコンをクリック > 環境設定 > 一般
  - スペースの入力
    - 半角

参考 URL：https://zenn.dev/kanazawa/articles/83d56e6f12bd4c

#### kap

- 起動する

#### Rectangle(★)

- Mac の設定を無効化する
- ショートカットキーの設定
  - 左半分：Command + Shift + H
  - 右半分：Command + Shift + L
  - 左上：Command + Shift + U
  - 右上：Command + Shift + I
  - 左下：Command + Shift + J
  - 右下：Command + Shift + K
  - 最大化：Command + Shift + Enter
- ログイン時に起動を on

#### Scroll Reverser（★★）

- Scroll Reverser を起動する
- スクロール
  - アクセシビリティのアクセスを有効にする
  - Scroll Reverser を動作させるにチェックを入れる
    - スクロール方向
      - 縦方向を逆にする にチェック。それ以外はオフ。
    - スクロールデバイス
      - マウスを逆にする にチェック。それ以外はオフ。
- アプリ
  - ログイン時に開始にチェックを入れる

参考 URL：https://qiita.com/kapioz/items/54acca6126e43456a835

#### Slack

- 各アカウントでサインイン

#### SlimBlade Pro（★★）

- KensingtonWorks で設定する
  - ボタン
    - 左上
      - バック
    - 右上
      - フォワード
  - ポインター
    - デフォルトの速度
      - 加速を有効にする、デフォルトの速度+2

#### Visual Studio Code

- 左下のアカウントマークからバックアップ&設定同期を行う。
  - 設定同期後、VSCode を再起動する

#### Zoom

- 設定 > ビデオ
  - ミーティングに参加する際、ビデオをオフにする
- 設定 > オーディオ
  - ミーティングの参加時にマイクをミュートに設定
- 設定 > 背景とエフェクト
  - ぼかしに設定

## 3. Mac の開発環境構築

### Warp の設定

- テーマの設定
  - https://terminal-themes.com/ より `GruvboxDark` をダウンロードする
  - `mkdir -p $HOME/.warp/themes/` する
  - `mv /Users/snyt45/Downloads/GruvboxDark.yaml $HOME/.warp/themes/` する
- フォントの設定
  - [GitHub > yuru7/HackGen > Release](https://github.com/yuru7/HackGen/releases/latest) より、`HackGen_NF_vx.x.x.zip` をダウンロードの上、展開し `HackGenConsoleNF-Regular.ttf` をインストールする。
  - Settings > Appearance > Text > Terminal font を `HackGen Console NF`にする

### workspace を構築する

https://github.com/snyt45/workspace/tree/main/docker
