---
name: call-diagram
description: メソッド・API・画面処理の「呼出図」を、クライアント（toypo-web / toypo-lma-builder 等）とサーバー（toypo-api）をまたいで追跡して描くスキル。ASCII呼出図・定義箇所テーブル・呼び出し契機（useEffect等）のコードで回答する。「呼出図」「呼び出し元は」「どのAPIを叩いてる」「コールチェーン」「どこから呼ばれてる」「このAPIを呼んでるのは」といった依頼で使う。
---

# 呼出図 (Call Diagram)

「○○メソッドはどこから呼ばれているか」「どのリポジトリのどの処理がこのAPIを叩いているか」をクライアント⇔サーバー横断で追跡し、図で回答する。

## 調査手順

### 1. 対象名を全リポジトリ横断で検索

```bash
grep -rln "対象メソッド名" ~/work/toypo-api ~/work/toypo-web ~/work/toypo-lma-builder \
  --include="*.rb" --include="*.ts" --include="*.tsx" \
  | grep -vE "node_modules|dist|\.git" 
```

### 2. 定義と参照を区別する

- 定義: `def `、`export const xxx = `、`class〜#method` の宣言行
- 参照: それ以外の呼び出し箇所

※ 同名メソッドが複数クラスに定義されていても、呼び出し元は1箇所ということがある（例: `upsert_line_user_profile!` は LineChannel / LineLiffChannel に定義、呼び出しは ProvidersController#update のみ）。定義と参照は別々に数える。

### 3. クライアント側: エンドポイントで逆引き

API メソッドなら、パス文字列（例 `/line/providers` `/auth/liff/registrations`）をクライアントで grep して HTTP メソッド（get/put/post）と baseURL を確認する。

```bash
grep -rn "line/providers\|liff/registrations" ~/work/toypo-web/src ~/work/toypo-lma-builder/packages ~/work/toypo-lma-builder/apps 2>/dev/null | grep -v node_modules
```

### 4. サーバー側: routes → controller → 対象メソッド

- `config/routes.rb` でエンドポイント行 → `to:` で controller#action を特定
- action を読み、対象メソッドが呼ばれている箇所を確認
- 呼び出し先が resolver / client 経由なら解決クラスも1段辿る

### 5. 呼び出し契機を確認する

「いつ呼ばれるか」をコードで確定する:

- React: `useEffect` + deps（例: `liffId` と `accessToken` が揃ったマウント時）
- イベントハンドラ / ボタン / フォーム送信
- ジョブ / Webhook / cron

## 出力フォーマット

1. **結論を最初に1行**（例: `upsert_line_user_profile` は toypo-api 内のみで、呼び出しは ProvidersController#update の1箇所）
2. **ASCII 呼出図**: クライアント → HTTP → route → controller#action → 呼ばれるメソッド。ファイル:行を併記

```
toypo-web (クライアント)
  src/layouts/Store/StoreLayout.tsx
    └─ useEffect: liffId と accessToken が揃ったら PUT /line/providers
          │
          v
toypo-api (サーバー)
  Api::V2::Line::ProvidersController#update
    ├─ LineLiffChannelResolver.resolve(liff_id)
    ├─ LineLoginApiClient#fetch_profile        … accessToken でLINEプロフィール取得
    └─ channel.upsert_line_user_profile!(user:, line_user_id:, display_name:)
```

3. **定義箇所テーブル**: クラス/ファイル、保存先や内容、呼び出し契機
4. **必要なら該当コード抜粋**（十数行以内）

## 注意

- ユーザーの「〜のはず」という推測は必ず検証して答える。実物が違えば指摘する
- minify 済み dist にヒットしても無視し、ソース（src / packages / app）を優先
- クライアント側にメソッド名が存在しないケースもある（メソッド名は API 側専用、クライアントはエンドポイントだけ叩く）。その場合「クライアント側はエンドポイント呼び出しが出発点」と明記する
- 呼び出し契機コードは deps 配列の注記（いつ再実行されるか）まで含めて抜粋する