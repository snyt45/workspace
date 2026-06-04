# チートシート

## Vimium

| キー | 動作 |
|------|------|
| `h / j / k / l ` | スクロール |
| `gg` / `G` | ページトップ/ボトム |
| `d` / `u` | 半ページスクロール |
| `H` / `L` | 前/次のページ |
| `f` | リンクを開く（現在タブ） |
| `F` | リンクを開く（新しいタブ） |
| `r` | ページをリロード |
| `x` | タブを閉じる |
| `t` | 新規タブを開く |
| `J` / `K` | タブを左/右へ移動 |
| `/` | ページ内検索 |
| `gi` | 入力欄にフォーカス |
| `o` / `b` | ブラウザ検索 / ブックマーク検索 |
| `yy` | ページURLをコピー |


## Zsh

| キー/コマンド | 説明 |
|---------------|------|
| `ide` | レイアウト選択 |
| `Ctrl + r` | 履歴検索 (fzf) |
| `z <dir>` | ディレクトリ移動 (zoxide) |
| `zi` | ディレクトリ選択 (zoxide) |
| `g` | git |
| `lz` | lazygit |
| `v` | nvim |
| `vd` | nvim +DiffviewOpen |
| `vdh` | nvim +DiffviewFileHistory |
| `c` | opencode |
| `cx` | Claude Code |


## Ghostty

| キー | 説明 |
|------|------|
| `Cmd + D` | 垂直分割 |
| `Cmd + Shift + D` | 水平分割 |
| `Cmd + T` | 新規タブ |
| `Cmd + W` | タブを閉じる |
| `Cmd + [` / `Cmd + ]` | ペイン移動 |
| `Cmd + Shift + [` / `Cmd + Shift + ]` | タブ移動 |

## tmux

Prefix = `C-t`

| キー | 説明 |
|------|------|
| `Prefix - v` | 垂直分割 |
| `Prefix - s` | 水平分割 |
| `Prefix - h / j / k / l` | ペイン移動 |
| `Prefix - H / J / K / L` | ペインをスワップ |
| `Prefix - t` | ズーム（全画面） |
| `Prefix - T` | 部分ズーム（縦方向のみ。横レイアウト維持） |
| `Prefix - i` | ペイン番号を表示。続けて番号キーで該当ペインへジャンプ |
| `Prefix - q` | ペイン閉じる |
| `Prefix - e` | 全ペイン同時入力 ON |
| `Prefix - E` | 全ペイン同時入力 OFF |
| `Prefix - I` | tpmプラグインをインストール |
| `Prefix - U` | tpmプラグインを更新 |

### ウィンドウ

| キー | 説明 |
|------|------|
| `Prefix - c` | 新規ウィンドウ作成 |
| `Prefix - ,` | ウィンドウ名を変更 |
| `Prefix - w` | ウィンドウ一覧を表示・切替 |
| `Prefix - n` | 次のウィンドウへ移動 |
| `Prefix - p` | 前のウィンドウへ移動 |
| `Prefix - <` | 現在のウィンドウを1つ左へ |
| `Prefix - >` | 現在のウィンドウを1つ右へ |
| `Prefix - 1`〜`9` | 番号指定でウィンドウ移動 (1始まり) |
| `Prefix - &` | 現在のウィンドウを閉じる | 

### セッション

| キー | 説明 |
|------|------|
| `Prefix - d` | デタッチ |
| `Prefix - $` | セッション名変更 |
| `Prefix - N` | 新規セッション作成 |

## Neovim

leader = `,`

### 基本キーマップ

| キー | モード | 説明 |
|------|------|------|
| `Esc` | n | 検索ハイライト解除 |
| `C-^` | n | 前のバッファに戻る |
| `,x` | n | バッファを閉じる |
| `,c` | n | 現在のファイルパスをコピー |
| `,cc` | v | ファイルパス + 選択コードをマークダウン形式でコピー |
| `,m` | n | Markdownプレビュー |
| `,t` | n | 水平分割でターミナルを開く |
| `Esc Esc` | t | ターミナルモードを抜ける |
| `lz` | n | Lazygit 起動 |

### コメント

