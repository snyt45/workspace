---
name: hunk-review
description: Interacts with live Hunk diff review sessions via CLI. Inspects review focus, navigates files and hunks, reloads session contents, and adds inline review comments. Use when the user has a Hunk session running or wants to review diffs interactively.
---

# Hunk Review (スタブ)

実体は brew でインストールした hunk 本体に同梱されており、常にバイナリと同バージョンのスキルが使われる。

1. `hunk skill path` を実行して同梱スキルの SKILL.md のパスを得る（`hunk` が見つからなければ「hunk が未インストール」と伝えて終了）
2. そのファイルを読み、以降はその指示に従う
