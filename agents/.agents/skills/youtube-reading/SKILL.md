---
name: youtube-reading
description: YouTube 動画を、見なくても内容が分かる「読書版」の記事に書き直し、Obsidian vault の Inbox にノートとして保存する。youtube.com / youtu.be の URL を渡されたとき、「この動画を読書版にして」「動画を記事にして」「動画の内容をまとめて」「この動画をノートにして」といった依頼で使う。
---

# YouTube 読書版

動画を要約するのではなく、ブログ記事に書き直す。
読者がノートを読むだけで、動画の内容を完全に理解できるようにする。

## 1. 取得する

- メタデータ: `uvx yt-dlp --skip-download --print "%(title)s" --print "%(channel)s" --print "%(upload_date>%Y-%m-%d)s" <URL>`
- 字幕: `uvx --from youtube-transcript-api youtube_transcript_api <動画ID> --languages <言語> --format text`
  - `--list-transcripts` で言語を確認し、動画の原語と手動字幕を優先する。
- 字幕を取得できなければ、推測で書かずに「取得できなかった」と返して終える。

## 2. 書く

- `## 概要`: 動画の核心的な論題と結論を1段落で書く。
- テーマごとの `##` 小節: 動画の内容に沿って詳しく展開する。動画を見返さなくても細部まで分かるようにする（目安1000字以上）。
  - 方法・フレームワーク・プロセスは、ステップや段落に書き直す。
  - 重要な数字・定義・発言は原語のまま残し、括弧内に日本語の注釈を付ける。
- `## Framework & Mindset`: 動画から抽象化できるフレームワークと考え方を、ステップや段落で書く（それぞれ目安1000字以上）。
- `## 自分の仕事への接続`: toypo の開発、AI エージェントの運用、子育てしながらの学習のどれに効くかを書く。

制約:

- 高度に要約しない。
- 新しい事実を足さない。曖昧な発言は原意を保ち、不確かだと明記する。
- 固有名詞は原語のまま残す。訳せるものは括弧内に日本語訳を付ける。
- 長い段落は、論理のまとまりごとに bullet に分ける。
- 字数などの指示そのものを本文に書かない。

## 3. 保存する

`<vault>/Inbox/<YYYY-MM-DD> <題>.md` を作る。既存のノートは上書きしない。

- vault: `/Users/snyt45/Library/Mobile Documents/iCloud~md~obsidian/Documents/pkm-vault`
- frontmatter: `title`, `source`（URL）, `kind: video`, `date`（公開日）, `author`（チャンネル名）, `tags: [reading/clippings, ...]`, `status: unread`

作ったらパスを1行で返す。
