# チートシート

開発環境で使うコマンド、キーバインド、操作方法をまとめたもの。
変更があるたびにここを更新する。


## シェル (zsh)

| キー/コマンド | 説明 |
|---------------|------|
| `Ctrl+r` | 履歴検索 (fzf) |
| `z <dir>` | ディレクトリ移動 (zoxide。過去の移動先を学習) |
| `zi` | インタラクティブにディレクトリ選択 |
| `g` | git のエイリアス |
| `lz` | lazygit のエイリアス (Git TUI) |
| `v` | nvim のエイリアス |
| `vd` | nvim +CodeDiff (diffビュー付きで起動) |
| `vdh` | nvim +"CodeDiff history" (コミット履歴付きで起動) |
| `c` | opencode (AIコーディングエージェント) |
| `cx` | claude --enable-auto-mode (Claude Code自動モード) |


## Ghostty

| キー | 説明 |
|------|------|
| `Cmd+D` | 垂直分割 |
| `Cmd+Shift+D` | 水平分割 |
| `Cmd+T` | 新規タブ |
| `Cmd+W` | タブを閉じる |
| `Cmd+[` / `Cmd+]` | ペイン移動 |
| `Cmd+Shift+[` / `Cmd+Shift+]` | タブ移動 |

## tmux

Prefix = `C-t`

| キー | 説明 |
|------|------|
| `Prefix-v` | 垂直分割 |
| `Prefix-s` | 水平分割 |
| `Prefix-h/j/k/l` | ペイン移動（Prefix付き） |
| `Prefix-t` | ズーム（全画面） |
| `Prefix-T` | 部分ズーム（縦方向のみ。横レイアウト維持） |
| `Prefix-i` | ペイン番号を表示。続けて番号キーで該当ペインへジャンプ |
| `Prefix-q` | ペイン閉じる |
| `Prefix-e` | 全ペイン同時入力 ON |
| `Prefix-E` | 全ペイン同時入力 OFF |
| `Prefix-I` | tpmプラグインをインストール |
| `Prefix-U` | tpmプラグインを更新 |

### ウィンドウ (tab的に使う)

軽量に context 分離したい時はセッションよりウィンドウ。同一セッション内で1プロンプトで飛べる。

| キー | 説明 | 覚え方 |
|------|------|--------|
| `Prefix-c` | 新規ウィンドウ作成 | create |
| `Prefix-,` | ウィンドウ名を変更 | `,` = ラベル貼り |
| `Prefix-w` | ウィンドウ一覧を表示・切替 | window 一覧 |
| `Prefix-n` | 次のウィンドウへ移動 | next |
| `Prefix-p` | 前のウィンドウへ移動 | previous |
| `Prefix-1`〜`9` | 番号指定でウィンドウ移動 (1始まり) | 番号そのまま |
| `Prefix-&` | 現在のウィンドウを閉じる | `&` = 確認付き終了 |

ウィンドウの並び順を入れ替える (`Prefix-:` でコマンド入力):

| コマンド | 説明 |
|---------|------|
| `swap-window -t 2` | 現在のウィンドウをウィンドウ2と入れ替え |
| `swap-window -s 3 -t 1` | ウィンドウ3 と ウィンドウ1 を入れ替え |

### セッション

ウィンドウで足りる日常では出番少なめ。プロジェクトを完全に切替えたい時だけ使う。

| キー | 説明 |
|------|------|
| `Prefix-d` | デタッチ |
| `Prefix-$` | セッション名変更 (プロンプトで入力) |
| `Prefix-N` | 新規セッション作成 (名前プロンプト) |

### シェル alias

| alias | 実体 |
|------|------|
| `t` | `tmux` |
| `tn` | `tmux new -s` |
| `td` | `tmux detach` |
| `tl` | `tmux ls` |
| `tk` | `tmux kill-session -t` |
| `ts` | `tmux switch-client -t` |
| `trn` | `tmux rename-session` |

### ide コマンド (レイアウト)

| コマンド | 説明 |
|----------|------|
| `ide` | fzfでレイアウト選択 |
| `ide ai-single` | NeoVim + エージェント1つ + ターミナル (エージェント選択) |
| `ide ai-single c` | NeoVim + OpenCode + ターミナル |
| `ide ai-single cx` | NeoVim + Claude Code + ターミナル |
| `ide ai-dual` | NeoVim + エージェント2つ + ターミナル (各ペイン選択) |
| `ide ai-dual c cx` | NeoVim + OpenCode(上) + Claude Code(下) + ターミナル |
| `ide ai-dual cx cx` | NeoVim + Claude Code×2 + ターミナル |
| `ide dev` | エディタ + ターミナル3つ |
| `ide dev-full` | エディタ + ターミナル6つ |
| `ide pair` | NeoVim 2つ横並び + ターミナル |


