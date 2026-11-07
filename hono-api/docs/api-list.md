# hono-api API一覧（フロントエンド向け早見表）

起動方法や認証の詳しい説明は [flutter-api.md](flutter-api.md) を参照。

- `/api/*` と `/me` は `Authorization: Bearer <Firebase IDトークン>` が必要。
- エラーは `{ error: { code, message } }` で返る。
- `?` が付いた項目は省略できる。

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
| POST | `/api/trips/:id/messages` | body: `{ client_message_id（送信ID・uuid）, text（本文） }` | `{ message: ChatMessage, trip: Trip, suggested_places（おすすめの場所）: Place[] }` |
| GET | `/api/places/search` | query: `q（検索語）`, `limit?（件数）`, `page_token?（次ページ用）` | `{ places: SearchPlace[], next_page_token（次ページ用） }` |
| GET | `/api/places/nearby` | query: `latitude（緯度）`, `longitude（経度）`, `radius?（半径m）`, `limit?（件数）`, `included_types?（種類・カンマ区切り）`, `rank?（並び順）` | `{ places: SearchPlace[], next_page_token（次ページ用） }` |
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
| `destination`（行き先） | string |
| `start_date`（開始日） | `YYYY-MM-DD` \| null |
| `end_date`（終了日） | `YYYY-MM-DD` \| null |
| `duration_days`（日数） | number \| null |
| `participant_count`（人数） | number \| null |
| `budget`（予算・円） | number \| null |
| `preferences`（希望・好み） | string[] |
| `status`（状態） | `draft`（下書き） / `planned`（計画済み） / `completed`（完了） |
| `itinerary`（日ごとの予定） | TripItem[][] |
| `unassigned_items`（日が未定の予定） | TripItem[] |

### TripInput（旅行の作成・更新）

`Trip` から `id`・`status`・`itinerary`・`unassigned_items` を除いたもの。すべて省略できる。`status` は PATCH でのみ指定できる。

### TripItemInput（予定の入力）

| フィールド | 型 |
|---|---|
| `type`（種類） | `place_entertainment`（観光） / `place_food`（食事） / `place_accommodation`（宿泊） / `movement`（移動） |
| `title?`（タイトル） | string \| null |
| `place_id?`（場所ID） | string \| null |
| `from?`（開始時刻） | `HH:mm` \| null |
| `to?`（終了時刻） | `HH:mm` \| null |
| `end_day_offset?`（終了が何日後か） | number（既定0） |
| `price?`（料金・円） | number \| null |
| `movement_type?`（移動手段） | `walk` / `train` / `bus` / `car` / `taxi` / `airplane` / `boat` / `other` \| null |
| `estimated_travel_minutes?`（移動時間・分） | number \| null |
| `notes?`（メモ） | string \| null |

- `movement_type` と `estimated_travel_minutes` は `type` が `movement` のときだけ指定できる。
- 予定は合計300件まで。

### TripItem（予定）

`TripItemInput` から `place_id` を除き、`id`（予定ID）と `place`（場所）: `Place | null` を足したもの。

### Place（場所）

| フィールド | 型 |
|---|---|
| `id`（場所ID） | string |
| `name`（名前） | string |
| `location`（住所） | string |
| `category`（カテゴリ） | string |
| `google_place_id`（GoogleのID） | string \| null |
| `latitude`（緯度） | number \| null |
| `longitude`（経度） | number \| null |
| `is_saved`（保存済みか） | boolean |

チャットの `suggested_places` には `maps_url`（Googleマップのリンク）も付く。

### SearchPlace（検索結果の場所）

`Place` に以下を足したもの。DBに未登録の場所は `id` が `null`（保存するには先に `POST /api/places` で登録する）。

| フィールド | 型 |
|---|---|
| `maps_url`（Googleマップのリンク） | string \| null |
| `attributions`（データ提供元の表示） | `{ provider, provider_uri }[]` |

### ChatMessage（チャットのメッセージ）

| フィールド | 型 |
|---|---|
| `id`（メッセージID） | string |
| `role`（発言者） | `user`（ユーザー） / `assistant`（AI） |
| `text`（本文） | string |

## 既定値と上限

| 項目 | 既定値 | 上限 |
|---|---|---|
| `limit`（一覧系） | 20 | 100 |
| `limit`（検索系） | 20 | 20 |
| `radius`（半径m） | 1000 | 50000 |
| `rank`（並び順） | `DISTANCE`（近い順） | `POPULARITY`（人気順）も可 |
| `text`（チャット本文） | - | 2000文字 |
