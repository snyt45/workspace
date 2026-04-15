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

### Claude Code通知

settings.jsonのhooksで、Claude Codeのレスポンス完了時にmacOS通知を飛ばす。Ghostty/tmuxどちらでも動作する。


## tmux

Prefix = `C-t`

| キー | 説明 |
|------|------|
| `Prefix-v` | 垂直分割 |
| `Prefix-s` | 水平分割 |
| `C-h/j/k/l` | ペイン移動（Neovim/tmuxシームレス） |
| `Prefix-h/j/k/l` | ペイン移動（Prefix付き） |
| `Prefix-t` | ズーム（全画面） |
| `Prefix-T` | 部分ズーム（縦方向のみ。横レイアウト維持） |
| `Prefix-q` | ペイン閉じる |
| `Prefix-d` | デタッチ |
| `Prefix-e` | 全ペイン同時入力 ON |
| `Prefix-E` | 全ペイン同時入力 OFF |

### コマンド (エイリアス)

| コマンド | 説明 |
|----------|------|
| `t` | tmux |
| `tn <name>` | 新規セッション作成 |
| `td` | デタッチ |
| `tl` | セッション一覧 |
| `tk <name>` | セッション削除 |
| `ts` | fzfでセッション切り替え |

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
| `Esc Esc` | 検索ハイライト解除 |
| `C-^` | 前のバッファに戻る |
| `q` | 無効化 (誤操作防止) |
| `C-h/j/k/l` | ウィンドウ間移動 |
| `,x` | バッファを閉じる |
| `,c` | 現在のファイルパスをコピー |
| `,cc` (ビジュアル) | ファイルパス+選択コードをマークダウン形式でコピー |
| `,m` | Markdownプレビュー (ブラウザ自動起動) |
| `,t` | ターミナルを下に分割して開く |
| `C-a` (インサート) | 行頭へ移動 (Karabiner対応) |
| `C-e` (インサート) | 行末へ移動 (Karabiner対応) |
| `jj` (ターミナルモード) | ノーマルモードに戻る |

コメント:

| キー | 説明 |
|------|------|
| `gcc` (ノーマル) | 現在行のコメントトグル |
| `gc` (ビジュアル) | 選択範囲をコメント |

### ファイルツリー (neo-tree)

| キー | 説明 |
|------|------|
| `,e` | ファイルツリーのトグル |
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

### その他の検索 (telescope)

| キー | 説明 |
|------|------|
| `,o` | 最近使ったファイル (カレントディレクトリのみ) |
| `,b` | バッファ一覧 |
| `,gf` | 変更ファイル一覧 (off: working tree / on: `base...HEAD`) |

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

### Git (gitsigns)

| キー | 説明 |
|------|------|
| `]c` | 次の変更箇所へ |
| `[c` | 前の変更箇所へ |
| `,gs` | 変更をステージング |
| `,gu` | ステージング取り消し |
| `,gr` | 変更をリセット |
| `,gp` | 変更をプレビュー |
| `,gb` | blame表示 |

### Git diff (codediff)

ターミナルから起動:

| コマンド | 説明 |
|----------|------|
| `vd` | diffビューを開く |
| `vdh` | コミット履歴を開く |

Neovim内から起動:

| キー | 説明 |
|------|------|
| `,gg` | diffビューを開く (レビューモード時は `base...HEAD`) |
| `,gh` | コミット履歴を開く |

### レビューモード

baseブランチを宣言すると、gitsigns / CodeDiff / `,gf` が同じbaseを参照するようになる。PRレビュー時に摩擦なく差分を見られる。

| コマンド | 説明 |
|----------|------|
| `:ReviewStart [base]` | レビューモード開始 (引数省略時はtelescopeでbase選択) |
| `:ReviewEnd` | レビューモード終了 |

モードon時はlualineに `Review: <base>` と表示される。gitsignsのsign/hunk移動もbase基準に切り替わる。

エクスプローラ内:

| キー | 説明 |
|------|------|
| `i` | リスト/ツリー表示の切り替え |
| `t` | サイドバイサイド/インラインの切り替え |
| `g?` | キーマップヘルプ表示 |
| `gT` | gdで別ファイルに飛んだ後、codediffのタブに戻る |

### 検索・置換 (grug-far)

コマンドで起動する。コマンドパレット (`,p`) からも検索可能。左sidebar (`topleft vsplit`) で開く。

| キー / コマンド | 説明 |
|------|------|
| `,s` | grug-farバッファに移動 (なければ開く、状態保持) |
| `q` (バッファ内) | 閉じる (状態保持、再度`,s`で復帰) |
| `:GrugFar` | 検索・置換バッファを開く (毎回新規) |
| `:GrugFarFocus` | `,s` と同じ |
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
| `,p` | コマンドパレットを開く |
| `,?` | キーマップ一覧を表示 |

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

`,p` (コマンドパレット) から呼ぶ。`gh` CLI使用。

| エントリ | 説明 |
|---------|------|
| `[Snacks] Issue一覧 (open)` | OpenなIssue一覧 → bufferで開く |
| `[Snacks] Issue一覧 (all)` | closed含む全Issue |
| `[Snacks] PR一覧 (open)` | OpenなPR一覧 → bufferで開く |
| `[Snacks] PR一覧 (all)` | closed/merged含む全PR |

開いたbuffer内: `<cr>`=アクションメニュー (merge/checkout/diff等), `i`=編集, `a`=コメント, `c`=close, `o`=reopen

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
