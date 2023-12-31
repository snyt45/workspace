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

WSL と cron の設定を反映させるために再起動する。

```
wsl --shutdown

# cronの設定確認: systemdがPID=1で起動していること
ps -ae

# resolv.confの設定が反映されていること
cat /etc/resolv.conf
```

## トラブルシューティング

### クリップボード連携がうまく動かない

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
