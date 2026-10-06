---
name: youtube-reading
description: YouTube 動画を、見なくても内容が分かる「読書版」の記事に書き直し、Obsidian vault の Inbox にノートとして保存する。youtube.com / youtu.be の URL を渡されたとき、「この動画を読書版にして」「動画を記事にして」「動画の内容をまとめて」「この動画をノートにして」といった依頼で使う。
---

# YouTube 読書版

YouTube 動画を読書版のノートにする。書き方は `reading`、保存は `pkm-vault` スキルに従う。

## 取得する

- メタデータ: `uvx yt-dlp --skip-download --print "%(title)s" --print "%(channel)s" --print "%(upload_date>%Y-%m-%d)s" <URL>`
- 字幕: `uvx --from youtube-transcript-api youtube_transcript_api <動画ID> --languages <言語> --format text`
  - `--list-transcripts` で言語を確認し、動画の原語と手動字幕を優先する。

## 保存する

`kind: video`。`author` はチャンネル名。
