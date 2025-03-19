# windows 用の構築手順

## 前提条件

- Windows 11 Home
- Ubuntu 24.04 on WSL2

## 1. リストア手順

### リセット手順

1. 設定（`Win + I`） > システム > 回復 > この PC をリセット
2. すべて削除する
3. ローカル再インストール
4. 次へ
5. リセット

### リセット後

- Windows11 でオフライン環境でセットアップする
  - 参考：https://tanweb.net/2023/01/21/51703/
- 設定（`Win + I`） > `Windows Update`で更新があれば更新を行う。

## 2. Windows の環境構築

### Windows 用のセットアップスクリプトを実行する

Windows ホスト用のセットアップを行うため、Git をインストールする。

```
winget install Git.Git
git config --global user.name "yuta.sano"
git config --global user.email "snyt45@gmail.com"
```

Windows ホスト用のセットアップを行うため、リポジトリをクローンする。

```
git clone https://github.com/snyt45/workspace.git $HOME/.dotfiles
```

Windows ホスト用の設定とツール郡のインストールを行う。

```
cd $HOME/.dotfiles/windows
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
.\setup.ps1
```

### 手動インストール

#### Ankerwork

Anker の WEB カメラ「Anker PowerConf C300」のアプリ。

Windows を選択してダウンロードする。

https://us.ankerwork.com/pages/download-software

#### Google 日本語入力

winget 経由だとデフォルト設定ができない

https://www.google.co.jp/ime/

#### KensingtonWorks

SlimBlade Pro トラックボールのアプリ。

ページ下部の「マニュアル＆サポート」の「Kensington Konnect Trackballs for Windows 1.0.0」からダウンロードする。

https://www.kensington.com/ja-jp/p/%E8%A3%BD%E5%93%81/%E3%82%B3%E3%83%B3%E3%83%88%E3%83%AD%E3%83%BC%E3%83%AB/%E3%83%88%E3%83%A9%E3%83%83%E3%82%AF%E3%83%9C%E3%83%BC%E3%83%AB/slimblade-pro%E3%83%88%E3%83%A9%E3%83%83%E3%82%AF%E3%83%9C%E3%83%BC%E3%83%AB3/

#### Tana

公式ホームページから直接ダウンロードする。

https://tana.inc/

#### CubePDF（任意）

PDF にパスワードをかける際に必要。

```
$ winget install CubeSoft.CubePDF
```

#### LibreOffice（任意）

エクセルを使うときに必要。

```
$ winget install TheDocumentFoundation.LibreOffice
```

#### Metaquest Remote Desktop（任意）

メタクエスト 3 と Windows でリモートデスクトップ機能を使う場合には PC にもアプリのインストールが必要。

参考 URL：https://note.com/sigmode21/n/na4018cb9c262

ダウンロードリンク：https://apps.microsoft.com/detail/9pcnzpd0zw44?hl=ja-jp&gl=JP&ocid=pdpshare

#### XPPen Deco mini7（任意）

ペンタブを使うときに必要なアプリ。

https://www.xp-pen.jp/download-530.html

### ソフトウェアの設定

#### 壁紙

- 設定（`Win + I`）を開く > 個人用設定 > テーマ > ダークテーマ

#### Ankerwork

- 解像度を「720P」、画角とフレームを「78°」にする

#### Dropbox

- ファイルの同期方法を選択する > ファイルを`ローカル`に設定する
- PC をバックアップしないで続ける

#### Google Chrome

- 規定のアプリに設定
- 各アカウントでサインイン
- 設定 > プライバシーとセキュリティ > 広告プライバシー > 広告のトピック > OFF

#### Google 日本語入力

- 右下の IME アイコンを右クリック > プロパティ > 一般
  - スペースの入力
    - 半角

#### PowerToys

- FancyZones
  - 各ディスプレイごとに`Win + Shift + @`で設定

#### Slack

- 各アカウントでサインイン

#### shareX

- ホットキーの設定
  - 領域をキャプチャ：Shift + F1
  - 独自領域の動画キャプチャを開始/停止：Shift + F2
  - 独自領域の動画キャプチャ(GIF)を開始/停止：Shift + F3
- キャプチャ後のタスク
  - 以下にチェックを入れる
    - 画像エディタで開く
    - 画像をクリップボードにコピー
    - 画像をファイルに保存
- アプリの設定 > 高度な設定 > Upload > DisableUpload を True にする

#### SlimBlade Pro

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

## 3. WSL2 の環境構築

### WSL を最新にアップデートして、Ubuntu をインストールする

WSL を更新する。

```
wsl --update
```

Ubuntu をインストールする。

```
wsl --install -d Ubuntu-24.04
```

