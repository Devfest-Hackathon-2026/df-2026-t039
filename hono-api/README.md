# hono-api

旅行・旅程・場所・AIチャットのAPIサーバー。APIの使い方は [docs/api-list.md](docs/api-list.md) を参照。

## 初回セットアップ（1回だけ）

```bash
cd hono-api
npm install

# .env を作り、値を埋める（DB接続、Firebase、Vertex AI、GOOGLE_PLACES_API_KEY、DEV_AUTH_* など）
cp .env.example .env

# DBを起動して、アプリ用のテーブルを作る（空のDBのみ）
docker compose up -d
docker compose cp db db:/tmp/travel-db
docker compose exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f /tmp/travel-db/init.sql'

# AIチャットの会話を保存するDBを作る（ADK_DATABASE_URL を設定した場合。テーブルはADKが自動で作る）
docker compose exec db sh -c 'createdb -U "$POSTGRES_USER" adk_sessions'

# AIチャット（Vertex AI）用にGoogle Cloudへログイン
gcloud auth application-default login
```

- 古いマイグレーション（`db/migrations/`）で作ったDBが残っている場合は、テーブルの形が違うので `docker compose down -v` でデータを消してから上の手順をやり直す。
- `ADK_DATABASE_URL` を空にすると、会話はメモリに保存される（サーバーを再起動すると消える）。
- DBの詳細は [db/README.md](db/README.md) を参照。

## 起動（毎回）

```bash
cd hono-api
docker compose up -d   # 先にDB
npm run dev            # 次にAPI（http://localhost:8080）
```

## 動作確認

```bash
curl http://localhost:8080/health      # {"ok":true}
curl http://localhost:8080/health/db   # {"ok":true} ならDBにもつながっている
```

フロントエンドからは、`Authorization: Bearer <.env の DEV_AUTH_TOKEN の値>` を付けて呼ぶとデモユーザーとして扱われる（ローカル専用）。Androidエミュレーターからは `http://10.0.2.2:8080`。

## 止める

`npm run dev` は Ctrl+C。DBは `docker compose stop`（データは残る）。