## Neovim

leader = `,`

### 基本キーマップ

| キー | 説明 |
|------|------|
| `Esc` | 検索ハイライト解除 |
| `C-^` | 前のバッファに戻る |
| `q` | 無効化 (誤操作防止) |
| `C-h/j/k/l` | ウィンドウ間移動 |
| `C-d` / `C-u` | 半ページスクロール (カーソル中央維持) |
| `C-f` / `C-b` | 1ページスクロール (カーソル中央維持) |
| `,x` | バッファを閉じる |
| `,c` | 現在のファイルパスをコピー |
| `,cc` (ビジュアル) | ファイルパス+選択コードをマークダウン形式でコピー |
| `,m` | Markdownプレビュー (ブラウザ自動起動) |
| `,t` | 水平分割でターミナルを開く (:split \| terminal) |
| `Esc Esc` (ターミナル) | ターミナルモードを抜ける (insert/term → normal) |
| `lz` (ノーマル) | Lazygit Float起動 (snacks.lazygit) |
| `C-a` (インサート) | 行頭へ移動 (Karabiner対応) |
| `C-e` (インサート) | 行末へ移動 (Karabiner対応) |

コメント:

| キー | 説明 |
|------|------|
| `gcc` (ノーマル) | 現在行のコメントトグル |
| `gc` (ビジュアル) | 選択範囲をコメント |

### ファイルツリー (neo-tree)

| キー | 説明 |
|------|------|
| `,e` | ファイルツリーのtoggle/focus (押すたび: 閉 → focus → 閉じる) |
| `/` | ファイル名で絞り込み |
| `D` | ディレクトリ内でファイル検索 |

### ファイル検索・grep (fff.nvim)

| キー | 説明 |
|------|------|
| `,,` | ファイル検索 (frecency順) |
| `,r` | grep検索 (plain/regex/fuzzy切替: Shift+Tab) |
| `,rw` | カーソル下の単語でgrep |

fff.nvim 操作:

| キー | 説明 |
|------|------|
| `Tab` | マルチ選択 |
| `C-q` | 選択をquickfixに送信 |
| `S-Tab` | grepモード切替 (plain → regex → fuzzy) |
| `C-Up` | クエリ履歴 |

### その他の検索 (snacks.picker / telescope)

| キー | 説明 |
|------|------|
| `,o` | 最近使ったファイル (カレントディレクトリのみ) — snacks |
| `,b` | バッファ一覧 — snacks |
| `,gs` | git status (off: working tree / on: `base...HEAD`) — snacks |

telescope プレビュー操作:

| キー | 説明 |
|------|------|
| `C-d` | プレビューを下にスクロール |
| `C-u` | プレビューを上にスクロール |

### ファイルジャンプ (harpoon)

作業中のファイル(3-4個)を登録して番号キーで一発ジャンプ。プロジェクト単位で永続化される。

| キー | 説明 |
|------|------|
| `,a` | 現在のファイルをharpoonに追加 |
| `,h` | harpoonメニュー表示 (順序変更・削除可) |
| `,1`〜`,4` | 登録ファイルに直接ジャンプ |

### カーソルジャンプ (flash)

ラベル付きの高速ジャンプ。`s<文字>` でラベル表示、ラベルキーで一発ジャンプ。

| キー | 説明 |
|------|------|
| `s` | ラベル付きジャンプ (ノーマル/ビジュアル/オペレータ) |
| `S` | Treesitterノード選択 |
| `r` (operator) | リモートジャンプ (例: `yr` で別の場所をyank) |
| `R` (operator/visual) | Treesitter検索 |
| `C-s` (`/` 検索中) | Flashトグル |

注意: ノーマルモードの `s` (substitute char) は `cl` で代替可能。
`f` / `t` / `F` / `T` はそのまま強化される (ラベル自動表示)。連続移動は `;` 次 / `,` 前 (`,` はleader衝突で遅延あり)。

#### Remote action (カーソル移動せず遠くのテキスト操作)

`<operator>r` → ラベルで飛んで → モーション入力 → **元の位置に戻る**。

| 操作 | 等価動作 |
|------|--------|
| `yr` → ラベル → `iw` | 遠くで `yiw` して元に戻る |
| `dr` → ラベル → `iw` | 遠くで `diw` して元に戻る |
| `cr` → ラベル → `i"` | 遠くで `ci"` して挿入モード (Escで戻る) |
| `yr` → ラベル → `$` | 行末までyankして戻る |
| `yr` → ラベル → `%` | 対応括弧までyankして戻る |