| キー | モード | 説明 |
|------|------|------|
| `gcc` | n | 現在行のコメントトグル |
| `gc` | v | 選択範囲をコメント |

### ファイルエクスプローラー (snacks.explorer)

| キー | モード | 説明 |
|------|------|------|
| `,e` | n | エクスプローラー開閉 |
| `l` / `<CR>` | n | ディレクトリに入る / ファイルを開く |
| `h` | n | ディレクトリを閉じる |
| `<BS>` | n | 親ディレクトリへ |
| `a` / `d` / `r` | n | 新規作成 / 削除 / リネーム |
| `c` / `m` / `p` | n | コピー / 移動 / ペースト |
| `H` / `I` | n | 隠しファイル / gitignoreファイル トグル |
| `]g` / `[g` | n | 次/前のgit変更 |
| `]d` / `[d` | n | 次/前の診断 |
| `<leader>/` | n | 配下をgrep |

### ファイル検索・grep (fff.nvim)

| キー | モード | 説明 |
|------|------|------|
| `,,` | n | ファイル検索 |
| `,r` | n | grep検索 |
| `,rw` | n | カーソル下の単語でgrep |

### その他の検索 (snacks.picker / telescope)

| キー | モード | 説明 |
|------|------|------|
| `,o` | n | 最近使ったファイル (snacks) |
| `,b` | n | バッファ一覧 (snacks) |
| `,gs` | n | git status (snacks) |

### ファイルジャンプ (harpoon)

| キー | モード | 説明 |
|------|------|------|
| `,a` | n | 現在のファイルをharpoonに追加 |
| `,h` | n | harpoonメニュー表示 (順序変更・削除可) |
| `,1`〜`,4` | n | 登録ファイルに直接ジャンプ |

### カーソルジャンプ (flash)

| キー | モード | 説明 |
|------|------|------|
| `s` | n/v/o | ラベル付きジャンプ |
| `S` | n/v/o | Treesitterノード選択 |

#### Remote action 

| 操作 |
|------|
| `yr`(遠くをコピー) → ラベル → `iw`(単語選択) → `viwp`(単語選択して貼り付け) |
| `dr`(遠くを削除) → ラベル → `iw`(単語選択) → `viwp`(単語選択して貼り付け) |
| `cr`(遠くを書き換え) → ラベル → `iw`(単語選択) → `viwp`(単語選択して貼り付け) |

### LSP

| キー | モード | 説明 |
|------|------|------|
| `gd` | n | 定義ジャンプ |
| `gy` | n | 型定義ジャンプ |
| `gr` | n | 参照一覧 |
| `K` | n | ホバー  |
| `gl` | n | diagnostic |
| `,rn` | n | リネーム |
| `,ca` | n | コードアクション |
| `,cs` | n | ソースアクション |

LSP管理は組み込みコマンドを使う 

| コマンド | 説明 |
|----------|------|
| `:lsp restart [client]` | LSP再起動 (引数省略でカレントバッファの全クライアント) |
| `:lsp stop [client]` | LSP停止 |
| `:lsp enable [config]` | LSPを有効化 (現在/今後のバッファ) |
| `:lsp disable [config]` | LSPを無効化 (起動中なら停止) |
| `:checkhealth vim.lsp` | LSP状態を確認 (`:che lsp` でlsp系health全部に一致) |

### GitHub Copilot

| キー | モード | 説明 |
|------|------|------|
| `Right` | i | サジェストを受け入れる |
| `C-l` | i | 単語単位で受け入れる |
| `C-j` | i | 次のサジェスト |
| `C-k` | i | 前のサジェスト |
| `C-e` | i | サジェストを閉じる |

### Copilot NES (Sidekick.nvim)

Next Edit Suggestions: Copilot が「次にここも編集するでしょ？」を予測してインライン diff で提示。
sidekick の CLI 統合機能は使わず、**NES のみ利用**。AIチャットは tmux 別pane の `c` (opencode) / `cx` (claude) alias で。

| キー | モード | 説明 |
|------|------|------|
| `<Tab>` | n | NES 提案があれば: ジャンプ → もう一度で apply。無ければ通常の `<Tab>` |

NES 操作コマンド:

