---
name: toypo-nicchoku
description: 日直対応スキル。データ修正スクリプトの作成、障害調査、原因分析など日直業務のタスクを処理する。複数リポジトリの並列探索と別エージェントによるダブルチェックを行う。「日直」「データ修正」「スクリプト作成」「原因調査」「障害対応」「ユーザーのデータを直して」「画面が動かない」「エラーが出ている」「SQLを書いて」「クーポンの有効期限を変更」といった依頼で使うこと。toypoやisomaru関連の運用タスク全般にも対応する。
---

# 日直対応スキル

日直で受ける依頼を、探索からダブルチェックまで一貫して処理する。
このスキルはオーケストレーション役。実際の探索とレビューは専用のWorkerエージェントに委譲する。

- 探索: `toypo-explorer`（.claude/agents/toypo-explorer.md）
- レビュー: `toypo-reviewer`（.claude/agents/toypo-reviewer.md）

## リポジトリ一覧

work/ 配下のリポジトリを依頼内容に応じて使い分ける。

### Toypo系
| リポジトリ | 役割 |
|---|---|
| toypo-api | バックエンドAPI（Rails） |
| toypo-app | トイポアプリ（ユーザー向け） |
| toypo-web | LINEミニアプリ |
| toypo4store-app | 店舗アプリ |
| toypo4store-web | 店舗管理画面 |
| toypo-link-preview | ダイナミックリンク |

### 磯丸系
| リポジトリ | 役割 |
|---|---|
| toypo-api | バックエンドAPI（共用） |
| isomaru_app | 磯丸アプリ |
| isomaru-line-mini-app | 磯丸LINEミニアプリ |

依頼文に「磯丸」「isomaru」が含まれていたら磯丸系を探索する。それ以外はtoypo系をデフォルトとする。どちらか判断がつかない場合はユーザーに確認する。

## ワークフロー

### Phase 1: タスク理解

依頼内容を読んで、以下を判断する。

**タスクタイプ**
- **スクリプト作成**: データ修正、一括更新など。成果物はRailsコンソールにそのまま貼って実行できるコード
- **SQL作成**: データ抽出、集計、状態確認など。成果物はそのまま実行できるSQLクエリ
- **調査**: 障害原因の特定、挙動の確認、仕様の把握など。成果物はNotion向けマークダウンの調査報告

判断がつかない場合はユーザーに聞く。「〜を直して」「〜を修正して」「〜を変更して」はスクリプト作成、「〜を抽出して」「〜の件数を出して」はSQL、「〜を調べて」「〜の原因は」は調査と判断してよい。

**探索対象リポジトリ**
- 依頼内容から関連するリポジトリを選ぶ
- DB操作やAPIの話 → toypo-api は必ず含める
- フロント側の話 → 該当するフロントリポジトリを含める
- 不明なら toypo-api + 関連しそうなフロント1-2個で始める

### Phase 2: 並列探索

`toypo-explorer` Workerをリポジトリごとに起動する。**1つのレスポンス内で全てのAgentツールを同時に呼び出す**ことで並列実行される。順番に1つずつ呼んではいけない。

呼び出し方:
```
Agent({
  description: "toypo-api を調査",
  subagent_type: "toypo-explorer",
  prompt: "toypo-api（~/work/toypo-api）で以下を調査してください:
    依頼内容: {依頼の要約}
    キーワード: {モデル名、テーブル名、機能名}"
})

Agent({
  description: "toypo4store-web を調査",
  subagent_type: "toypo-explorer",
  prompt: "toypo4store-web（~/work/toypo4store-web）で以下を調査してください:
    依頼内容: {依頼の要約}
    キーワード: {画面名、コンポーネント名}"
})
```

3つ以上のリポジトリでも全て同時に起動する。サブエージェントからさらにサブエージェントは起動できないため、必ずこのPhaseでメインセッションから直接起動すること。

### Phase 3: 作業実行

探索結果を統合して、タスクタイプに応じた成果物を作成する。

#### Railsスクリプトの場合

Railsコンソールに直接貼って実行できる簡潔なコードを書く。ファイルは作らない。

