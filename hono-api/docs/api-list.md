# hono-api API一覧（フロントエンド向け）

## サーバーを手元で動かす

```bash
cd hono-api
docker compose up -d   # 先にDB
npm run dev            # 次にAPI。curl localhost:8080/health/db が {"ok":true} ならOK
```

初めてのときは先に [README.md](../README.md) の「初回セットアップ」を行う（`npm install`、`.env` の作成、DBのテーブル作成、AIチャット用のDB作成、`gcloud auth application-default login`）。古いマイグレーションで作ったDBは形が違うので作り直す。

## 接続

- **URL**：デプロイ先はDMで共有。手元で動かすときは `http://localhost:8080`、Androidエミュレーターからは `http://10.0.2.2:8080`。
- **認証**：`/api/*` と `/me` には `Authorization: Bearer <Firebase IDトークン>` が必要（デプロイ先での扱いはDMで共有）。
  - 手元のサーバーでは、`.env` にある `DEV_AUTH_TOKEN` の値を送ればデモユーザーとして扱われる。
- **Flutter Web**：サーバーの `CORS_ORIGINS` に実際のOrigin（例 `http://localhost:3000`）を入れてもらう。

## 共通ルール

- `?` が付いた項目は省略できる。IDはすべて文字列。`user_id` は送らない（トークンから決まる）。
- 未定は `null`、空の一覧は `[]`。日付は `YYYY-MM-DD`、時刻は日本時間の `HH:mm`。金額は円/人の整数（0は無料）。
- 送るJSONに知らないキーがあると400。返ってきたデータを丸ごと送り返さず、入力の項目だけ送る。
- `limit` の既定は20、上限は一覧系100・検索系20。一覧は総件数を返さないので、続きは `offset` をずらして取る。

## エラー

形は `{ error: { code（エラーコード）, message（日本語の説明） } }`。

| ステータス | 意味 |
|---|---|
| 400 / 401 / 404 | 入力が不正 / 認証失敗 / 存在しない・他人のデータ |
| 409 | 競合（旅程より短い日数への変更、同じ旅行でAIが返信作成中 `TRIP_BUSY` など） |
| 413 / 500 | 送信データが1MiB超え / サーバーエラー |
| 502 / 503 / 504 | Google検索の接続エラー / 未設定・利用制限 / タイムアウト |

## すぐ試す

`<デプロイURL>` を共有されたURL（末尾の `/` なし）に、`{id}` を返ってきた `id` に置き換える。

```
<デプロイURL>/health/db
<デプロイURL>/api/trips/upcoming
<デプロイURL>/api/trips?status=completed
<デプロイURL>/api/trips/{id}
<デプロイURL>/api/saved-places
<デプロイURL>/api/places/search?q=京都
<デプロイURL>/api/places/nearby?latitude=35.0&longitude=135.77
<デプロイURL>/api/trips/{id}/messages
```

```bash
curl -X POST <デプロイURL>/api/trips -H 'Content-Type: application/json' -d '{}'
curl -X POST <デプロイURL>/api/trips/{id}/messages -H 'Content-Type: application/json' \
  -d '{"client_message_id":"<UUID>","text":"京都に2人で行きたい"}'
curl -X POST <デプロイURL>/api/saved-places -H 'Content-Type: application/json' -d '{"place_id":"{id}"}'
```

Flutter ではベースURLを1か所にまとめる：`const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '<デプロイURL>');`

## エンドポイント