| コマンド | 説明 |
|---------|------|
| `:Sidekick nes enable` | NES 有効化 |
| `:Sidekick nes disable` | NES 無効化 |
| `:Sidekick nes toggle` | NES トグル |
| `:Sidekick nes update` | 手動で次の編集案を取得 |

ヘルスチェック: `:checkhealth sidekick` で Copilot LSP 検出状況を確認。

### Git (gitsigns)

| キー | モード | 説明 |
|------|------|------|
| `]c` | n | 次の変更箇所へ |
| `[c` | n | 前の変更箇所へ |
| `,gb` | n | blame表示 |
| `,go` | n/v | カーソル位置をGitHubで開く (commit固定permalink、ビジュアル選択で範囲リンク) |

コマンドパレット (`,?` → Commands) から実行:

| エントリ | 説明 |
|---------|------|
| `[GitSigns] 比較ベース変更` | 比較対象のブランチを変更 (デフォルト: origin/main) |
| `[GitSigns] 比較ベースをリセット` | 比較対象をインデックス(デフォルト)に戻す |

### Git diff (Diffview)

ターミナルから起動:

| コマンド | 説明 |
|----------|------|
| `vd` | diffビューを開く |
| `vdh` | コミット履歴を開く |

Neovim内から起動:

| キー | モード | 説明 |
|------|------|------|
| `,gg` | n | 全差分ビューを開く (レビューモード時は `base...HEAD --imply-local`) |
| `,gf` | n | 現バッファの単一ファイル差分を開く (レビューモード時は `base...HEAD --imply-local`) |
| `,gh` | n | コミット履歴を開く |

コマンドパレット (`,?` → Commands) から実行:

| エントリ | 説明 |
|---------|------|
| `[Diffview] 全差分` | DiffviewOpen を起動 (レビューモード時はbase差分) |

### レビューモード

baseブランチを宣言すると、Diffview が `base...HEAD` を参照するようになる (`--imply-local` で右ペインがワーキングツリーの実バッファになり、差分内から `gd` 等の LSP 操作が直接効く)。`,gs` は通常の git status のまま。

| コマンド | 説明 |
|----------|------|
| `:ReviewStart [base]` | レビューモード開始 + Diffview 自動起動 (引数省略時はtelescopeでbase選択) |
| `:ReviewEnd` | レビューモード終了 + Diffview を閉じる |

Diffview タブ内:

| キー | モード | 説明 |
|------|------|------|
| `<Tab>` / `<S-Tab>` | n | 次/前の変更ファイルへ |
| `<leader>e` | n | file panel をトグル |
| `g?` | n | Diffview のキーマップヘルプを表示 |

### コマンドパレット (command-palette)

キーマップやコマンドを検索して実行できる。`desc` が `[` で始まるキーマップとコマンドパレット専用コマンドが一覧に表示される。

| キー | モード | 説明 |
|------|------|------|
| `,?` | n | Commands / Keymaps を選択して開く (2段メニュー) |

### Overlook (peek definition)

LSPの定義やカーソル位置をスタック可能なフロートpopupで表示。popupは編集可能で `:w` で保存もできる。

| キー | モード | 説明 |
|------|------|------|
| `,pd` | n | 定義をpeek |
| `,pp` | n | カーソル位置をpeek |
| `,pu` | n | 直前のpopupを復元 |
| `,pU` | n | 全popupを復元 |
| `,pc` | n | 全popupを閉じる |
| `,pf` | n | popup / rootをフォーカス切替 |
| `,ps` | n | popupを水平分割で開く |
| `,pv` | n | popupを垂直分割で開く |
| `,pt` | n | popupを新規タブで開く |
| `,po` | n | popupを元ウィンドウで開く |
| `q` (popup内) | n | 最上位のpopupを閉じる |

### quickfix

| キー | モード | 説明 |
|------|------|------|
| `]q` | n | 次のquickfix項目 |
| `[q` | n | 前のquickfix項目 |
| `,q` | n | quickfixリストのトグル |
| `,Q` | n | quickfixリストをクリア |

### ウィンドウ・バッファ操作

