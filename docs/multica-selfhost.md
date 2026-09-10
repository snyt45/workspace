# Multica セルフホスト

## 概要

セルフホストは独立した 2 つの部分から成る。

| 部分 | 動かすもの | 置き場所 |
|------|-----------|---------|
| Multica サービス | web / API / PostgreSQL | Docker が動く 1 台 |
| runtime | multica daemon + AI コーディング CLI（pi / claude 等） | 実際に開発するマシン |

**実処理は runtime 側で行われる。** サービスが持つのは issue・コメント・run の状態だけで、コードとファイル変更はマシンの外に出ない。この分離が「self-host の意味」「マシン移行」「herdr との関係」を全部決めている。

## この Mac の構成

| 項目 | 値 |
|------|-----|
| サービス本体 | `~/work/multica`（`v0.4.42` にチェックアウト） |
| Web UI | http://localhost:3100 |
| API | http://localhost:8180 |
| ポート変更 | `.env` の `FRONTEND_PORT` / `PORT` で変えられる（デフォルト 3000/8080 は他ツールと被るため 3100/8180 に変更済み）。変更後は CLI と Desktop も更新: `multica config set server_url/app_url` と `~/.multica/desktop.json` |
| bind | どちらも `127.0.0.1` のみ（`docker-compose.selfhost.yml` で固定） |
| 調整データ | Docker volume `multica_pgdata`（PostgreSQL 17 + pgvector） |
| 添付ファイル | Docker volume `multica_backend_uploads` |
| 秘密 | `~/work/multica/.env` |
| CLI 設定・daemon | `~/.multica/` |
| 認証 | メール + 認証コード（メール送信未設定ならコードは backend ログに出る） |

`MULTICA_IMAGE_TAG` は `v0.4.42` にピン留めしてある。`latest` のままだと `pull` のたびに黙って上がる。

## 初回構築

```sh
# 1. サービス本体を取得（リリースタグに合わせる）
cd ~/work
git clone --depth 1 https://github.com/multica-ai/multica.git
cd multica
git fetch --tags --depth 1
git checkout $(git tag -l 'v*' --sort=-v:refname | head -1)

# 2. .env 生成 + イメージ pull + 起動（初回だけ秘密が自動生成される）
make selfhost

# 3. イメージをタグでピン留め
sed -i '' 's/^MULTICA_IMAGE_TAG=latest/MULTICA_IMAGE_TAG=v0.4.42/' .env
docker compose -f docker-compose.selfhost.yml up -d
```

初回の `make selfhost` がやること: `.env` を `.env.example` から作り、`JWT_SECRET` / `POSTGRES_PASSWORD` / `MULTICA_VCS_SECRET_KEY` を生成し、イメージを pull して 3 コンテナを起動する。**`.env` が既にあれば秘密は再生成されない。**

### 検証

```sh
curl -fsS http://localhost:8180/readyz
# {"status":"ok","checks":{"db":"ok","migrations":"ok"}}
```

`/health` は liveness（プロセスが生きていれば ok）。**migration の成否を見るのは `/readyz`。** DB と適用済み migration を照合する。マイグレーションは backend 起動時に自動で走る（手動コマンドはない）。

### アカウント作成

ブラウザなら http://localhost:3100 にメールを入れて、コードをログから読む:

```sh
docker compose -f docker-compose.selfhost.yml logs backend | grep "Verification code"
```

非対話で作りたい場合（mac mini 移行時など）:

```sh
curl -sS -X POST http://localhost:8180/auth/send-code \
  -H 'Content-Type: application/json' -d '{"email":"snyt45@gmail.com"}'
# → ログからコードを読む
curl -sS -X POST http://localhost:8180/auth/verify-code \
  -H 'Content-Type: application/json' \
  -d '{"email":"snyt45@gmail.com","code":"123456"}'   # token と user が返る

# workspace 作成（JWT を Bearer で渡す）
curl -sS -X POST http://localhost:8180/api/workspaces -H "Authorization: Bearer $JWT" \
  -H 'Content-Type: application/json' -d '{"name":"snyt45","slug":"snyt45"}'
```

### CLI と daemon の接続

```sh
# CLI を self-host に向ける
multica config set server_url http://localhost:8180
multica config set app_url http://localhost:3100

# PAT を発行してログイン（`multica login --token` は mul_ プレフィックス必須。
# /auth/verify-code が返す JWT はそのままでは使えない）
curl -sS -X POST http://localhost:8180/api/tokens -H "Authorization: Bearer $JWT" \
  -H 'Content-Type: application/json' -d '{"name":"cli","expires_in_days":3650}'
multica login --token mul_...

multica daemon start
multica daemon status     # Daemon: running / Agents / Workspaces > 0
multica runtime list      # online の runtime が並ぶ
```

