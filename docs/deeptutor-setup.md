# DeepTutor セットアップ

自ホスト型の個人学習アプリ。pip ルートでインストールする。

## 前提

- mise（python 3.13.12）
- pipx（Homebrew でインストール済み）
- [OpenCode Go](https://opencode.ai/auth) サブスク（$5 初月 → $10/月）。モデル利用の API キーをコンソールから取得しておく。API 利用は Zen の従量課金レートでドル換算してカウントされ、サブスク内に利用上限あり（5 時間/$12・週/$30・月/$60）。上限超過時はブロックされるが、Zen 残高があればコンソールで「Use balance」を有効にすると残高（従量課金）へフォールバックする

## 手順

```sh
# 1. ワークスペース作成（runtime の pin も兼ねる）
mkdir -p ~/work/my-deeptutor && cd ~/work/my-deeptutor
printf 'python 3.13.12\n' > .tool-versions

# 2. インストール（--python 必須: deeptutor は <3.14 要件）
pipx install --python python3 deeptutor

# 3. 対話式設定
deeptutor init
#   LLM:        [c] Custom → Binding は Enter（openai のまま）→ Base URL 編集 Y
#               → https://opencode.ai/zen/go/v1 → Go の API キー → deepseek-v4-flash
#   Embedding:  [s] Skip（OpenCode Go に embedding は存在しない）
#   Web search: [12] DuckDuckGo（キー不要）
deeptutor start
```

## 注意点

### API キーは平文保存される

`data/user/settings/model_catalog.json` に API キーがそのまま入る。commit しないこと。

```gitignore
data/
```

### pipx の python バージョン違いで古い版に落ちる

pipx のデフォルト python が 3.14 だと、pip が「3.14 対応の最新版」を黙って選び、deeptutor 1.5.2 が入る（1.5.12 は <3.14 要件）。`.tool-versions` で 3.13 を pin した状態で `--python python3` を指定すれば最新版が入る。

```sh
pipx uninstall deeptutor
pipx install --python python3 deeptutor
```

### iCloud の Obsidian vault を接続する場合

Knowledge Center で「Link existing」→ Obsidian を選ぶ。vault パスは自動検出されないので自分で入力する（例: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/pkm-vault`、KB の `path` は vault 直下のフォルダ名）。読み書きは vault に直接行われる（コピーしない・インデックスも作らない）。

### PC クリーンアップ後、何が残る・消える

**残る（iCloud 同期）**: Obsidian vault 内の note。deeptutor が生成した学習メモも vault 直下（KB の `path` フォルダ）に書かれるので、ドキュメントだけ見る用途なら再セットアップで足りる。

**消える（`~/work/my-deeptutor/data/` はローカル）**:

- 学習進捗・mastery: `data/user/workspace/learning/`
- チャット履歴: `data/user/chat_history.db`
- co-writer / book / notebook の成果物: `data/user/workspace/`
- 設定・API キー・vault パス: `data/user/settings/`・`data/knowledge_bases/kb_config.json`

学習状態まで維持したいなら `~/work/my-deeptutor/data/` ごとバックアップする（git 管理 or iCloud に同期）。vault だけでは進捗は復元できない。

iCloud 上の vault は **「この Mac に保存」（常時ダウンロード）** に固定しておくこと。cloud-only の placeholder に deeptutor が当たるとハング・失敗する。

### 設定の所在

- 設定ファイル: `data/user/settings/*.json`（キー・トークン含む）
- 学習成果物: `data/user/workspace/`（git 管理したければ workspace だけトラックする）
- 環境変数（`LLM_BINDING` / `LLM_HOST` 等）でも設定可能だが、`.env` ファイルは自動読み込みされない

### 更新

```sh
pipx upgrade deeptutor
```