| キー | モード | 説明 |
|------|------|------|
| `C-w s` | n | 水平分割 |
| `C-w v` | n | 垂直分割 |
| `C-w x` | n | 隣のウィンドウと入れ替え |
| `C-w H/J/K/L` | n | ウィンドウを指定方向の端に移動 |
| `mm` | n | ズームトグル (カレントを縦横最大化 / もう一度で等分に戻す) |

### 折りたたみ

| キー | モード | 説明 |
|------|------|------|
| `zM` | n | 全て折りたたむ |
| `zR` | n | 全て展開 |
| `zc` | n | カーソル位置を折りたたむ |
| `zo` | n | カーソル位置を展開 |

### ツール管理

| コマンド | 説明 |
|----------|------|
| `:Mason` | LSPサーバ管理 |
| `:ConformInfo` | フォーマッタ設定の確認 |


## GitHub (snacks.gh)

`,?` → Commands (コマンドパレット) から呼ぶ。`gh` CLI使用。

| エントリ | 説明 |
|---------|------|
| `[Snacks] Issue一覧 (open)` | OpenなIssue一覧 → bufferで開く |
| `[Snacks] Issue一覧 (all)` | closed含む全Issue |
| `[Snacks] PR一覧 (open)` | OpenなPR一覧 → bufferで開く |
| `[Snacks] PR一覧 (all)` | closed/merged含む全PR |

PR/Issue buffer内のキーマップ:

| キー | 動作 |
|------|------|
| `<CR>` | アクションメニュー (diff/merge/checkout/browser/label/react/review等) |
| `i` | タイトル/本文を編集 |
| `a` | コメント追加 (コメント上なら返信、diff行上ならインラインコメント) |
| `c` | Close |
| `o` | Reopen |

編集/コメント入力のscratchウィンドウ内:

| キー | 動作 |
|------|------|
| `<C-s>` | 送信 (ノーマル/インサート両対応)。`:wq`では送信されない |

## Git (コマンドライン)

| コマンド | 説明 |
|----------|------|
| `g s` | git status |
| `g ds` | git diff --staged (ステージ済みの差分表示) |
| `g l` | ログ (50件、カラー付き) |
| `g bc` | fzfでブランチを選んでcheckout |
| `g ls` | fzfでコミットを選んでshow (プレビュー付き) |
| `g fixup` | fzfでコミットを選んでfixupコミット作成 |
| `g aicommit` | AIでコミットメッセージ自動生成 |


## worktrunk (wt)

Git worktree 管理 CLI。並行作業や AI agent 用ブランチを高速に切り替え/作成する。

| コマンド | 説明 |
|----------|------|
| `ws` | 引数なし: 対話 picker (live preview / Alt-c で新規作成) |
| `ws <branch>` | 既存ブランチなら switch、無ければ自動 create して switch |
| `ws -` | 直前の worktree へ |
| `ws ^` | デフォルトブランチへ |
| `ws pr:123` | GitHub PR #123 の worktree へ |
| `wt list` | worktree 一覧 |
| `wt remove` | 現 worktree を削除 (マージ済みならブランチも) |
| `wt merge` | 現ブランチをデフォルトブランチへマージ (squash + rebase + remove) |

picker 内のキーバインド:

| キー | 動作 |
|------|------|
| `↑/↓` | 移動 |
| 文字入力 | fuzzy filter |
| `Enter` | 選択した worktree へ switch |
| `Alt-c` | 入力した名前で worktree を新規作成 |
| `1`〜`5` | preview タブ切替 (HEAD±, log, main…±, remote⇅, summary) |
| `Alt-p` | preview パネル開閉 |
| `Esc` | キャンセル |

設定ファイル:

- User config: `~/.config/worktrunk/config.toml` (全プロジェクト共通)
- Project config: `.config/wt.toml` (リポジトリで共有)

## karabiner キーマップ

| キー | 動作 |
|------|------|
| `ESC` | 英数キー + ESC (IME切替) |
| `英数+h/j/k/l` | カーソルキー (上下左右) |
| `英数+a/e` | 行頭/行末 |
| `英数+u/i` | 前の単語/次の単語 |
| `英数+n/m` | BackSpace/Delete |
| `CapsLock` | Command (Mac内蔵) / Control (外部KB) |