| メソッド | パス | 入力 | 出力 |
|---|---|---|---|
| GET | `/health` | なし | `{ ok }` |
| GET | `/me` | なし | `{ uid（ユーザーID） }` |
| GET | `/api/trips` | query: `status?（状態）`, `limit?（件数）`, `offset?（開始位置）` | `{ trips: Trip[] }` |
| GET | `/api/trips/upcoming` | なし | `{ trip: Trip \| null }`（次に行く旅行） |
| POST | `/api/trips` | body: `TripInput` | 201 `{ trip: Trip }` |
| GET | `/api/trips/:id` | なし | `{ trip: Trip }` |
| PATCH | `/api/trips/:id` | body: `TripInput` の一部 ＋ `status?（状態）`（1項目以上） | `{ trip: Trip }` |
| PUT | `/api/trips/:id/itinerary` | body: `{ itinerary（日ごとの予定）: TripItemInput[][], unassigned_items?（日が未定の予定）: TripItemInput[] }` | `{ trip: Trip }` |
| DELETE | `/api/trips/:id` | なし | 204 |
| GET | `/api/trips/:id/messages` | なし | `{ messages: ChatMessage[] }` |
| POST | `/api/trips/:id/messages` | body: `{ client_message_id（送信ID・uuid）, text（本文・2000文字まで） }` | `{ message: ChatMessage, trip: Trip, suggested_places（おすすめの場所）: Place[] }` |
| GET | `/api/places/search` | query: `q（検索語）`, `limit?（件数）`, `page_token?（次ページ用）` | `{ places: SearchPlace[], next_page_token（次ページ用） }` |
| GET | `/api/places/nearby` | query: `latitude（緯度）`, `longitude（経度）`, `radius?（半径m・既定1000・上限50000）`, `limit?（件数）`, `included_types?（種類・カンマ区切り）`, `rank?（DISTANCE 近い順［既定］/ POPULARITY 人気順）` | `{ places: SearchPlace[], next_page_token（常にnull） }` |
| POST | `/api/places` | body: `{ name（名前）, location?（住所）, google_place_id?（GoogleのID）, latitude?（緯度）, longitude?（経度） }` | 201 `{ place: Place }` |
| GET | `/api/saved-places` | query: `limit?（件数）`, `offset?（開始位置）` | `{ places: Place[] }` |
| POST | `/api/saved-places` | body: `{ place_id（場所ID） }` | `{ place: Place }` |
| DELETE | `/api/saved-places/:id` | なし | 204 |

## 型

### Trip（旅行）

| フィールド | 型 |
|---|---|
| `id`（旅行ID） | string |
| `title`（タイトル） | string \| null |
| `destination`（行き先） | string（未定なら `"行き先未定"`） |
| `start_date`（開始日） / `end_date`（終了日） | `YYYY-MM-DD` \| null |
| `duration_days`（日数） | number \| null |
| `participant_count`（人数） | number \| null |
| `budget`（予算・円） | number \| null |
| `preferences`（希望・好み） | string[] |
| `status`（状態） | `draft`（下書き） / `planned`（計画済み） / `completed`（完了） |
| `itinerary`（日ごとの予定） | TripItem[][] |
| `unassigned_items`（日が未定の予定） | TripItem[] |

**TripInput**（旅行の作成・更新）：`Trip` から `id`・`status`・`itinerary`・`unassigned_items` を除いたもの。すべて省略できる。`status` は PATCH でのみ指定できる。

### TripItemInput（予定の入力）

| フィールド | 型 |
|---|---|
| `type`（種類） | `place_entertainment`（観光） / `place_food`（食事） / `place_accommodation`（宿泊） / `movement`（移動） |
| `title?`（タイトル） | string \| null |
| `place_id?`（場所ID） | string \| null |
| `from?`（開始時刻） / `to?`（終了時刻） | `HH:mm` \| null |
| `end_day_offset?`（終了が何日後か） | number（既定0） |
| `price?`（料金・円） | number \| null |
| `movement_type?`（移動手段） | `walk` / `train` / `bus` / `car` / `taxi` / `airplane` / `boat` / `other` \| null |
| `estimated_travel_minutes?`（移動時間・分） | number \| null |
| `notes?`（メモ） | string \| null |

- 移動手段と移動時間は `type` が `movement` のときだけ指定できる。予定は合計300件まで。
- **TripItem**（予定）：`TripItemInput` から `place_id` を除き、`id`（予定ID）と `place`（場所）: `Place | null` を足したもの。

### Place（場所）