モーションは何でも使える (`iw` / `i"` / `it` / `ip` / `$` / `%` など)。treesitter併用なら `if` (inner function) も可。中止は `<Esc>`。
overlook popup 内でも動く (popup は普通のバッファなので remote action で遠くのテキストを持ってこれる)。

### LSP

| キー | 説明 |
|------|------|
| `gd` | 定義ジャンプ |
| `gy` | 型定義ジャンプ |
| `gr` | 参照一覧 |
| `K` | ホバー (型情報表示、2回押しでウィンドウに入れる) |
| `gl` | diagnosticをフロート表示 |
| `,rn` | リネーム |
| `,ca` | コードアクション |
| `,cs` | ソースアクション (import整理等) |
| `,ll` | LSP再起動 |

### 補完 (nvim-cmp)

| キー | 説明 |
|------|------|
| `Tab` | 次の候補 |
| `Shift+Tab` | 前の候補 |
| `Enter` | 確定 |
| `Ctrl+Space` | 手動で補完メニュー表示 |

### GitHub Copilot

| キー | 説明 |
|------|------|
| `Right` | サジェストを受け入れる |
| `C-l` | 単語単位で受け入れる |
| `C-j` | 次のサジェスト |
| `C-k` | 前のサジェスト |
| `C-e` | サジェストを閉じる |

### AI CLI (Sidekick.nvim)

OpenCode / Claude Code を floating で呼び出す。NES (Next Edit Suggestions) で次の編集案をインラインで提示。

| キー | 説明 |
|------|------|
| `,aa` | AI CLI 選択 (picker。installed だけ表示) |
| `,ao` | OpenCode をトグル |
| `,ac` | Claude Code をトグル |
| `,ap` | プロンプトテンプレ選択送信 |
| `,af` | カレントファイル全体を送信 |
| `,av` | Visual 選択範囲を送信 (visual モード) |
| `,at` | カーソル位置のスコープ (関数/ブロック) を送信 |
| `<Tab>` | NES: AI の次の編集案へジャンプ / 適用 (normal モード) |

floating ウィンドウ内:

| キー | モード | 説明 |
|------|------|------|
| `q` | n | ウィンドウを隠す |
| `<C-q>` | n / t | ウィンドウを隠す (**terminal 入力中も一発で閉じる**) |
| `<C-.>` | n / t | ウィンドウを隠す (Ghostty では効かない場合あり) |
| `<C-p>` | t | プロンプト / コンテキストを挿入 |
| `<C-b>` | n / t | バッファピッカー |
| `<C-f>` | n / t | ファイルピッカー |
| `<C-z>` | n / t | 前のウィンドウに戻る (hide しない) |

NES 操作コマンド:

| コマンド | 説明 |
|---------|------|
| `:Sidekick nes enable` | NES 有効化 |
| `:Sidekick nes disable` | NES 無効化 |
| `:Sidekick nes toggle` | NES トグル |
| `:Sidekick nes update` | 手動で次の編集案を取得 |

ヘルスチェック: `:checkhealth sidekick` で CLI / Copilot LSP 検出状況を確認。

### Git (gitsigns)

| キー | 説明 |
|------|------|
| `]c` | 次の変更箇所へ |
| `[c` | 前の変更箇所へ |
| `,gb` | blame表示 |

コマンドパレット (`,?` → Commands) から実行:

| エントリ | 説明 |
|---------|------|
| `[GitSigns] 比較ベース変更` | 比較対象のブランチを変更 (デフォルト: origin/main) |
| `[GitSigns] 比較ベースをリセット` | 比較対象をインデックス(デフォルト)に戻す |

### Git diff (codediff)

ターミナルから起動:

| コマンド | 説明 |
|----------|------|
| `vd` | diffビューを開く |
| `vdh` | コミット履歴を開く |

Neovim内から起動:

| キー | 説明 |
|------|------|
| `,gg` | 全差分ビューを開く (レビューモード時は `base...HEAD`) |
| `,gf` | 現バッファの単一ファイル差分を開く (レビューモード時は `base...HEAD`) |
| `,gh` | コミット履歴を開く |

コマンドパレット (`,?` → Commands) から実行:

| エントリ | 説明 |
|---------|------|
| `[CodeDiff] ブランチとの差分` | 指定ブランチとHEADの差分を表示 (デフォルト: origin/main) |

### レビューモード

baseブランチを宣言すると、CodeDiff / `,gs` が同じbaseを参照するようになる。PRレビュー時に摩擦なく差分を見られる。

| コマンド | 説明 |
|----------|------|
| `:ReviewStart [base]` | レビューモード開始 + 変更ファイルpicker自動起動 (引数省略時はtelescopeでbase選択) |
| `:ReviewEnd` | レビューモード終了 |

エクスプローラ内:

