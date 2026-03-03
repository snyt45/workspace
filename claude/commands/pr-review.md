---
allowed-tools:
  - Bash(git log:*)
  - Bash(git diff:*)
  - Bash(git show:*)
  - Bash(git status:*)
  - Bash(git branch:*)
  - Bash(git remote:*)
  - Bash(git ls-files:*)
  - Bash(git blame:*)
  - Bash(git grep:*)

  - Bash(gh pr view:*)
  - Bash(gh pr diff:*)
  - Bash(gh pr checks:*)
  - Bash(gh pr list:*)
  - Bash(gh pr status:*)
  - Bash(gh issue view:*)
  - Bash(gh issue list:*)
  - Bash(gh repo view:*)
  - Bash(gh workflow view:*)
  - Bash(gh workflow list:*)
  - Bash(gh run view:*)
  - Bash(gh run list:*)

  - Read(*.md)
  - Fetch(*)
description: "引数で指定したPR IDのレビューを行います。使用法: /pr-review [PR_ID（省略可）]"
---

### 使用例

/pr-review 1234 → gh pr view 1234, gh pr diff 1234, gh pr checks 1234
/pr-review → gh pr view, gh pr diff, gh pr checks

### PR 詳細レビュー自動化

PR レビュー時は以下のプロンプトでブランチの変更内容を構造化して要約・分析：

このブランチで作成されているプルリクエストの内容と差分をチェックし、どのような変更が行われたかまとめてください。
次の観点で整理してください：

- 主な変更内容
- 重大な指摘事項
- 軽微な改善提案
- 変更の影響範囲
- 潜在的なリスク・不確実性
- 人間が最終確認すべき観点

### フィードバックラダー（優先度順）

1. 🚨 ブロッカー: マージ前に必須修正（セキュリティ、重大バグ、データ損失リスク）
2. ⚠️ 重要: 強く推奨される改善（パフォーマンス、設計問題、技術的負債）
3. 💡 提案: 検討すべき改善案（可読性、将来の拡張性、リファクタリング）
4. 📝 nitpick: 任意の軽微な改善（スタイル、命名、コメント）
5. ✨ 称賛: 良い実装の認識（学習価値のある箇所、エレガントな解決策）

### レビュー出力フォーマット

- **[総合評価]**: X/10 点
- **[概要]**: 変更の目的と全体像
- **[重大な指摘事項]**: セキュリティ・パフォーマンス・データ品質の問題（-2 ～-3 点/件）
- **[軽微な改善提案]**: コードスタイル・可読性・保守性の改善（-0.5 ～-1 点/件）
- **[影響範囲]**: 変更による他システム・ユーザーへの影響
- **[リスク・不確実性]**: 潜在的な問題・テスト観点
- **[人間が最終確認すべき観点]**: AI では判断困難な業務ロジック・設計判断
