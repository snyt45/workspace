---
name: toypo-api-search
description: 画面名から API エンドポイントを探します。
---

## 使い方

```
/toypo-api-search ユーザー一覧
/toypo-api-search 店舗管理
```

## 実行内容

1. まず現在地を確認して、work/ディレクトリを見つけてください
2. work/ディレクトリ内の 4 つのリポジトリを確認してください：

   - toypo-api（バックエンド API）
   - toypo-app（メインアプリ）
   - toypo4store-app（店舗向けアプリ）
   - toypo4store-web（店舗向け Web）

3. フロントエンドのリポジトリ（toypo-app、toypo4store-app、toypo4store-web）で「{ユーザーが指定した画面名}」を含むファイルを検索してください

   - .js、.jsx、.ts、.tsx、.vue ファイルを対象に検索
   - 見つかったファイルのパスを表示

4. 見つかったファイルの中から、API を呼び出している部分を探してください

   - axios.get、axios.post、fetch、api.get などのパターン
   - 特に「/api/」で始まる URL に注目

5. 見つかった API エンドポイント（例：/api/users、/api/stores）をリストアップしてください

6. toypo-api リポジトリで、見つかったエンドポイントの実装を検索してください

   - ルーティング定義（router.get、app.post など）
   - 該当するコントローラーやハンドラー

7. 最後に以下の形式でまとめてください：
   - 検索した画面名
   - 見つかったフロントエンドファイル
   - 使用されている API エンドポイント
   - バックエンドの実装ファイル
