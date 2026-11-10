# アプリの構成

## 概要

日本国内の旅行を AI チャットで相談しながら計画するアプリです。データは `hono-api`（Cloud Run 上の API）から取得します。ただしプロフィール画面だけは、ローカルのサンプルデータ（`lib/data/example_user_data.json`）を表示します。

## 画面

下のナビゲーションバーで 5 つの画面を切り替えます。画面は `IndexedStack` に入っているので、切り替えても状態が残ります。

| タブ | 画面 | 内容 | 使う API |
|---|---|---|---|
| 0 | `HomePage` | 直近の旅行を表示。「完了」ボタンで旅行を完了にする | `GET /api/trips/upcoming`、`PATCH /api/trips/:id` |
| 1 | `SearchPage` | 場所の検索と、現在地の近くの場所。場所の保存 | `GET /api/places/search`、`GET /api/places/nearby`、`POST /api/places`、`POST /api/saved-places` |
| 2 | `ProfilePage` | プロフィール、旅行の履歴（`MyTripsPage`）、保存した場所（`SavedPlacesPage`） | `GET /api/trips`、`GET/DELETE /api/saved-places` |
| 3 | `SettingsPage` | 設定 | なし |
| 4 | `ChatListPage` → `ChatPage` | チャットの一覧と、AI との会話 | [chat.md](./chat.md) を参照 |

ナビゲーションバー中央の「＋」ボタンは、チャット一覧（タブ 4）を開きます。

## フォルダの役割

```
lib/
├── main.dart              アプリの入口。ServiceLocator の初期化、タブの切り替え
├── bottom_navigation.dart 下のナビゲーションバー
├── pages/                 画面
├── widgets/               複数の画面で使う部品（旅程の表示 TripDetails など）
├── services/              API 通信、キャッシュ、リポジトリ
├── data/                  サンプルの JSON
├── customPaints/          点線の枠などの描画
└── util/                  位置情報の取得
```

## 起動の流れ

1. `main()` で `.env` を読み込む（`API_BASE_URL`）。
2. `ServiceLocator.initialize()` で、API クライアント、キャッシュ、リポジトリを作る。
3. 画面は `ServiceLocator.tripRepository` のように、リポジトリ経由で API を呼ぶ。

詳しくは [api-and-cache.md](./api-and-cache.md) を見てください。

## 画面をまたぐ更新

`IndexedStack` の中の画面は、切り替えても作り直されません。チャットで旅程を確定すると、`HomePage.refreshSignal`（`ValueNotifier`）を更新します。`HomePage` はこれを監視していて、直近の旅行を取り直します。

## 旅程の表示

`TripDetails`（`lib/widgets/trip_details.dart`）が旅行の見出しと日ごとの予定を表示します。ホーム画面とチャットの旅程パネルで共通です。`title` が `null` のときは `destination` を表示し、`to` が `null` のときは時刻の終わりを省略します。

## テスト

`test/` に画面とサービスのテストがあります。実行は `flutter test` です。
