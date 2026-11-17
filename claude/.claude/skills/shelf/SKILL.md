---
name: shelf
description: HTML・PDF を Shelf（Cloudflare R2 ＋ Worker のスマホで読む置き場、https://shelf.snyt45.workers.dev）に上げ、ID と開く URL を返す。同じファイルを上げ直すと同じカードが上書きされる。作った HTML のレポートや PDF をスマホで読みたいとき、「shelfにあげて」「Shelf に上げて」「スマホで読めるようにして」「shelf-put」といった依頼で使う。
---

# shelf

仕事は1つ: 渡された HTML か PDF を Shelf に上げ、ID と URL を返す。

Shelf にあるのは2種類だけ。クリップ（clipping-digest が作る要約のページ）と、ページ（それ以外の単発の HTML・PDF）。下のタブは 未読・クリップ・ページ。

## 上げ方

```
~/work/shelf/bin/shelf-put [--as <ID>] [--desc <説明>] <ファイル> [タイトル]
~/work/shelf/bin/shelf-put --id <ファイル>      上げずに ID だけ出す
~/work/shelf/bin/shelf-rm <ID かファイル>...     Shelf から消す（目録と R2 のファイル。元のファイルは残る）
```

- Cowork のシェルでは `~/work/shelf/bin` の代わりに `$HOME/mnt/shelf/bin`。ログインできないので `$HOME/mnt/shelf/.env`（R2 と D1 の権限のトークン）が要る
- HTML の `<meta>` で渡せるもの: `description`（一覧に出す1〜2行）、`shelf-tab`（`クリップ` ならクリップ。無ければページ）、`shelf-source`（出どころ。サイト名など）、`shelf-minutes`（読む時間。省くと開いたままの文字数から出す）、`shelf-ask`（「聞く」で Claude のチャットに入る最初の文）
- タイトルを省くと、HTML は `<title>`、PDF はファイル名になる
- ID は「ルート（上にたどって最初に `.git` か `.obsidian` がある所）のフォルダ名/そこからの相対パス」から作る。どの PC から上げても、同じファイルは同じ ID になり上書きされる
- 名前や場所を変えたファイルで既存のカードを置き換えるときは `--as <ID>`
- 上げたら、ID と `https://shelf.snyt45.workers.dev/v/<ID>` を返す

## ルール

- 上げるのは HTML と PDF だけ。ほかの形式は HTML か PDF にしてから上げるか、聞く
- HTML は1ファイルで完結させる。相対パスの CSS・画像・JS は読み込めない（外部 CDN は可）
- 容量の確認（バケット合計 5GB）で止まったら、`SHELF_ALLOW_EMPTY=1` で通さずに止めて報告する
- 認証は `~/work/shelf/.env`（`CLOUDFLARE_API_TOKEN` と `CLOUDFLARE_ACCOUNT_ID`）。無ければ Mac の `wrangler login` を使う。トークンの中身は表示しない
- 消すのは、頼まれたときだけ行う
