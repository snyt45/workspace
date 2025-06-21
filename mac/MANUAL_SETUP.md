# 手動セットアップガイド

このドキュメントは、自動化できない設定項目をまとめたものです。  
`setup.sh`実行後に、このガイドに従って設定を行ってください。

## 📍 システム設定

### キーボードショートカット

- システム環境設定 > キーボード > キーボードショートカット > Mission Control
  - **Mission Control**: F3
  - **アプリケーションウィンドウ**: F4

## 📦 手動インストールが必要なアプリ

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

## 🖥️ 開発環境

### Warp

#### テーマ設定

```sh
# GruvboxDarkテーマをダウンロード（https://terminal-themes.com/）
mkdir -p $HOME/.warp/themes/
mv ~/Downloads/GruvboxDark.yaml $HOME/.warp/themes/
```

#### フォント設定

- [HackGen](https://github.com/yuru7/HackGen/releases/latest)から`HackGen_NF_vx.x.x.zip`をダウンロード
- `HackGenConsoleNF-Regular.ttf`をインストール
- Settings > Appearance > Text > Terminal font: `HackGen Console NF`

#### プロンプト設定

- Settings > Appearance > Prompt > Shell prompt を選択
