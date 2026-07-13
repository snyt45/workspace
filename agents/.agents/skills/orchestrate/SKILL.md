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

ユーザーの依頼をワーカー単位のタスクに分解する。タスクごとに新規ワークスペースを作る:

```bash
herdr workspace create --cwd /path/to/repo --label "task-a" --no-focus
```

JSONを返すので `result` から `workspace_id` を必ずパースして使う（IDは閉じると圧縮されるので、古いIDを推測で使い回さない）。

**git worktreeは勝手に作らない。** ユーザーが明示的に「worktreeで」と指示した場合のみ `herdr worktree create --cwd /path/to/repo --branch task-a --no-focus` を使う。同一リポジトリで複数ワーカーを並走させるとファイル競合の恐れがある場合は、勝手に隔離せず「直列にするか、worktreeを使うか」をユーザーに確認する。

### チームの共有メモリ（.team/）

作業ディレクトリに `.team/` を作り、ワーカー起動後にロスターを書き出す（自分・ユーザー・後続セッションの復帰用）:

```json
// .team/roster.json — 起動のたびに書き直す使い捨て。リポジトリならgitignoreに入れる
{"team": "impl-review", "task": "<タスク1行>", "orchestrator": "<自分のpane_id>",
 "workers": {"worker-auth-impl": {"agent": "pi"}, "worker-auth-review": {"agent": "opencode"}}}
```

- 各ワーカーにはTASK.mdで「決定事項・引き継ぎメモを `.team/<ワーカー名>.md` に随時書く」よう指示する。結論だけ知りたいときは画面を読み返すよりこのメモを読む方が確実。
- ワーカーの指定は名前で行うので、pane_idはrosterに保存しない（IDは圧縮されて古くなるため）。

## 2. チームの選択

**編成は即興で組んではいけない。** 同ディレクトリの `teams.md`（`~/.agents/skills/orchestrate/teams.md`）を読み、そこに定義されたチームから選ぶ。台数・エージェント種別・モデル・ペインレイアウトはすべてチーム定義に従う。

- ユーザーがチーム名を指定した場合（「research-duoで」等）はそれに従う。
- 指定がない場合はタスク内容に合うチームを選び、起動前に1行だけ報告する:

  > チーム: impl-review で開始します（worker-auth-impl / worker-auth-review）

- どのチームも合わない場合は勝手に編成せず、近いチームの流用案または `teams.md` への新チーム追加案を提示してユーザーの確認を取る。

### 起動手順

```bash
herdr agent start worker-a --workspace <WS_ID> --cwd /path/to/workdir --no-focus \
  --env ORCH_PANE="$HERDR_PANE_ID" \
  -- claude
```

- ワーカー名（`worker-a` 等）はタスク内容がわかる名前にする。以後の `agent send` / `agent read` / `agent wait` は全てこの名前で指定できる。
- **`--cwd` を必ず指定する。** 省略するとworkspaceのcwdではなく `$HOME` で起動する（実測）。
- `--env ORCH_PANE` で自分のペインIDを渡す。ワーカーが報告の宛先解決に使う。
- **pi / opencode には `OPENCODE_API_KEY` が必要。** シェルのzsh関数（ensure_opencode_api_key）で遅延読み込みしているため `agent start` 経由では設定されない。同一シェル内で取得して `--env` で渡す:

  ```bash
  KEY=$(op read "op://Development/opencode_zen/credential")  # 初回はTouch ID認証
  herdr agent start ... --env OPENCODE_API_KEY="$KEY" -- pi
  ```

- 2台目以降を同じworkspaceに横並びで配置するには `--split right` を付ける。

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

### TASK.mdテンプレート

```markdown
# タスク: <1行>

あなたはherdr上のワーカー「<worker名>」です。

## ゴール
<何を作る/調べるか>

## 制約
<触ってよい範囲・使ってよいもの。触ってはいけない場所を明記>

## 受け入れ基準
<番号付きで、コマンドと出力で検証できる観測可能な基準。雰囲気ではなく実行結果で確認できること>

## 進め方
- 決定事項・引き継ぎメモは `.team/<worker名>.md` に随時書く
- 完了前に、受け入れ基準を自分で実際に実行して確認する

## 完了契約
作業が終わったら必ず次の2つを行う:
1. 最後に次の1行を正確に出力する（オーケストレーターの完了検知に使われる）:
   `HERDR-DONE: <worker名> | <1行要約>`
2. オーケストレーターへ報告を送る:
   `herdr pane run "$ORCH_PANE" "[<worker名>] 完了: <1行要約>"`
   （`$ORCH_PANE` が無効なら `herdr agent list` で orchestrator を探し、その pane_id に送る）

質問・ブロックで進めない場合は `HERDR-BLOCKED: <worker名> | <内容>` を出力し、同様に報告を送る。
```

**sentinel行（`HERDR-DONE:`）が主の完了シグナル、pane run報告は副。** ワーカー側の権限設定でherdrコマンドが承認待ちになっても、sentinelだけで完了検知が成立する。タスクが1行に収まらないのは分割サインでもある — 大きすぎるタスクは複数のTASK.mdに割る。

ワーカー側も `~/.agents/skills/herdr` スキルを持っているので、herdr CLIの使い方自体は知っている。

## 4. 監視と応答

**ポーリング（read + sleepのループ）はしない。** ブロッキングのwaitで待つ。

- 完了待ち（主）: sentinel行を待つ。ワーカーのpane_idは `herdr agent get <worker名>` で取り直す:

  ```bash
  herdr wait output <worker-pane> --match "HERDR-DONE: <worker名>" --timeout 600000
  ```

  タイムアウト時はexit 1。マッチしたら `herdr agent read <worker名> --source recent-unwrapped --lines 60` で要約行と直前の出力を回収する。
- 完了待ち（副）: `herdr agent wait <worker名> --status idle --timeout 600000`。sentinelが出ないままidleになったら、完了ではなく停止・入力待ちの可能性があるので必ずreadで確認する（`wait` に指定できるstatusは idle / working / blocked / unknown。「done」はUI上の未読概念）。
- 全体把握: `herdr agent list`（`agent_status`: idle / working / blocked / done / unknown）
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

## 復帰手順（オーケストレーターが再起動・コンテキスト喪失したとき）

チームを再spawnしない。既存チームに合流する:

1. 作業ディレクトリの `.team/roster.json` を読み、チーム構成とタスクを把握する。
2. `herdr agent list` でロスターのワーカー名を照合し、現在のpane_idを取り直す。
3. 各ワーカーの状態を `.team/<worker名>.md` のメモと `agent read` で把握する（メモ優先）。
4. エージェントが死んでシェルに落ちているペインだけを報告し、そのワーカーだけ再起動する。チーム全体を作り直さない。

## 注意事項

- IDは永続しない。ワーカーの指定は基本的に名前（`agent rename` / `agent start` の名前）で行い、ペインIDが必要なときは都度 `agent list` から取り直す。
- ワーカーの生成中に `pane run` でメッセージを送ると入力欄にキューされ、生成完了後に処理される（消えはしない）。
- ワーカーを増やしすぎない。同時に走らせるのは監視できる数（3〜4）まで。
