---
name: annotate
description: コードを読む・レビューする前に、引っかかりやすい構文へ警告レベル付きの注釈を付けた自己完結HTMLを生成する。AIが書いたコードや不慣れな言語（shell, Ruby/Rails, Go, Terraform, JS/TS等なんでも）を読むとき、「この構文何？」「実際どんな値が返る？」を後から聞かなくても読めるようにする。「注釈を付けて」「annotateして」「この構文を解説して」などの依頼で使う。
---

# Annotate

対象コードに警告レベル付きの注釈を付けた自己完結HTMLを生成する。全行解説ではなく、必要なところだけ書く。言語は問わない。
読者は経験のあるエンジニア。「この構文は何で実際どんな値が入るのか」を先回りして潰す。

## 手順

1. **対象を読む** — 実データを特定する（`guides/content.md`）
2. **生成する** — `template.html` の `__SRC__` / `__META__` を置換し、`~/annotations/YYYY-MM-DD-<slug>.html` に書き出す（形式: `guides/format.md`）
3. **検証する** — `python3 <dir>/check.py <出力html> <対象ファイル...>`
4. **開く** — `plannotator-annotate` スキルに委譲（フィードバックが返ったら修正して再度開く）

## ファイル

- `template.html` — レンダリング（ファイルツリー・カード・trace・シンタックスハイライト）。置換だけで動く
- `check.py` — マーカーと meta・原文の機械検証
- `guides/format.md` — 生成物の形式（マーカー・JSON・複数ファイル/PR 対応）
- `guides/content.md` — 注釈の中身の書き方（実データ・カード・警告レベル・essence）
- `guides/meta.md` — summary・呼び出し経路・処理の流れの書き方