### WSL2 構築前に行う設定

#### Docker Desktop

- 設定 > Resources > WSL INTEGRATION > Ubuntu をオン > Apply & Restart
- WSL で`docker -v`が使えることを確認

#### フォントのインストール

[GitHub > yuru7/HackGen > Release](https://github.com/yuru7/HackGen/releases/latest) より、`HackGen_NF_vx.x.x.zip` をダウンロードの上、展開し `HackGenConsoleNF-Regular.ttf` をインストールする。

#### Windows Terminal

- Windows Terminal の設定を行う。
  - 設定 > 操作(カーソル)
    - 「選択範囲をクリップボードに自動でコピーする」を ON にする
  - 設定 > 操作(キーボード)
    - 貼り付けの`Ctrl + V`を削除する ※Vim のキーバインドと被るため
  - プロファイル：規定値
    - 外観
      - テキスト
        - フォントフェイス
          - HackGen Console NF
        - フォントサイズ
          - 11
  - プロファイル： Ubuntu-24.04
    - 全般
      - 名前
        - 「snyt45」に設定
      - 開始ディレクトリ
        - `\\wsl.localhost\Ubuntu-24.04\home\snyt45`に設定
        - 設定が上手くいかない場合は、[こちら](https://creepfablic.site/2022/06/28/wsl2-default-login-user-change/)をもとにデフォルトユーザーを設定する
      - タブタイトル名
        - 「snyt45」に設定
      - 外観
        - カーソルの形を「バー」に設定
    - 詳細設定
      - ベル通知スタイル
        - 音によるチャイム オフ
      - タイトルの変更を表示しない オン
        - タブタイトルを反映させるための設定
  - スタートアップ
    - 既定のプロファイル
      - Windows PowerShell から 「snyt45」にする
  - カラーテーマ設定
    - gruvbox
      - https://windowsterminalthemes.dev/?theme=Gruvbox%20Dark
    - 手順
      1. Gruvbox Dark を選択して「Get theme」してコピー
      2. Windows Terminal > 設定 > JSON ファイルを開く > shemes に追加する
      - ![](https://firebasestorage.googleapis.com/v0/b/firescript-577a2.appspot.com/o/imgs%2Fapp%2Fyuta_sano%2FSjYZvSjZLB.png?alt=media&token=107c48b8-f3e6-402c-9281-869a81882e6d)
      3. プロファイル > 規定値 > 外観 > 配色を「Gruvbox Dark」に変更する

### WSL2 のセットアップ

```
git clone https://github.com/snyt45/workspace.git ~/.dotfiles
cd ~/.dotfiles/wsl2
bash setup.sh
```

GitHub の SSH key の設定を行う。

```
# `~/.ssh`にSSH keyをコピー
# 適切なパーミッションに設定
chmod 600 <SSH key>

# 接続確認
ssh -T git@<user name>
```

WSL と cron の設定を反映させるために再起動する。

```
wsl --shutdown

# cronの設定確認: systemdがPID=1で起動していること
ps -ae

# resolv.confの設定が反映されていること
cat /etc/resolv.conf
```

### workspace を構築する

https://github.com/snyt45/workspace/tree/main/docker

## トラブルシューティング

### WSL2 の調子が悪いときにインストールしなおす

- `wsl --unregister Ubuntu-24.04`
- Windows Terminal のプロファイルから該当のプロファイルを削除する
- `wsl --install -d Ubuntu-24.04`
  - 該当のプロファイルが出てこない場合
    - 設定 > 該当のプロファイル > ドロップダウンからプロファイルを非表示にする を OFF にする
- 「WSL2 構築前に行う設定」の手順を実施する

### WSL2 で apt-get update するときに一時接続エラーになる

- /etc/wsl.conf の [network] の設定を削除 -> wsl --shutdown

### winget を実行するとエラーが出る

https://teratail.com/questions/bnuj82z2oh7cso

- `Win + I` > システム > システムの詳細設定 > 詳細設定 > 環境変数 > Path の編集 > `%LOCALAPPDATA%\Microsoft\WindowsApps`を追加

### WSL 上で`code .`コマンドが存在しない

再インストールし直す

- `winget uninstall Microsoft.VisualStudioCode`
- `winget install Microsoft.VisualStudioCode`

### WSL2 とのクリップボード連携がうまく動かない

```
# cronの起動確認
service cron status

# cronを再起動
sudo service cron restart

# ログ確認
cat /var/log/cron.log

# clip.shに実行権限が付与されているか確認
ls -al ~/.dotfiles/wsl2/script
chmod +x ~/.dotfiles/wsl2/script/clip.sh

# reboot
wsl --shutdown
```
