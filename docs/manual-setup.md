# 手動セットアップガイド

このドキュメントは、自動化できない設定項目をまとめたものです。  
`setup.sh`実行後に、このガイドに従って設定を行ってください。

## 📍 システム設定

なし

## 📦 手動インストールが必要なアプリ

### Amphetamine

スリープ防止アプリ（Mac App Store限定）

- **ダウンロード**: Mac App Store で「Amphetamine」を検索してインストール

### Ankerwork

Anker PowerConf C300 Web カメラ用アプリ

- **ダウンロード**: https://us.ankerwork.com/pages/download-software
- **選択**: Mac 版をダウンロード

### CleanShot X

高機能スクリーンショット・画面録画ツール

- **ダウンロード**: https://licenses.cleanshot.com/download/cleanshotx
- **備考**: ライセンスキーが必要

### KensingtonWorks

SlimBlade Pro トラックボール用アプリ

- **ダウンロード**: https://www.kensington.com/ja-jp/p/製品/コントロール/トラックボール/slimblade-proトラックボール3/
- **場所**: ページ下部「マニュアル＆サポート」>「Kensington Konnect Trackballs for Mac 1.0.0」

## ⚙️ アプリケーション設定

### 主要アプリ

#### Google Chrome

- 規定のブラウザに設定
- 各アカウントでサインイン
- 設定 > プライバシーとセキュリティ > 広告プライバシー > 広告のトピック > OFF

#### Google 日本語入力

- **入力ソースの設定**
  - システム環境設定 > キーボード > 入力ソース > 編集
    - 「+」で追加:
      - カタカナ（Google）
      - ひらがな（Google）
      - 全角英数（Google）
      - 半角カナ（Google）
      - 英数（Google）
    - 「-」でデフォルトの日本語入力ソースを削除
- **環境設定**
  - 右上の IME アイコン > 環境設定 > 一般
    - スペースの入力: 半角

#### Karabiner Elements

- アプリを起動して権限を許可

#### Scroll Reverser

- **基本設定**
  - アクセシビリティのアクセスを有効化
  - 「Scroll Reverser を動作させる」にチェック
- **スクロール設定**
  - スクロール方向: 縦方向を逆にする（他はオフ）
  - スクロールデバイス: マウスを逆にする（他はオフ）
- **自動起動**
  - アプリ > ログイン時に開始にチェック

#### SlimBlade Pro（KensingtonWorks）

- **ボタン設定**
  - 左上: バック
  - 右上: フォワード
- **ポインター設定**
  - 加速を有効化
  - デフォルトの速度: +2

### その他のアプリ

#### Alt Tab

- コントロール > ショートカット1
  - 起動ショートカット: `Option + Tab
  - アプリケーションからウィンドウを表示する: 稼働アプリケーション

#### Ankerwork

- 解像度: 720P
- 画角とフレーム: 78°

#### CleanShot X

- 初回設定で macOS のスクリーンショットショートカットを無効化
- Settings > General > Startup: ON

#### Docker Desktop

- 起動後、Settings > General > Start Docker Desktop when you sign in: ON

#### Dropbox

- ファイルの同期方法: ローカル
- PC バックアップ: スキップ

#### Raycast

- ホットキー設定（Cmd+Space など）
- Spotlight のホットキーを無効化

#### Slack

- 各ワークスペースにサインイン

#### Visual Studio Code

1. アカウントマークから「バックアップと設定の同期」を実行
2. 設定同期後、VSCode を再起動

#### Zoom

- ビデオ: ミーティング参加時にビデオをオフ
- オーディオ: ミーティング参加時にマイクをミュート
- 背景とエフェクト: ぼかしに設定

#### 1Password + 1Password CLI

APIキー等のシークレットを1Password経由で管理する。gitリポジトリにシークレットを含めず、Touch IDで認証して取得する仕組み。

1. 1Passwordアプリを開いてアカウントにログイン
2. Settings > Developer > 「Integrate with 1Password CLI」にチェック
3. CLIの動作確認: `op --version`

シークレットの登録:

1. 1Passwordアプリで新しいアイテムを作成（カテゴリ: APIクレデンシャル）
2. アイテム名はスネークケース（例: `anthropic`）
3. 「認証情報」フィールドにAPIキーを保存

シークレット参照URIの確認:

```sh
# アイテム一覧
op item list | grep -i anthropic

# フィールド確認
op item get "anthropic" --format json | jq '.fields[] | {label, type}'

# 値の取得（Touch ID認証が求められる）
op read "op://Development/anthropic/credential"
```

参照URIは `op://Vault名/アイテム名/フィールド名` の形式。URIはシークレットではないのでgitにコミットして問題ない。

.zshrcでは遅延読み込みで設定済み。初回使用時にTouch IDで認証される。

## 🖥️ 開発環境

### Warp

#### AI 設定

- Settings > AI: OFF

#### テーマ設定

```sh
# Catppuccin Mochaテーマをダウンロード（https://github.com/catppuccin/warp）
mkdir -p $HOME/.warp/themes/
curl -sL https://raw.githubusercontent.com/catppuccin/warp/main/themes/catppuccin_mocha.yml -o $HOME/.warp/themes/catppuccin_mocha.yml
```

#### ウィンドウ設定

- Settings > Appearance > Window Opacity: 50
- Settings > Appearance > Window Blur: 20

#### フォント設定

- [HackGen](https://github.com/yuru7/HackGen/releases/latest)から`HackGen_NF_vx.x.x.zip`をダウンロード
- `HackGenConsoleNF-Regular.ttf`をインストール
- Settings > Appearance > Text > Terminal font: `HackGen Console NF`

#### プロンプト設定

- Settings > Appearance > Input > Shell prompt を選択
