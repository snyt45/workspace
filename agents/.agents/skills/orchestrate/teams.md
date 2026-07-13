# チーム定義

orchestrateスキルが使ってよい編成はこのファイルに定義されたチームだけ。**編成・台数・モデル・レイアウトを変えたいときは、このファイルを編集する**（実体: dotfiles `agents/.agents/skills/orchestrate/teams.md`）。

## 共通設定

- ワーカー名は `worker-<タスク略称>-<役割>` 形式（例: `worker-auth-impl`）。
- **opencode / pi はサブスク（opencode Goプラン）のモデルのみ使う。** API課金になるプロバイダを指定しない。
  - pi: 設定デフォルト（`~/.pi/agent/settings.json` = `opencode-go/kimi-k2.7-code`）をそのまま使う。フラグ指定は不要。
  - opencode: 必ず `--model opencode-go/kimi-k2.7-code` を明示する（未指定だと別プロバイダに落ちうる）。
  - claude: サブスク内。モデル指定なし（セッションデフォルト）。
- 作業場所は常に新規workspace。既存workspaceに相乗りしない。
- **worktreeはユーザーが明示的に指示した場合のみ。** 同一リポジトリでの並走が必要になったら、直列化するかworktreeを使うかをユーザーに確認する。

## team: impl-review（デフォルト）

- 用途: 機能実装・バグ修正
- レイアウト: 1つの新規workspaceに左右2ペイン

| 役割 | 名前 | 起動コマンド | 配置 |
|---|---|---|---|
| implement | `worker-<t>-impl` | `pi` | 左（最初に起動） |
| review | `worker-<t>-review` | `opencode --model opencode-go/kimi-k2.7-code` | 右（`--split right`） |

- フロー: implに実装させ、`HERDR-DONE: <impl>` を確認したらreviewに対象diffのレビューを指示する。reviewの完了契約はverdict付きにする:
  - `HERDR-DONE: worker-<t>-review | PASS — <要約>`
  - `HERDR-DONE: worker-<t>-review | FAIL — <どの基準> : <期待 vs 実際>`

  FAILならその内容（コマンド・期待・実際）をそのままimplに差し戻す（往復は1回まで。それ以上はユーザーに相談）。reviewはコードを直接修正しない。

## team: solo

- 用途: 小さな独立タスク1件（レビュー不要と判断できる規模）
- レイアウト: 新規workspaceに1ペイン

| 役割 | 名前 | 起動コマンド | 配置 |
|---|---|---|---|
| implement | `worker-<t>-impl` | `pi` | 単独 |

## team: research-duo

- 用途: 技術調査・コードベース調査を2視点で並列
- レイアウト: 1つの新規workspaceに左右2ペイン

| 役割 | 名前 | 起動コマンド | 配置 |
|---|---|---|---|
| research | `worker-<t>-research-a` | `opencode --model opencode-go/kimi-k2.7-code` | 左 |
| research | `worker-<t>-research-b` | `opencode --model opencode-go/kimi-k2.7-code` | 右（`--split right`） |

- TASKで視点を分ける（例: aは実装コード側、bはテスト・ドキュメント側から調べる）。両方の報告をオーケストレーターが突き合わせて要約する。

## 同時稼働の上限

チームをまたいだ合計で同時4ワーカーまで。超える分はキューにして、完了したワーカーの枠で順次投入する。