| キー | 説明 |
|------|------|
| `i` | リスト/ツリー表示の切り替え |
| `t` | サイドバイサイド/インラインの切り替え |
| `g?` | キーマップヘルプ表示 |
| `gT` | gdで別ファイルに飛んだ後、codediffのタブに戻る |

### 検索・置換 (grug-far)

コマンドで起動する。コマンドパレット (`,?` → Commands) からも検索可能。左sidebar (`topleft vsplit`) で開く。

| キー / コマンド | 説明 |
|------|------|
| `,s` | grug-farバッファのtoggle/focus (押すたび: 開 → focus → 閉じる) |
| `q` (バッファ内) | 閉じる (状態保持、再度`,s`で復帰) |
| `:GrugFar` | 検索・置換バッファを開く (毎回新規) |
| `:GrugFarFocus` | 開く or focus (閉じる動作なし) |
| `:GrugFarWithin` | 選択範囲内で検索・置換 (ビジュアルモード) |

grug-farバッファ内でpaths絞り込み切替 (`<localleader>` = `\`):

| キー | 説明 |
|------|------|
| `\1` | pathsを元ファイルのdirに |
| `\2` | pathsを開いているバッファ群に |
| `\3` | pathsをquickfixに |

バッファ内で `,?` を押すと、上記を含むbuffer-localキーマップ一覧が出る。

### コマンドパレット (command-palette)

キーマップやコマンドを検索して実行できる。`desc` が `[` で始まるキーマップとコマンドパレット専用コマンドが一覧に表示される。

| キー | 説明 |
|------|------|
| `,?` | Commands / Keymaps を選択して開く (2段メニュー) |

### Overlook (peek definition)

LSPの定義やカーソル位置をスタック可能なフロートpopupで表示。popupは編集可能で `:w` で保存もできる。

| キー | 説明 |
|------|------|
| `,pd` | 定義をpeek |
| `,pp` | カーソル位置をpeek |
| `,pu` | 直前のpopupを復元 |
| `,pU` | 全popupを復元 |
| `,pc` | 全popupを閉じる |
| `,pf` | popup / rootをフォーカス切替 |
| `,ps` | popupを水平分割で開く |
| `,pv` | popupを垂直分割で開く |
| `,pt` | popupを新規タブで開く |
| `,po` | popupを元ウィンドウで開く |
| `q` (popup内) | 最上位のpopupを閉じる |

### quickfix

| キー | 説明 |
|------|------|
| `]q` | 次のquickfix項目 |
| `[q` | 前のquickfix項目 |
| `,q` | quickfixリストのトグル |
| `,Q` | quickfixリストをクリア |

### ウィンドウ・バッファ操作

| キー | 説明 |
|------|------|
| `C-w s` | 水平分割 |
| `C-w v` | 垂直分割 |
| `C-w x` | 隣のウィンドウと入れ替え |
| `C-w H/J/K/L` | ウィンドウを指定方向の端に移動 |

### 折りたたみ

| キー | 説明 |
|------|------|
| `zM` | 全て折りたたむ |
| `zR` | 全て展開 |
| `zc` | カーソル位置を折りたたむ |
| `zo` | カーソル位置を展開 |

### ツール管理

| コマンド | 説明 |
|----------|------|
| `:Mason` | LSPサーバ管理 |
| `:ConformInfo` | フォーマッタ設定の確認 |


## スクラッチメモ (snacks.scratch)

レビューや作業中の気づきを書き留める永続メモ。cwd + branch 単位で自動保存される（PRブランチごとに別メモ）。

| キー | 説明 |
|------|------|
| `,n` | 現在のcwd+branchのscratchを開く (markdown) |
| `,N` | 既存scratch一覧から選択 |

scratch buffer内: 通常のmarkdown編集。終了時自動保存。再度`,n`で同じ内容が開く。

`,N` の一覧picker内:

| キー | 動作 |
|------|------|
| `<CR>` | 選択したscratchを開く |
| `<C-x>` | scratchを削除 |
| `<C-n>` | 新規scratchを作成 |

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


## karabiner キーマップ

| キー | 動作 |
|------|------|
| `ESC` | 英数キー + ESC (IME切替) |
| `英数+h/j/k/l` | カーソルキー (上下左右) |
| `英数+a/e` | 行頭/行末 |
| `英数+u/i` | 前の単語/次の単語 |
| `英数+n/m` | BackSpace/Delete |
| `CapsLock` | Command (Mac内蔵) / Control (外部KB) |


## VSCode (併用)

| 用途 | 説明 |
|------|------|
| TypeScript開発 | 型ホバー、定義ジャンプ、リファクタリング |
| PRレビュー | GitHub PRs拡張 |
| Claude Code | Claude Code拡張 |
| diff確認 | 差分の視覚的な確認 |