daemon は**自動起動しない**。再起動後やログイン後は手で `multica daemon start`。常駐させたい場合は下の「自動起動」を参照。

## 日常運用

```sh
cd ~/work/multica
docker compose -f docker-compose.selfhost.yml ps
docker compose -f docker-compose.selfhost.yml logs -f backend
docker compose -f docker-compose.selfhost.yml up -d      # .env 変更を反映（restart では読まれない）
docker compose -f docker-compose.selfhost.yml down       # 停止（volume は残る）
```

**`down -v` は volume ごと消す。DB が消えるので使わない。**

## アップデート

マイグレーションは forward-only。**pull の前に必ず dump を取る。**

```sh
cd ~/work/multica

# 1. 先にバックアップ
mkdir -p ~/Backups/multica
docker compose -f docker-compose.selfhost.yml exec -T postgres \
  pg_dump -U multica -d multica -Fc > ~/Backups/multica/multica-$(date +%F).dump

# 2. .env のピンを外す
grep MULTICA_IMAGE_TAG .env      # v0.4.42 なら latest（または狙った release）に変える

# 3. 取得して再作成
git pull --ff-only
docker compose -f docker-compose.selfhost.yml pull
docker compose -f docker-compose.selfhost.yml up -d
curl -fsS http://localhost:8180/readyz
```

```sh
docker compose -f docker-compose.selfhost.yml logs -f backend    # migration の進行を追う
```

`git pull` が更新するのは compose 定義（新しい環境変数・サービス・healthcheck）であって、Multica のバージョンではない。**どのバージョンになるかは `docker compose pull` が GHCR に問い合わせた結果で決まる。** `MULTICA_IMAGE_TAG` を固定していると `pull` しても何も上がらない（エラーも警告も出ない）。

### 失敗したときの挙動

**migration は fail-closed。** 危険なデータ状態（既存行が新 constraint に違反、rollup がシードされていない等）を検出すると**適用せず停止する**。失敗の形は「データが壊れる」ではなく「backend が起動しない」。止まっている間データは無傷なので、dump を戻すか、ピンを戻して旧バージョンで起動すれば復旧する。

## バックアップ / リストア

3 つセットで持つ。1 つ欠けると復旧できない。

```sh
cd ~/work/multica

# 1. 調整データ（issue / コメント / run の transcript 全部この中）
docker compose -f docker-compose.selfhost.yml exec -T postgres \
  pg_dump -U multica -d multica -Fc > ~/Backups/multica/multica-$(date +%F).dump

# 2. 添付ファイル
docker run --rm -v multica_backend_uploads:/d -v "$PWD":/b alpine \
  tar czf /b/uploads-$(date +%F).tgz -C /d .

# 3. .env（JWT_SECRET / POSTGRES_PASSWORD / MULTICA_VCS_SECRET_KEY）→ 1Password
```

`pg_dump ... | gzip > x.gz` は**禁止**。パイプの終了ステータスは最後のコマンドのものなので、dump が失敗しても `0` で抜ける。中身が空のアーカイブが「正常に」出来上がる。一度ファイルに落としてから圧縮する。

リストア（空の DB に対して）:

```sh
docker compose -f docker-compose.selfhost.yml exec -T postgres \
  pg_restore -U multica -d multica < ~/Backups/multica/multica-2026-09-11.dump
```

`-Fc` の dump は `pg_restore` で戻す（`psql` ではない）。112 テーブル前後が戻れば成功。

**鍵を失うと壊れる。** `JWT_SECRET` を変えると全員ログアウト。`MULTICA_VCS_SECRET_KEY` や `MULTICA_SLACK_SECRET_KEY` 系は保存済みの暗号文を復号する鍵なので、失うと連携トークンが復号不能になる。`.env` は pg_dump と必ずセットで保管する。

## mac mini への移行

サーバーと daemon は独立しているので、作業も 2 つ。

**サーバー**

```sh
# 新マシン
git clone --depth 1 https://github.com/multica-ai/multica.git && cd multica && make selfhost
# 旧マシンから dump / uploads を持ってくる
git checkout <同じタグ> && sed -i '' 's/^MULTICA_IMAGE_TAG=.*/MULTICA_IMAGE_TAG=v0.4.42/' .env
# .env を旧マシンと同一の秘密で配置（JWT_SECRET を同じにすればログイン状態も維持される）
docker compose -f docker-compose.selfhost.yml up -d
docker compose -f docker-compose.selfhost.yml exec -T postgres \
  pg_restore -U multica -d multica < multica-2026-09-11.dump
```

