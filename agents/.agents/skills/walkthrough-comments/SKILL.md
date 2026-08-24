---
name: walkthrough-comments
description: nvimのpi-nvim-commentから提出されたレビューコメント一覧に回答し、回答をwalkthroughとして出力する。コメント提出後に「walkthroughで回答して」「コメントへの返答を辿れるようにして」と言われたとき、またはコメント提出プロンプトにwalkthrough出力の指定があるときに使う。
---

# Walkthrough Comments

pi-nvim-comment が提出したコメント一覧（`## Comment N` + File/Lines/Review comment/Source excerpt 形式）への回答を、コメント位置を辿るwalkthroughにする。

## 手順

### 1. コメントに回答する

提出プロンプトの指示に従い、各コメントを独立に処理する（質問には回答、変更依頼は実装、曖昧なら確認事項として書く）。**現在のファイルを必ず読み直してから**回答・変更する（Source excerpt は未保存・古い可能性がある）。

### 2. ステップを設計する

- 1コメント = 1ステップ。`file:line` はコメントの開始行（変更を実装した場合は変更後の行番号に合わせる）
- 並び順は提出プロンプトのコメント順
- note の書式:

  ```
  > コメント本文（引用）

  回答または実施した変更の説明。
  変更した場合は before/after の要点。
  ```

### 3. 生成・検証・保存

JSONの生成・検証・保存の規約は `~/.agents/skills/walkthrough/SKILL.md` を読んで従う。

- slug: `comments-<日付やトピック>`
- 保存後、チャットには「変更N件・回答N件・要確認N件」の1行と「nvimで `,wo` から辿れます」だけ報告する（詳細はwalkthrough側に書く）
