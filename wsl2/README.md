# wsl2

Windows11 の WSL2 ホスト の環境構築スクリプト。

## 前提条件

- Windows 11 Home
- Ubuntu 22.04 on WSL2

## 使い方

WSL2 のセットアップを行う。

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