書き方のポイント:
- 短く、読みやすく。人間がレビューできるシンプルさを保つ
- 必要に応じて puts で変更内容を出力するが、冗長にしない
- update_all が使える場面では使う（コールバック不要なら）
- コールバックが必要な場面では each + update! を使う
- コメントは目的と対象だけ。1-2行で十分
- 複数のレコード操作を行う場合はトランザクションで囲む。ただし update! や save! 単体など、Rails自体がロールバックする1操作だけなら不要

単一操作の例:
```ruby
# store_id:3973 のクーポン(33574)の有効期限を変更
new_expiration = "2026-02-23 21:00:00"
store = Store.find(3973)
coupon_content = store.coupon_contents.find(33574)
coupons = coupon_content.coupons.where(status: [:active, :questionnaire_unanswered, :toypo_questionnaire_unanswered])
coupons.update_all(expiration_date: new_expiration)
```

複数操作の例:
```ruby
# store_id:3973 のクーポン有効期限変更 + ステータス更新
ActiveRecord::Base.transaction do
  store = Store.find(3973)
  coupon_content = store.coupon_contents.find(33574)
  coupon_content.coupons.where(status: :expired).update_all(status: :active)
  coupon_content.update!(expiration_date: "2026-02-23 21:00:00")
end
```

#### SQLクエリの場合

そのまま実行できるSQLを書く。

書き方のポイント:
- 複雑すぎないこと。人間がレビューして意図を理解できるレベルを保つ
- サブクエリを何段もネストするより、CTEやステップごとの分割を使って可読性を上げる
- 集計や抽出の目的をコメントで1行書く
- 破壊的操作（UPDATE/DELETE）の場合は、まずSELECTで対象を確認するクエリも添える

例:
```sql
-- store_id:3973 のアクティブなクーポン件数を確認
SELECT count(*)
FROM coupons c
JOIN coupon_contents cc ON cc.id = c.coupon_content_id
WHERE cc.store_id = 3973
  AND cc.id = 33574
  AND c.status IN (0, 5, 6);
```

#### 調査の場合

調査結果をNotion向けマークダウンで作成する。読み手はエンジニアと非エンジニアの両方。結論から書き、根拠となる事実を具体的に積み上げる構成にする。

調査報告の構成:

```markdown
## 結論

{何が原因だったか、1-2文で端的に。ここだけ読めば概要がわかるように}

---

## 事実（確認できたこと）

### 1) {調査した項目}

- {具体的な事実。ID、日時、件数など}
- {関連する設定や条件}

### 2) {次の調査項目}

- {ユーザー例やデータの追跡結果}
    - {ネストして詳細を記載}

### 3) {さらなる調査}

- {追跡結果や因果関係の整理}
```

この構成の意図: 「結論」で忙しい人が即座に状況を把握でき、「事実」で根拠を追えるようにする。事実セクションでは推測と確認済みの事実を分けて書くこと。推測が入る場合は「〜と推測される」「〜の可能性がある」と明記する。

### Phase 4: ダブルチェック

作業結果を `toypo-reviewer` Workerにレビューさせる。作成者とレビュアーを分離することで、思い込みによる見落としを防ぐ。

呼び出し方:
```
Agent({
  description: "スクリプトをレビュー",
  subagent_type: "toypo-reviewer",
  prompt: "以下のスクリプトをレビューしてください。
    リポジトリ: ~/work/toypo-api
    目的: {何をするスクリプトか}
    スクリプト:
    {スクリプト内容}"
})
```

レビューで問題が見つかった場合は修正して、修正内容をユーザーに報告する。

### Phase 5: 最終出力

ユーザーに以下を提示する:

**スクリプト / SQLの場合**
1. 完成したスクリプト / SQL
2. レビュー結果（問題なし or 修正した内容）
3. 確認してほしいポイント（人間の目で見るべき箇所を具体的に）

**調査の場合**
1. 調査報告（Notion用マークダウン。コピペで貼れる形）
2. レビュー結果
3. 確認してほしいポイント（推測が入っている箇所、追加調査が必要な箇所）