| フィールド | 型 |
|---|---|
| `id`（場所ID） | string |
| `name`（名前） | string |
| `location`（住所） | string |
| `category`（カテゴリ） | string |
| `google_place_id`（GoogleのID） | string \| null |
| `latitude`（緯度） / `longitude`（経度） | number \| null |
| `is_saved`（保存済みか） | boolean |

- チャットの `suggested_places` には `maps_url`（Googleマップのリンク）も付く。
- **SearchPlace**（検索結果の場所）：`Place` に `maps_url`（Googleマップのリンク）: `string | null` と `attributions`（データ提供元の表示）: `{ provider, provider_uri }[]` を足したもの。DBに未登録の場所は `id` が `null`。

### ChatMessage（チャットのメッセージ）

`{ id（メッセージID）: string, role（発言者）: 'user'（ユーザー） | 'assistant'（AI）, text（本文）: string }`

## 動きの注意点

### 旅行

- `POST /api/trips` は空の `{}` でも作れる（`status` は `draft`）。
- `PATCH` は変えたい項目だけ送る。`null` でクリア、省略すると今の値のまま。開始日と終了日の両方があると日数は自動で計算される。
- `GET /api/trips` は開始日の新しい順（日付未定が先）。
- `GET /api/trips/upcoming` は、今日以降に出発する `completed` 以外の旅行のうち、いちばん近い1件。日付未定の下書きは入らないので `?status=draft` で取る。
- `completed` は自動では変わらない。明示的に `PATCH` する。

### 旅程（`PUT /api/trips/:id/itinerary`）

- 毎回まるごと置き換える。`unassigned_items` を省略すると、日が未定の予定は消える。
- `itinerary` の0番目が1日目。予定がない日は `[]`。
- 保存すると予定の `id` は新しくなる。画面は返ってきた `trip` で置き換える。
- 返ってきた予定を送り直すときは、`place.id` を `place_id` に入れ直し、`id` と `place` は外す。

### 場所の検索と保存

- 検索は入力のたびに呼ばず、検索ボタンかdebounceで呼ぶ。キーワード検索の次ページは、同じ `q` と返ってきた `next_page_token` を `page_token` に入れて呼ぶ。
- 保存ボタン：`id` があればそのまま `POST /api/saved-places` に `{ place_id: id }`。`id` が `null` なら、先に `POST /api/places` に `name`・`location`・`google_place_id`・`latitude`・`longitude` を送って登録し、返ってきた `id` で保存する。旅程に入れるときも同じく登録してから `place_id` に使う。
- Google由来の場所を表示するときは、`maps_url` と `attributions`（データ提供元）も表示する。
- 保存は何度送っても重複しない。保存の取り消しは、取り消し済みでも204。

### AIチャット

- 旅行1件につき会話1つ。新しい相談は `POST /api/trips` で空の下書きを作り、その `id` で会話する。対象は日本国内の旅行だけ。
- `client_message_id` はアプリで作るUUID。通信に失敗したら同じ値で送り直す（同じ結果が返り、二重には処理されない）。
- 返信には10〜20秒、まれに1〜2分かかる。HTTPのタイムアウトは長め（例：150秒）にし、送信中は入力を止めて「考え中」を出す。待っている間に同じ旅行へ送ると409 `TRIP_BUSY`。
- 返ってきた `trip` で画面のプランを置き換える。
- `suggested_places` はおすすめ候補で、旅程に入ったわけではない。`location` は空文字、緯度経度は `null`。保存は `{ place_id: id }` で `POST /api/saved-places`。

## 画面とAPIの対応

| 画面 | 呼ぶAPI |
|---|---|
| Home（直近の旅行） | `GET /api/trips/upcoming` |
| Profile（過去 / 予定の旅行） | `GET /api/trips?status=completed` / `GET /api/trips?status=planned` |
| Profile（保存した場所） | `GET /api/saved-places` |
| 旅行の詳細 | `GET /api/trips/:id` |
| 検索 | `GET /api/places/search`、`GET /api/places/nearby` |
| AIで新しく相談 | `POST /api/trips` → `POST /api/trips/:id/messages` |
| AIの相談を再開 | `GET /api/trips/:id/messages` → `POST /api/trips/:id/messages` |
