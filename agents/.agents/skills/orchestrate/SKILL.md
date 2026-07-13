---
name: orchestrate
description: herdr上のマルチエージェントオーケストレーション。単一のオーケストレーターペインからworkspace/worktreeごとにワーカーエージェント(claude/opencode/pi)を起動し、タスクを割り振り、進捗を監視し、エージェント間で報告をやり取りして結果を回収する。「並列で作業させて」「ワーカーに任せて」「オーケストレーションして」といった依頼で使う。HERDR_ENV=1のとき専用。
---

# orchestrate — herdrマルチエージェントオーケストレーション

## 前提チェック

- `HERDR_ENV` が `1` でなければ「herdr外なので実行できない」と伝えて中止する。
- 自分のペインIDは `$HERDR_PANE_ID`、ワークスペースは `$HERDR_WORKSPACE_ID`。

## 0. 自分に名前をつける

ワーカーからの報告の宛先になるため、最初に必ず自分を `orchestrator` と命名する。

```bash
herdr agent rename "$HERDR_PANE_ID" orchestrator
```

既に別ペインが `orchestrator` を名乗っている場合（`herdr agent list` で確認）は `orchestrator-2` 等にずらし、ワーカーへの指示でもその名前を使う。

## 1. タスク分解と作業場所の用意

ユーザーの依頼をワーカー単位のタスクに分解する。タスクごとに独立した作業場所を作る:

- **別リポジトリ・別ディレクトリのタスク** → ワークスペースを作る:

  ```bash
  herdr workspace create --cwd /path/to/repo --label "task-a" --no-focus
  ```

- **同一リポジトリ内の並列タスク**（ファイル競合の恐れあり）→ git worktreeで隔離する:

  ```bash
  herdr worktree create --cwd /path/to/repo --branch task-a --no-focus
  ```

どちらもJSONを返す。`result` から `workspace_id` を必ずパースして使う（IDは閉じると圧縮されるので、古いIDを推測で使い回さない）。

## 2. 編成の決定とワーカーの起動

### 編成の決め方

ユーザーが編成（エージェント種別・台数・役割）を明示した場合はそれに従う。**指定がない場合は自分がタスク内容から下の役割プリセットで自動編成する。** ユーザーに編成の確認を求めない。起動前に1行だけ報告する:

> 編成: worker-auth-impl (implement/pi) + worker-auth-review (review/opencode) で開始します

### 役割プリセット

<!-- TODO(snyt45): 役割→エージェントの割当は仮置き。好みに合わせて書き換える -->
| 役割 | エージェント | 使いどころ | TASK.mdに含める要点 |
|---|---|---|---|
| implement | `pi` | 機能実装・バグ修正 | ゴール、完了条件、テストの実行方法 |
| test | `pi` | テスト追加・修正・実行 | 対象範囲、テストコマンド |
| review | `opencode` | implementの成果物レビュー | 対象ブランチ/diff、レビュー観点 |
| research | `opencode` | コードベース調査・技術調査 | 質問、期待する報告フォーマット |

### スケール規則

- 独立したタスク1つ = ワーカー1台。無関係なタスクを1台に相乗りさせない。
- 同時稼働は3〜4台まで。超える分はキューにして、完了したワーカーの枠で順次投入する。
- implementの成果物は原則、別のreviewワーカーに回す（実装した本人に自己レビューさせない）。
- ワーカー名は `worker-<タスク>-<役割>` 形式（例: `worker-auth-impl`）。

### 起動手順

```bash
herdr agent start worker-a --workspace <WS_ID> --no-focus \
  --env ORCH_PANE="$HERDR_PANE_ID" \
  -- claude
```

- ワーカー名（`worker-a` 等）はタスク内容がわかる名前にする。以後の `agent send` / `agent read` / `agent wait` は全てこの名前で指定できる。
- `--env ORCH_PANE` で自分のペインIDを渡す。ワーカーが報告の宛先解決に使う。

起動後、入力プロンプトが出るまで待つ:

```bash
herdr agent wait worker-a --status idle --timeout 30000
```

## 3. タスクの指示

長い指示はEnterで途中送信されるのを避けるため、タスクファイル経由で渡すのが確実:

1. タスク内容を作業ディレクトリの `TASK.md` に書き出す（背景・ゴール・完了条件・報告方法を含める）。
2. 1行の起動指示を送る:

```bash
herdr pane run <worker-pane-id> "TASK.md を読んでタスクを実行してください"
```

短い指示なら直接1行で送ってよい。`agent send` はEnterを送らない（打ち込むだけ）ので、メッセージ送信には `pane run`（テキスト+Enter）を使うこと。

### TASK.mdに必ず含める報告プロトコル

```markdown
## 報告方法
あなたはherdr上のワーカー「worker-a」です。オーケストレーターへの連絡は以下で行う:
- 完了時: herdr pane run "$ORCH_PANE" "[worker-a] 完了: <結果の要約>"
- 質問・ブロック時: herdr pane run "$ORCH_PANE" "[worker-a] 質問: <内容>"
- $ORCH_PANE が無効な場合は `herdr agent list` で orchestrator という名前のエージェントを探し、その pane_id に送る
```

ワーカー側も `~/.agents/skills/herdr` スキルを持っているので、herdr CLIの使い方自体は知っている。

## 4. 監視と応答

- 全体把握: `herdr agent list`（`agent_status`: idle / working / blocked / done / unknown）
- 完了待ち: `herdr agent wait worker-a --status idle --timeout 600000`
  （`wait` に指定できるstatusは idle / working / blocked / unknown。「done」はUI上の未読概念なので、完了検知は idle 待ち + read で行う）
- 出力確認: `herdr agent read worker-a --source recent --lines 100`
- **blocked を検知したら**（権限ダイアログ等）: `agent read` で内容を確認し、
  - 安全な確認なら `herdr pane send-keys <pane-id> Enter` 等で応答する
  - 判断が必要なら `herdr notification show "worker-aが承認待ち" --sound request` でユーザーに知らせる
- ワーカーからの報告は自分の入力欄にユーザーメッセージとして届く。`[worker-name]` プレフィックスで発信元を識別する。

複数ワーカーの並列監視は、タイムアウト付き `agent wait` を順番に回すか、定期的に `agent list` をポーリングする。

## 5. 回収と片付け

1. `agent read` で最終出力を確認し、成果物（diff、ファイル、ブランチ）を検証する。
2. 必要ならワーカーに追加指示を `pane run` で送る（セッションはコンテキストを保持している）。
3. 完了したワークスペースを閉じる:

   ```bash
   herdr workspace close <WS_ID>          # 通常のworkspace
   herdr worktree remove --workspace <WS_ID>  # worktreeの場合
   ```

4. ユーザーへ全体の結果をまとめて報告する。

## 注意事項

- IDは永続しない。ワーカーの指定は基本的に名前（`agent rename` / `agent start` の名前）で行い、ペインIDが必要なときは都度 `agent list` から取り直す。
- ワーカーの生成中に `pane run` でメッセージを送ると入力欄にキューされ、生成完了後に処理される（消えはしない）。
- ワーカーを増やしすぎない。同時に走らせるのは監視できる数（3〜4）まで。
