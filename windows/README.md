# windows

Windows ホストの環境構築スクリプト。

## 前提条件

- Windows 11 Home

## 使い方

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
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
.\setup.ps1
```

## Windows 設定, WSL2 の構築

[wiki](https://github.com/snyt45/workspace/wiki)を参照。

## WSL2 の運用手順

### 環境のバックアップ

`script/backup_vm.bat`をダブルクリックする。

### バックアップから VM を複製

`script/add_vm.bat`をダブルクリックする。 プロンプトが起動するので指示に従ってください。

### 不要になった VM 削除

```
wsl --unregister <distro name>
```
