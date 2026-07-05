---
name: explain-diff-notion
description: コードの変更・diff・branch・PRを、背景・直感・コード解説・クイズ付きのNotionページとして説明する。
---

# Explain Diff (Notion)

指定されたコード変更について、リッチな解説をNotionページとして作成してください。

以下のセクションで構成すること:

- **Background（背景）**: この変更に関連する既存システムを説明する。周辺コードを幅広く探索すること。読者が事前知識をどれくらい持っているかわからないため、初心者向けの深い背景（すでに知っている読者はスキップ可）と、変更に直接関連する絞り込んだ背景の両方を含める。
- **Intuition（直感）**: コード変更の核心となる直感を説明する。全詳細ではなく本質の伝達に集中する。具体例・おもちゃデータを使い、図やダイアグラムを積極的に使う。
- **Code（コード解説）**: 変更のハイレベルなウォークスルーを行う。理解しやすい順序・グループでまとめる。
- **Quiz（クイズ）**: PRの内容を理解できているか確認する5問のクイズを作る。適度な難易度（本質を理解しないと答えられないが、引っかけにしない）。各問題に選択肢と、正誤それぞれの説明を付ける。トグルブロックで表現する。例:
  ```
  1. Question
     ▶ Option 1
      ❌ Explanation for why it was incorrect
     ▶ Option 2
      ❌ Explanation for why it was incorrect
     ▶ Option 3
      ✅ Explanation for why it was correct
     ▶ Option 4
       ❌ Explanation for why it was incorrect
  2. Question
     ...
  ```

フォーマット:

- Notion MCP ツールを使って新しいページを作成し、そのURLを返す。
- Martin Kleppmann のような明快さとフローで書き、読んでいて楽しい文章にする。セクション間の遷移はスムーズに。
- ダイアグラムのヒント: 説明全体で再利用できる少数の「ダイアグラムファミリー」を選ぶと良い。サンプルデータを必ず含める。
- 重要概念・定義・エッジケースにはコールアウトを使う。
