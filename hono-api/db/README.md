# DB：種類別の定義と初期化

普段の設計確認は **schema/** を見てください。テーブルの現在の完成形を種類別にまとめています。

| ファイル | 種類・役割 |
|---|---|
| [schema/users.sql](schema/users.sql) | ユーザー |
| [schema/trips.sql](schema/trips.sql) | 旅行の基本情報・希望・状態 |
| [schema/trip_items.sql](schema/trip_items.sql) | 日別の旅程・食事・観光・移動 |
| [schema/places.sql](schema/places.sql) | 場所の情報 |
| [schema/saved_places.sql](schema/saved_places.sql) | 気になる場所の保存関係 |
| [schema/agent.sql](schema/agent.sql) | Agentの送信管理・提案場所 |
| [schema/rules.sql](schema/rules.sql) | 更新日時・所有者確認の関数とトリガー |

## 空の新規DBを作る

[init.sql](init.sql) が必要なファイルを依存順に読み込み、まとめて作成します。

```bash
# hono-api ディレクトリから。接続設定はpsqlの標準環境変数などで指定。
psql -v ON_ERROR_STOP=1 -f db/init.sql
```

`psql` はアプリの `.env` / `POSTGRES_*` を自動で読みません。`PGHOST / PGPORT / PGUSER / PGDATABASE / PGPASSWORD` 等を設定するか、接続オプションを指定してください。

ComposeのDBを使う場合は、SQLをコンテナにコピーして実行できます（空のDBのみ）。

```bash
docker compose cp db db:/tmp/travel-db
docker compose exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f /tmp/travel-db/init.sql'
```

新規DBは **init.sqlだけを実行**すれば必要な定義が作成されます。現在のローカルDBは初期化済みなので、再実行は不要です。

## 既存DBについて

init.sqlは空のDB専用です。既存データを保持してテーブル構成を変更するときは、現在の構成を確認したうえで差分のALTER文を用意します。schemaの編集だけでは既存DBに反映されません。

## データの扱い

- 旅行削除で旅程は削除されますが、場所と保存関係は残ります。
- saved_placesの削除は保存解除であり、場所自体の削除ではありません。
- 旅程のscheduled_date / start_at / end_atは旧データ保持用です。新規処理はday_number / start_time / end_time / end_day_offsetを使います。自動同期はありません。
- 日番号と予定日数の整合、日程変更時の旅程調整はservice側で行います。
- agent_requestsは会話送信の再送管理、trip_suggested_placesはAgentが提案した場所を保持します。
- 会話本文はADKがADK_DATABASE_URLのDBに保存します。アプリDBとは別管理で、必要なテーブルはADKが初期化します。
