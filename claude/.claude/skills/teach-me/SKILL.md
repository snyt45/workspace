---
name: teach-me
description: teach + md-log を一気通貫で起動する薄いラッパー。「/teach-me <トピック>」「〜を教えて」「〜を学びたい」で発動。ファイル作成→teach移譲までワンアクションで完結し、会話は md-log hook がファイルに写す。
---

# teach-me

`teach` スキルに教授を移譲し、会話を md ファイルに写して Obsidian で読めるようにする。本スキルはファイル作成と移譲だけを行う。

写すのは md-log hook（`~/.claude/hooks/md-log.py`）。このセッションで Write した、frontmatter に `md-log: true` を持つファイルへ、ターンの終わりごとにユーザーの発言・本文・AskUserQuestion の問いと回答を書き出す。ファイルは毎回作り直されるので、セッション中に手で編集しない。

## フロー

### 1. トピックを特定

引数または依頼文から教える対象トピックを特定する。曖昧な場合は確認する。

### 2. 保存先・ファイル名を決定

**デフォルトパス:** `pkm-vault` スキルの vault 直下の `Learn/`

ユーザーに以下のように確認する:
> デフォルトの `Learn` フォルダに保存しますか？（Y / n / 別のパスを指定）

- `Y` または未入力 → デフォルトパスを使用
- `n` または別パス指定 → 指定されたパスを使用（存在しない場合は親ディレクトリを `mkdir -p` してから作成）

**ファイル名:**
知見キャプチャの instructions のメモ形式に合わせ、`<YYYY-MM-DD HHmm> <日本語タイトル>.md` とする。英語に翻訳しない。

- 日時はファイル作成時点のローカル日時を `date "+%Y-%m-%d %H%M"` で取得する
- 日本語タイトルはトピックを簡潔に表すもの（例: `featureTestHarness bootstrapFailedとonRouterReady`）
- 既存と衝突したら `_2`、`_3` … を付ける

例: `2026-09-14 1530 featureTestHarness bootstrapFailedとonRouterReady.md`

### 3. ファイルを作成

Write で作成する。内容は frontmatter とトピックの見出しだけ:

```markdown
---
md-log: true
---
# {{元のトピック}}
```

作成後、ファイルのフルパスをユーザーに伝える。

### 4. teach に移譲

`teach` スキルを読み込み、Probe → Plan → Teach のフローに従って教える。
