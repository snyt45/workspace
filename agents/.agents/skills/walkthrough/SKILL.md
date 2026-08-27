---
name: walkthrough
description: Neovimのwalkthrough.nvimで辿れるJSON（コード実行パス・バグ経路・diffのステップ列）を生成・検証して保存する汎用フォーマットスキル。応用スキルからの委譲、または明示的な呼び出しで使う。
disable-model-invocation: true
---

# Walkthrough生成

walkthroughは、コード上のポイント列（ステップ）を意図した順序で辿る1つの説明単位。各ステップは `file:line` と、その点が経路上にある理由の解説（note）、必要なら期待される変数状態（values）を持つ。Neovim側がJSONを読み、カーソルジャンプ・行ハイライト・変数値のvirtual text・noteフロートで再生する。

## スキーマ

```json
{
  "description": "何のwalkthroughか（メタデータ。UI非表示）",
  "commit": "40桁のフルSHA（git rev-parse HEAD。--short不可）",
  "steps": [
    {
      "file": "src/api.ts",
      "line": 6,
      "note": "このポイントで何が成り立ち、何が次に起きるか。\\nで複数段落。",
      "thread": [
        { "author": "you", "text": "この分岐いらなくない？" },
        { "author": "pi", "text": "初回アクセス時に必要です。…" }
      ],
      "values": [
        { "name": "id", "value": "\"user:42\"", "line": 5 }
      ]
    }
  ]
}
```

- `commit`: 必須。行番号のstale検出用（コード編集後は再生成する）
- `steps[].file`: リポジトリ相対パス（スラッシュ区切り。`./` や絶対パスは不可）
- `steps[].line`: 1始まり
- `steps[].note` / `steps[].thread`: どちらか一方を使う。`note` は解説1本、`thread` は同じ位置に積み上がる会話（`{author, text}` の時系列フラット配列。ネストなし）。`thread` があるステップでは `note` は表示されない
- `steps[].values`: 任意。実行パス説明では使い、diffレビューでは省略してよい
- `steps[].values[].line`: 必須。その変数が最も意味を持って観測される行（宣言・代入・呼び出し元）

## 執筆ルール

- **1ステップ1論点。** 2つの考えが必要なら分割する。水増しも圧縮もしない
- **noteは「なぜこの点が経路上にあるか」を語る。** 何の不変条件が成り立つか、どの仮定が誤っているか、次に何が起きるか
- **valuesは具体値。** `"user:42"`、`1715000060000` のような実データ。`<某ユーザー>` のようなプレースホルダは検証不能なので使わない
- **競合パスは順序をnoteで明示する。**「ステップ4はステップ5より前に返る」
- **辿る順序は意図で決める。** 実行順・diffの上から順・重要度順など、目的に合った1つの順序で並べる

## 検証（必須）

保存前に必ず実行し、エラー0にする:

```bash
node ~/.agents/skills/walkthrough/scripts/validate.mjs <path/to/walkthrough.json> --check-files
```

`--check-files` はファイル存在と行範囲もチェックする。exit 0=成功 / 1=スキーマ・ファイルエラー / 2=usageエラー。

## 保存と案内

1. 保存先: **対象リポジトリ直下の `.walkthroughs/<slug>.json`**（ディレクトリがなければ作成。git管理不要 — グローバルgitignore済み）。slugは内容を表す短いケバブケース（例: `fix-cache-race.json`）
2. 保存後、ユーザーへ案内して終わり（nvimの起動や操作はしない）:
   > nvimで `,wo` を押すとこのwalkthroughを開けます

nvim側の操作・API・設定は `~/.config/nvim/walkthrough.nvim/README.md` を参照。
