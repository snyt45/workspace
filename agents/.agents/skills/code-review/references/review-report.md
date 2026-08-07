# plannotator review への指摘コメント注入

集約した指摘を `plannotator review` の実差分にインラインコメントとして付ける。
API操作は `$plannotator-review` に委譲する。

## 手順

1. 指摘を codeAnnotation に変換する（下記「アノテーションの内容」）。
2. `$plannotator-review` に委譲して起動・注入・回収する。
3. ブラウザセッションのフィードバックが返ったら集約に反映する。

## アノテーションの内容

- アンカー: 指摘の影響が現れる差分内の行（新しい側）に置く。hunk ヘッダー（`@@ -a,b +c,d @@`）から新しい側の行番号を計算する。差分に無い行の指摘は、関係する差分行に置く。
- `text`: 人がレビューするように書く（下記「文体」）。
- `conventionalLabel`: 重大度に応じて `issue` / `suggestion` / `nitpick`。
- `severity`: `error` / `warning` / `info`。
- `suggestedCode` / `originalCode`: コードで直せる指摘には変更前後を入れる。
- `author: "ai-code-review"`。`commitSha` / `commitSubject` は該当行の blame から取る（取れなければ省略可）。

## ラベル

- 致命・高 → `issue`（赤・blocking）
- 中 → `suggestion`（青・提案）
- 低・削除候補・好み → `nitpick`（"nit" 表示・trivial）
- カスタムラベルを使う場合は plannotator 設定で追加してから使う。

## 文体

人がレビューコメントを書くように書く。読み手が「何を・なぜ・どう直すか」を1読で掴める:

- 指摘 → 理由 → 提案の順。2〜4文。
- 丁寧語にしすぎない。命令調・断定調を避け、提案として書く。
- 抽象語を避け、具体の状況・影響を1つ書く。
- 修正をコードで示せる指摘は必ず `suggestedCode` に実コードを入れる。
- 命名・統一・文言の指摘は、具体的な代替案を必ず1つ示す。
- 文ごとに改行する。

## 品質基準

- 軸・重大度は集約時と同じものをそのまま使う。再ランクしない。
- 軽量パスでは注入を省略してよい。
