---
name: jot
description: 気になったキーワード・課題・問題を ~/work/claude-obsidian/wiki/next.md の Backlog に1行追加する軽量キャプチャ。「/jot」「jot」「これ後で」「気になった」「メモして」「Backlog に積んで」「Backlog 入れといて」といった明示依頼や、会話中にユーザーが stumble / question / 関心を示した時に proactive に「これ jot しますか?」と提案する用途で使う。完全な構造化保存は /save、深い学習セッションは /dojo の役割なので混同しない。
---

# /jot — Backlog に1行追加

走り書き（jot down）でバックログを育てる。詳細な記録より速さ優先。

## 起動

### 明示トリガ
- `/jot "気になったこと"`
- 「これ後で」「気になった」「メモして」「Backlog に積んで」「Backlog 入れといて」「jot」

### Proactive トリガ（重要）

会話中、ユーザーが以下を示した時に**自分から**「これ jot しますか?」と提案する:

- **stumble**: 「あれ?」「分からない」「なんでこうなる」「迷う」
- **question**: 「〜どうやるんだっけ」「〜の使い方は」（本筋から外れる軽い問い）
- **関心**: 「これ面白い」「気になる」「いつか試したい」「ちゃんと理解したい」
- **未消化**: 「あとで読む」「読んでない」「ちゃんと見てない」

提案は**1行**で済ませる。長い説明はしない。
例: 「これ Backlog に積みますか? `Neovim の :checkhealth の中身を理解する`」

## 動作

1. **`~/work/claude-obsidian/wiki/next.md` を Read する**（固定パス）
2. **どのサブセクションに追加するか判断**:
   - 学習・自己投資系
   - 業務由来の wiki 化
   - KAIZEN アワー系
   - dev environment
   - 探索的 ingest 候補
   - 該当なし → `🌱 Backlog` の最下部
3. **1行で追記**（過度に整形しない）:
   ```
   - [ ] **{タイトル}** — {1行コンテキスト}（jotted: YYYY-MM-DD）
   ```
4. **確認は最小限**:
   - 「Backlog に追加しました: `{タイトル}`」とだけ短く返す
   - 何があったかの説明は不要

## ルール

- **1分以内で完了**を目標。会話の流れを止めない
- **重複チェックは軽く**: タイトルが類似していたら1行で通知（「既に `~~` がありそうです、追加しますか?」）
- **削除や昇格はしない**: Backlog 整理は `/dojo` 終了時の責務
- **質問の意図を深掘りしない**: 走り書きなので、jot した内容は後で `/dojo` で展開すれば良い
- **複数同時 jot OK**: 「これとこれを jot」と言われたら2行追加する

## /save / /dojo との使い分け

| ツール | 粒度 | トリガ | 出力先 |
|---|---|---|---|
| **`/jot`**（このスキル） | 1行 Backlog | 軽い気づき / proactive | `wiki/next.md` の Backlog |
| **`/dojo`** | 1段落 learning | バックログ消化時 | `wiki/learning/<topic>.md` |
| **`/save`** (claude-obsidian:save) | 完成された概念ページ | 学びが熟したとき | `wiki/concepts/` `wiki/questions/` 等 |

`/jot` → `/dojo` → `/save` の**情報濃縮カスケード**。逆方向（save から jot）はない。

## 自己改善ループ

`/dojo` と同じ pattern。

- **セッション中**: jot の運用に違和感があれば、`~/.dotfiles/claude/.claude/skills/jot/SKILL.md` の `## Lessons` に1行追加（source を編集）
- **5件溜まる or 月初**: 本体プロンプトへの昇格を検討
- **目的**: 自分の捕捉スタイル（粒度 / カテゴリ / proactive 頻度）の進化を encode する

## Lessons（運用しながら追記）

*まだなし。proactive トリガの精度や粒度が分かってきたらここに記録する。*
