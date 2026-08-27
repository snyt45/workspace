---
name: walkthrough-comments
description: nvimのpi-nvim-commentから提出されたレビューコメント一覧に回答し、回答をwalkthroughとして出力する。コメント提出後に「walkthroughで回答して」「コメントへの返答を辿れるようにして」と言われたとき、またはコメント提出プロンプトにwalkthrough出力の指定があるときに使う。
---

# Walkthrough Comments

pi-nvim-comment が提出したコメント一覧（`## Comment N` + File/Lines/Review comment/Source excerpt 形式）への回答を、コメント位置を辿るwalkthroughにする。

## 手順

### 1. コメントに回答する

提出プロンプトの指示に従い、各コメントを独立に処理する（質問には回答、変更依頼は実装、曖昧なら確認事項として書く）。**現在のファイルを必ず読み直してから**回答・変更する（Source excerpt は未保存・古い可能性がある）。

### 2. ステップを設計する（thread形式）

- 1コメント = 1ステップ = 1スレッド。`file:line` はコメントの開始行（変更を実装した場合は変更後の行番号に合わせる）
- 並び順は提出プロンプトのコメント順
- `note` は使わず `thread` で書く。コメントが `author: "you"`、回答が `author: "pi"`:

  ```json
  { "file": "src/api.ts", "line": 42, "thread": [
    { "author": "you", "text": "コメント本文そのまま" },
    { "author": "pi", "text": "回答または実施した変更の説明。変更した場合は before/after の要点。" }
  ] }
  ```

### 3. 返信コメントは元のJSONに追記する

コメントに `Reply to walkthrough thread: <json path> (step N)` が付いている場合は**新規JSONを作らない**:

1. 参照されたJSONを読む
2. `steps[N-1]`（stepは1始まり）の `thread` 末尾に `{ "author": "you", "text": 返信本文 }` と `{ "author": "pi", "text": 回答 }` を追記する
3. コードを変更した場合は該当ステップの `line` を変更後に合わせ、`commit` を `git rev-parse HEAD` で更新する
4. 検証して**同じファイルに上書き保存**する（nvim側は `,wR` で再読み込みする）

返信と新規コメントが混在する提出では、返信は追記・新規は新しいJSONに分ける。

### 4. 生成・検証・保存

JSONの生成・検証・保存の規約は `~/.agents/skills/walkthrough/SKILL.md` を読んで従う。

- slug: `comments-<日付やトピック>`
- 保存後、チャットには「変更N件・回答N件・要確認N件」の1行と「nvimで `,wo` から辿れます」（追記の場合は「`,wR` で再読み込みできます」）だけ報告する（詳細はwalkthrough側に書く）