**daemon**

```sh
multica config set server_url http://localhost:8180   # 別マシンならその URL
multica config set app_url http://localhost:3100
multica login --token mul_...
multica daemon start
```

mac → mac mini はどちらも arm64 macOS なので `pgdata` volume を生でコピーすることもできるが、**pg_dump を使う。** 生の `pgdata` は PostgreSQL の内部表現で、間に入るバージョンが変わると壊れる。dump なら PostgreSQL さえあれば戻せる。

**エージェントは runtime に紐づく。** 新しいマシンは 2 台目の runtime として登録されるので、そちらで動かすには付け替えが要る。

```sh
multica runtime list                                  # 新 runtime の ID を取る
multica agent update <agent-id> --runtime-id <new-id>
```

## トラブルシューティング

| 症状 | 見るところ |
|------|-----------|
| `/readyz` が ok にならない | `docker compose logs backend postgres`。migration 失敗なら backend は起動を繰り返す |
| 認証コードが届かない | メール未設定なら仕様。`logs backend \| grep "Verification code"` |
| daemon に Agents が出ない | AI CLI が PATH にありログイン済みか確認 → `multica daemon restart` |
| issue が queued のまま | `multica daemon status`。daemon が止まっているか workspace を watch していない |
| backend が `password authentication failed` で再起動ループ | 下記 |

### DB のパスワードが `.env` とずれた場合

volume に残っている DB のパスワードと `.env` の `POSTGRES_PASSWORD` が食い違うと、backend が延々と再起動する。`make selfhost` は `.env` が既にあると秘密を再生成しないので、**`.env` を消して作り直した / 別の設定で一度起動した volume が残っている**ときに起きる。

```sh
# 実際の DB が受け付けるパスワードを確かめる（.env.example の既定は multica）
docker run --rm --network multica_default -e PGPASSWORD=multica \
  postgres:17-alpine psql -h postgres -U multica -d multica -tAc 'select 1'

# データを捨ててよいなら作り直す
docker compose -f docker-compose.selfhost.yml down -v
docker compose -f docker-compose.selfhost.yml up -d

# 捨てたくないなら DB 側を .env に合わせる
docker compose -f docker-compose.selfhost.yml exec -T postgres \
  psql -U multica -d postgres -c "ALTER USER multica WITH PASSWORD '<.env の値>'"
```

## 秘密の管理

| 秘密 | 置き場所 |
|------|---------|
| `.env`（`JWT_SECRET` / `POSTGRES_PASSWORD` / `*_SECRET_KEY`） | 1Password。**Git は禁止** |
| CLI の PAT（`mul_...`） | `~/.multica/config.json`。別マシン用に発行した分は 1Password |
| 詳細設計 | [SELF_HOSTING.md](https://github.com/multica-ai/multica/blob/main/SELF_HOSTING.md) / [環境変数リファレンス](https://www.multica.ai/docs/environment-variables) |

`.env` は `.gitignore` 済み。`~/work/multica` は Git 管理下なので、うっかり `git add -A` しない。

## 自動起動（任意）

daemon も Docker Desktop も既定では自動起動しない。常駐させたい場合のみ。

`~/Library/LaunchAgents/ai.multica.daemon.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>ai.multica.daemon</string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/bin/multica</string>
    <string>daemon</string>
    <string>start</string>
    <string>--foreground</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/multica-daemon.out.log</string>
  <key>StandardErrorPath</key><string>/tmp/multica-daemon.err.log</string>
</dict>
</plist>
```

```sh
launchctl load ~/Library/LaunchAgents/ai.multica.daemon.plist
```

daemon は**ユーザーの全権限で動く**（run はそのユーザーが読み書きできるもの全部に触れる）。自動起動するならその前提を飲むこと。

## 制約

- **クラウド → self-host のデータ移行ツールはない。** issue・コメント・run transcript は移らない。スキルは `multica skill files list` で抜いて self-host 側に `skill import --url` で入れられる
- ポートは `127.0.0.1` bind のまま。外出先から使うなら `0.0.0.0` にせず HTTPS のリバースプロキシを前段に置く
- 添付はローカル volume。S3 / R2 に逃がす設定もある（`.env` の `S3_*`）
