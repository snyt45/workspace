---
name: rspec-runner
description: PRの差分から関連するRSpecテストを特定して実行するスキル。PRの番号またはURLを渡すと、差分に含まれるspecファイルと、変更されたソースファイルに対応するspecファイルを自動的に検出し、bundle exec rspecで実行する。結果は--format documentationのツリー形式で表示する。「rspec」「テスト実行」「PR specを回して」「PRのテスト」「spec実行」といった依頼で使うこと。PRの番号やURLが含まれるテスト実行の依頼には必ずこのスキルを使う。
---

# RSpec Runner

PRの差分から関連するspecファイルを特定し、まとめて実行する。

## 使い方

ユーザーから以下のいずれかを受け取る:
- PR番号: `123`
- PR URL: `https://github.com/org/repo/pull/123`

## 実行手順

### 1. PRの差分からファイル一覧を取得

```bash
gh pr diff <PR番号> --name-only
```

URLが渡された場合は番号部分を抽出して使う。

### 2. specファイルを特定

差分のファイル一覧から、実行すべきspecファイルを2つのルートで集める。

**A. 差分に直接含まれるspecファイル**

`_spec.rb` で終わるファイルをそのまま対象に加える。

**B. 変更されたソースファイルに対応するspec**

`_spec.rb` 以外のRubyファイル（`.rb`）について、対応するspecファイルのパスを推測する。基本パターン:

| ソースファイル | 対応するspec |
|---|---|
| `app/models/user.rb` | `spec/models/user_spec.rb` |
| `app/controllers/users_controller.rb` | `spec/controllers/users_controller_spec.rb` |
| `app/services/billing/charge.rb` | `spec/services/billing/charge_spec.rb` |
| `lib/utils/parser.rb` | `spec/lib/utils/parser_spec.rb` |

変換ルール:
- `app/` で始まるファイル → `app/` を `spec/` に置換し、拡張子を `_spec.rb` に
- `lib/` で始まるファイル → 先頭に `spec/` を付けて、拡張子を `_spec.rb` に

推測したパスが実際に存在するかを `test -f` で確認し、存在するものだけを対象にする。

### 3. 重複を除去して実行

集めたspecファイルの重複を除去し、`bundle exec rspec` で実行する。

```bash
bundle exec rspec <ファイル1> <ファイル2> ... --format documentation
```

対象のspecファイルが0件だった場合は、ユーザーにその旨を伝えて終了する。

### 4. 結果を表示

rspecの `--format documentation` の出力をそのまま表示する。実行結果のサマリー行（例: `4 examples, 0 failures`）も含める。

ユーザーがコピペしやすいよう、出力はコードブロックで囲む。

## 注意点

- specファイルの対応関係はプロジェクトの規約に依存する。上記の変換ルールで見つからない場合は、`find spec/ -name "*対応する名前*_spec.rb"` でファジー検索を試みてもよい。
- rspecの実行ディレクトリはプロジェクトルート（Gemfileがある場所）で行う。
- Docker環境のプロジェクトでは `bundle exec` の代わりに `docker compose exec` が必要になることがある。ユーザーの環境に合わせて調整する。
