---
name: pkm-vault
description: Obsidian vault（pkm-vault）にノートを保存するときの共通ルール。場所・ファイル名・frontmatter・既存ノートの扱いを決める。youtube-reading・web-reading など vault に書くスキルから読み込む。「vault に保存して」「Obsidian にノートを作って」「Inbox に入れて」といった依頼でも使う。
---

# pkm-vault

vault: `/Users/snyt45/Library/Mobile Documents/iCloud~md~obsidian/Documents/pkm-vault`

iCloud で同期している。既存のノートは上書きしない。

## Inbox ノート

後で読む素材は `<vault>/Inbox/<YYYY-MM-DD> <題>.md` に作る。日付は作成日。

- frontmatter: `title`, `source`（URL）, `kind`（article / post / paper / video）, `date`（公開日）, `author`, `tags: [reading/clippings, ...]`, `status: unread`

作ったらパスを1行で返す。
