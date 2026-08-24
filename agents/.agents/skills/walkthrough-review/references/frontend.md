# フロントエンド (TypeScript / React) の基準

toypo-app / toypo4store-web / toypo-lma-builder の過去レビュー指示から抽出。

- **view はバカ** — view は加工済みデータを表示するだけ。ロジック・分岐・整形は view hook へ。
- **神hook / 神コンポーネント禁止** — reload も create も update も1つの hook でやらない。hook のための単一責任 hook があってよい。
- **依存の向き** — 親が自身の持たない値を子に渡していたら設計ミス。context で import して values に流し込めるものを view から流し込まない。
- **命名** — 実態と一致。`pool !== null` より `isOpen`。UI 文言はエンドユーザーに通じる語彙か。
- **型は手書きせず導出** — `as` より元の型から `Pick`。`keyof typeof` を再定義するより元の箇所で export して import。
- **マジックストリング排除** — エンドポイントパス等はファイル内定数に。共通化されていないか先に探す。
- **既存の流儀** — 定数は strings.ts の流儀に合わせる。styled より css。リポジトリの最新の書き方を確認してから書く。UI は既存画面に揃える。
- **セキュリティは allowlist 型** — 許可タグを列挙して外は escape。ただし脅威モデルは現実的に（事業者しか触らない入力への過剰防御は不要）。
- **リリース順序の安全性** — API より先にフロントがリリースされても壊れないかを確認する。
- **予測可能性** — 計算は純粋に保ち、副作用（fetch・store更新）は1箇所にまとめる。状態は invalid を型で排除できる形（discriminated union 等）で持つ。
- **テスト** — test-quality-check エージェント定義に従う（ブラックボックスE2E優先）。
