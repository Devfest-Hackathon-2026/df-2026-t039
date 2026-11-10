# API 通信とキャッシュ

## 全体の流れ

```
画面 → ServiceLocator.xxxRepository → ApiProxy → ApiClient → hono-api
                                        └→ CacheManager
```

| クラス | ファイル | 役割 |
|---|---|---|
| `ApiClient` | `services/api_client.dart` | HTTP リクエストを送る。JSON の変換とエラー処理をする |
| `ApiProxy` | `services/cache/api_proxy.dart` | GET の結果をキャッシュする。書き込み系のあとに、関連するキャッシュを消す |
| `CacheManager` | `services/cache/cache_manager.dart` | キャッシュの保存場所。有効期限（TTL）を持つ |
| リポジトリ | `services/repositories/` | API ごとのメソッドをまとめたもの |
| `ServiceLocator` | `services/service_locator.dart` | 上のクラスを作って、どこからでも使えるようにする |

## ApiClient

- ベース URL は `.env` の `API_BASE_URL` です。
- タイムアウトは 150 秒です。AI の返信に最大 2 分ほどかかるためです。
- 2xx 以外の応答は `ApiException` になります。

## キャッシュのルール

- キャッシュするのは GET だけです。キーはメソッドとパスとクエリで決まります。
- 有効期限が切れたキャッシュは、読み出したときに捨てます。
- `forceRefresh: true` を渡すと、キャッシュを使わずに取り直して、結果で上書きします。
- `createTrip` や `updateTrip` などの書き込みは、`^GET:/api/trips` に合うキャッシュを消します。

### 有効期限（TTL）

| データ | TTL |
|---|---|
| 旅行の一覧 | 10 分 |
| 旅行の詳細 | 10 分 |
| 直近の旅行 | 5 分 |
| 保存した場所 | 15 分 |
| 場所の検索、近くの場所 | 15 分 |
| チャットの履歴 | キャッシュしない |

## リポジトリ

| リポジトリ | 主なメソッド |
|---|---|
| `TripRepository` | `listTrips`、`getUpcomingTrip`、`getTrip`、`createTrip`、`updateTrip` ほか |
| `MessagesRepository` | `listMessages`、`sendMessage`、`newClientMessageId` |
| `PlacesRepository` | `getNearbyPlaces`、`searchPlaces`、`createPlace` |
| `SavedPlacesRepository` | `listSavedPlaces`、`createSavedPlace`、`deleteSavedPlace` |

```dart
final data = await ServiceLocator.tripRepository.listTrips(status: 'planned');
await ServiceLocator.tripRepository.getUpcomingTrip(forceRefresh: true);
await ServiceLocator.tripRepository.updateTrip(tripId, {'status': 'completed'});
```

## 新しい API を追加するには

1. `services/repositories/` の該当するリポジトリにメソッドを追加する。
2. GET なら `cacheTtl`（秒）を、書き込みなら消したいキャッシュのパターンを渡す。
3. 画面からは `ServiceLocator.xxxRepository` を通して呼ぶ。

## Q&A

**Q. 更新したのに画面が古いままです。**
A. 更新の API は関連するキャッシュを消しますが、画面がすでに持っているデータは変わりません。`forceRefresh: true` で取り直して `setState` を呼んでください。別のタブの画面には `HomePage.refreshSignal` のような通知が必要です。
