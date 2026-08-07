# plannotator review への指摘コメント注入

集約した指摘を、`plannotator review` が表示する実差分（PR diff / ローカル差分）にインラインコメントとして付ける。差分そのものに載るため、コードと指摘の対応が確実。人がレビューしたのと同じ見た目にする（ラベル・文体・提案コード）。

## 手順

1. 対象の差分を `plannotator review` で開く（PR URL を渡すか、`--git` でローカル差分）。
2. セッションのポートを読む: `~/.plannotator/sessions/<pid>.json` の `port`。
3. `GET /api/diff` で rawPatch を取得する。hunk ヘッダー（`@@ -a,b +c,d @@`）から新しい側の行番号を計算し、各指摘の `file:line` を差分内の行へ写像する。
4. 指摘を codeAnnotation に変換する:
   - `filePath` / `lineStart` / `lineEnd`（新しい側の行番号）/ `side: "new"`
   - `text`: 人がレビューするように書く（下記「文体」）
   - `conventionalLabel`: 重大度に応じて `issue` / `suggestion` / `nitpick`（下記「ラベル」）
   - `severity`: `error` / `warning` / `info`
   - `suggestedCode` / `originalCode`: コードで直せる指摘には変更前後を入れる
   - `author: "ai-code-review"`。`commitSha` / `commitSubject` は該当行の blame から取る（取れなければ省略可）
5. `POST /api/draft` に draft JSON を送る（`codeAnnotations` / `descriptionAnnotations` / `commentAnnotations` / `viewedFiles` / `draftGeneration` / `ts`）。既存のドラフトがあれば先に `DELETE /api/draft` で消す。
6. `GET /api/draft` で注入件数と位置を確認する。
7. ブラウザのタブをリロードしてもらう（UI はロード時に一度だけ取得する。ポーリングしない）。
8. ブラウザセッションのフィードバックが返ったら、ユーザー自身の注釈も含めて集約に反映する。

## ラベル（conventionalLabel）

plannotator のラベルバッジ。重大度との対応:

- 致命・高 → `issue`（赤・blocking）
- 中 → `suggestion`（青・提案）
- 低・削除候補・好み → `nitpick`（"nit" 表示・trivial）

`imo` 等のカスタムラベルを使う場合は plannotator の設定（Conventional Comments のラベル編集）で追加してから使う。

## 文体

人がレビューコメントを書くように書く。読み手（実装者）が「何を・なぜ・どう直すか」を1読で掴める:

- 指摘 → 理由 → 提案の順。2〜4文。
- 丁寧語にしすぎない（「〜です」「〜したいです」）。命令調・断定調を避け、提案として書く。
- 抽象語を避け、具体の状況・影響を1つ書く（「こういう入力で、こう壊れる」）。
- 修正をコードで示せる指摘は必ず `suggestedCode`（+`originalCode`）に実コードを入れる。文言だけの「直し方: …」にしない。
- 命名・統一・文言の指摘は、具体的な代替案（リネーム例・変更後の文言など）を必ず1つ示す。
- 文ごとに改行する（$essence 原則8）。

## 品質基準

- アンカーは指摘の影響が現れる差分内の行（新しい側）に置く。差分に無い行の指摘（既存コード・テスト欠落など）は、関係する差分の行に置く。
- 軸・重大度は集約時と同じものをそのまま使う。再ランクしない。
- 既存のユーザー注釈を上書きしない。POST 前に `GET /api/draft` で確認する。
- 注入した draft は差分のハッシュに紐づく。同じ差分を再レビューすると残っていることがあるので、不要なら `DELETE /api/draft` で消す。
