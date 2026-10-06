---
name: web-reading
description: Web の記事・X（Twitter）のポスト・論文を、読むだけで内容が分かる「読書版」に書き直し、Obsidian vault の Inbox にノートとして保存する。ブログ・note・Zenn・X・arXiv などの URL を渡されたとき、「この記事を読書版にして」「この記事をノートにして」「このポストをまとめて」「この論文を読んでまとめて」といった依頼で使う。YouTube は youtube-reading を使う。
---

# Web 読書版

記事・投稿・論文を読書版のノートにする。書き方は `reading`、保存は `pkm-vault` スキルに従う。

## 取得する

本文は要約させずに、原文のまま取る。

- 記事: `uvx trafilatura -u <URL>` で本文を取る。取れなければ WebFetch で、本文を省略せずに原文のまま出すよう頼む。
- X のポスト: `https://api.fxtwitter.com/<ユーザー>/status/<ID>` を WebFetch で取る。画像があれば、画像内の文字も読む。
- 論文: arXiv は `https://arxiv.org/html/<ID>` か PDF から全文を読む。abstract だけで書かない。

## 保存する

`kind` は article / post / paper。X の `author` はアカウント名も書く。
