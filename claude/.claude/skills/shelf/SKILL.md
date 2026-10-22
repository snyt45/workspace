---
name: shelf
description: HTML・PDF を Shelf（Cloudflare R2 ＋ Worker のスマホで読む置き場、https://shelf.snyt45.workers.dev）に上げ、ID と開く URL を返す。同じファイルを上げ直すと同じカードが上書きされる。ページをフォルダに入れる・移す・フォルダの名前を変えるのもこれで行う。作った HTML のレポートや PDF をスマホで読みたいとき、「shelfにあげて」「Shelf に上げて」「スマホで読めるようにして」「shelf-put」「Shelf のフォルダに入れて」「フォルダを移して」といった依頼で使う。
---

# shelf

仕事は1つ: 渡された HTML か PDF を Shelf に上げ、ID と URL を返す（入れるフォルダの指定と変更を含む）。

## 上げ方

```
~/work/shelf/bin/shelf-put [--as <ID>] [--series <名前> | --folder <名前>] <ファイル> [タイトル]
~/work/shelf/bin/shelf-put --id <ファイル>      上げずに ID だけ出す
~/work/shelf/bin/shelf-move <ID かファイル> <フォルダ | ->            上げ直さずにページをフォルダへ移す（- で外す）
~/work/shelf/bin/shelf-move --folder <フォルダ名> <親フォルダ | ->   フォルダごと別のフォルダの下へ（- でいちばん上へ）
~/work/shelf/bin/shelf-rename <今の名前> <新しい名前>                 フォルダの名前を変える
```

- まとまりは2種類。シリーズは地続きのもの（前へ・次へ、進み具合）、フォルダは単発のページを束ねるだけのもの。1ページが入るのは1つまで
- まとまりを省くと、HTML の `<meta name="shelf-series">` か `<meta name="shelf-folder">` から取り、それも無ければ今のまとまりのまま変えない。外すときは `-`
- フォルダは `Work/ワイズテーブル` のようにパスで入れ子にでき、ページはいちばん下のフォルダに入る。無いフォルダは指定したときに作られる
- 名前はシリーズ・フォルダ全体で1つ。別の親の下にある同じ名前のフォルダは指定できない（移すなら `shelf-move --folder`）

- タイトルを省くと、HTML は `<title>`、PDF はファイル名になる
- ID は「ルート（上にたどって最初に `.git` か `.obsidian` がある所）のフォルダ名/そこからの相対パス」から作る。どの PC から上げても、同じファイルは同じ ID になり上書きされる
- 名前や場所を変えたファイルで既存のカードを置き換えるときは `--as <ID>`
- 上げたら、ID と `https://shelf.snyt45.workers.dev/v/<ID>` を返す

## ルール

- 上げるのは HTML と PDF だけ。ほかの形式は HTML か PDF にしてから上げるか、聞く
- HTML は1ファイルで完結させる。相対パスの CSS・画像・JS は読み込めない（外部 CDN は可）
- 容量の確認（バケット合計 5GB）で止まったら、`SHELF_ALLOW_EMPTY=1` で通さずに止めて報告する
- 認証は `~/work/shelf/.env`（`CLOUDFLARE_API_TOKEN` と `CLOUDFLARE_ACCOUNT_ID`）。無ければ Mac の `wrangler login` を使う。トークンの中身は表示しない
- 消す操作はしない。フォルダの入れ替えと名前の変更は、頼まれたときだけ行う
