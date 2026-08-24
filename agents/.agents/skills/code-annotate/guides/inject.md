# 注入モード（plannotator への注釈）

「注釈として注入して」等、`plannotator review` の実差分にインラインコメントとして注釈を付ける**明示依頼**の場合。解説モード（SKILL.md 本文）ではなく、ここに従う。注釈の中身の書き方（実データ・警告レベル・カード・essence）は `guides/content.md` を参照。

## 手順

1. **対象を読む** — 差分と実データを特定する（`guides/content.md`）。PR なら `plannotator review <PR_URL>` の diff（`GET /api/diff`）が対象になる。コミット済みの差分をレビューする場合は `POST /api/diff/switch` に `{"diffType":"commit:<sha>"}` を送って開く（起動時は未コミット変更が対象）。注釈は差分内の行にのみ置ける。差分に無い構文は、それが使われている差分行に置く
2. **注釈を組み立てる** — 概要・呼び出し経路・処理の流れ・構文注釈（L1/L2）を決める（`guides/content.md`「注釈の中身」）。同じ構文が複数ファイルにある場合は初出に完全版、他は2〜3文に畳む
3. **注入する** — `$plannotator-review` に委譲して起動・注入・回収する。draft は `DELETE /api/draft` → `POST /api/draft`（`draftGeneration` は現在値より大きい値）
4. **反映する** — フィードバックが返ったら注釈を直して再度注入する

## 出力形式（要約)

- 1注釈 = 1コメント。アンカーは差分内の該当行（新しい側）。ファイル全体は `scope:"file"`
- `conventionalLabel` / `severity` のマッピング: 概要・経路・流れ → `note` / 構文注釈 L2 → `issue` + `important` / L1 → `note` + `nit`。`severity` の UI 表示は important / nit / pre_existing の3値のみ
- `text` は Markdown（1行目 `**…**` 太字タイトル、例は `> ` 引用、ref はリンク）。絵文字なし。`author: "ai-code-annotate"`
- カードの what / ex / ref の書き方は `guides/content.md`