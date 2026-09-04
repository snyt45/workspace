# piで学ぶ チュートリアル（5分）

`teach` スキル（プローブ→プラン→ティーチ）＋ `md-log`（Obsidianミラー）の最小フロー。

## 0. 前提（1回だけ）

```sh
brew install librsvg                       # 図のSVG描画（Brewfileに追加済み）
npm i -g @mermaid-js/mermaid-cli           # 図のMermaid描画
```

## 1. vault内でセッションを始める

Obsidianの図埋め込みを描画するには `viz/` がvault内にある必要がある → **vaultの中でpiを起動する**。

```sh
cd ~/Notes/my-vault            # ← Obsidianで開いているフォルダ
touch 学習ログ.md              # md-logは既存ファイルしか受け付けない
pi
```

## 2. ログをリンク

```
/md-log 学習ログ.md
```

→ 以降の講師の説明・quizのQ&Aが `学習ログ.md` に追記されていく。

## 3. 教えてもらう

```
/teach 微分形式を理解したい
```

teachは3フェーズで進む:

| フェーズ | あなたの作業 | 何が起きるか |
|---|---|---|
| **Probe** | quizに答えるだけ | 理解の端を二分探索でマッピング。全問正解だとエスカレートされる |
| **Plan** | 方針＋依存マップ（mermaid DAG）を確認してGOを出す | このタイミングが承認チェック。変ならここで直す |
| **Teach** | ノードごとに 動機→確立→(発見)→quiz確認 | 1ステップずつ。図が必要ならsvg-maker/mermaid-makerがherdr経由で作ってくる |

## 4. Obsidianで見る

```
open -a Obsidian
```

- 数式 → LaTeX描画
- 依存マップ → mermaid描画
- 図 → `![[viz-*.png]]` がvault内 `viz/` から解決される

## 心構え（親より先に言っておくこと）

- teachは**あなたの「その場だけの理解」を防ぐ設計**。quizを落としたら講師が止まって直す。全問正解が続いたら質問が易しすぎ（エッジを探しに行く）。
- 質問したいときはいつでも割り込んでOK。講師は1ノードずつ進み、先回りしない。
- 覚えたことは `学習ログ.md` に残る。後で読み返して復習。

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| 図がObsidianに出ない | `viz/` がvaultの外。vault内でpiを起動する |
| `/md-log` がエラー | ファイルを作ってから再実行（`touch`） |
| 講師がミスを自信満々に言う | 「それwebで確認して」と指示。researcher委譲を促す |
| mmdcが見つからない | `npm i -g @mermaid-js/mermaid-cli` を実行 |