# windows

Windows ホストの環境構築スクリプト。

## WSL2 の運用手順

### 環境のバックアップ

`script/backup_vm.bat`をダブルクリックする。

### バックアップから VM を複製

`script/add_vm.bat`をダブルクリックする。 プロンプトが起動するので指示に従ってください。

### 不要になった VM 削除

```
wsl --unregister <distro name>
```
