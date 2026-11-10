# flutter_ui_travelling

日本国内の旅行を AI チャットで相談しながら計画できる Flutter アプリです。

## 必要なもの

- [Flutter SDK](https://docs.flutter.dev/get-started/install)（Dart `^3.13.7` に対応したバージョン）
- Android の場合：Android Studio（エミュレーター）または USB デバッグを有効にした Android 端末
- iOS の場合：Mac、Xcode、実機またはシミュレーター

## セットアップ

### 1. リポジトリを取得して依存パッケージをインストール

```bash
git clone https://github.com/Devfest-Hackathon-2026/df-2026-t039.git
cd df-2026-t039/flutterUI
flutter pub get
```

### 2. `.env` ファイルを作成する（必須）

アプリは起動時に `flutterUI` フォルダ直下の `.env` から API の URL を読み込みます。
`.env` は Git で管理されていないため、**各自で作成する必要があります**。`.env` がないとアプリは起動しません。

`.env.example` をコピーして `.env` を作成してください。

```bash
# Windows (PowerShell)
Copy-Item .env.example .env

# macOS / Linux
cp .env.example .env
```

作成した `.env` を開き、`API_BASE_URL` を実際の API の URL に書き換えます。

```env
API_BASE_URL=https://hono-api-659757296906.asia-northeast1.run.app
```

注意：

- URL は `http://` または `https://` で始まる絶対 URL にしてください。末尾の `/` はあってもなくても構いません。
- `API_BASE_URL` を書かないと `http://localhost:3000` が使われます。実機では接続できません。
- `.env` はアプリに同梱されます。パスワードや API キーなどの秘密情報は書かないでください。
- `.env` を変更したら、アプリを再起動（ホットリスタート、または `flutter run` をやり直し）してください。

### 3. 起動する

```bash
flutter devices   # 接続されている端末・エミュレーターを確認
flutter run       # 起動
```

## 端末へのインストール

### Android（APK）

1. `android/app/src/main/AndroidManifest.xml` に次の行があることを確認します。なければ追加してください。リリースビルドではこの権限がないと通信できません。

   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

2. `.env` を作成してから、APK をビルドします。

   ```bash
   flutter build apk --release
   ```

3. 生成されたファイルを端末に渡します。

   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

4. 端末で APK を開いてインストールします。「提供元不明のアプリ」のインストール許可を求められた場合は許可してください。

USB 接続でインストールする場合は、次のコマンドでも構いません。

```bash
flutter install
```

### iOS

iOS のビルドには Mac と Xcode が必要です。

- **自分の端末で試す**：`ios/Runner.xcworkspace` を Xcode で開き、Signing で自分の Apple ID を選択して、実機を接続して `flutter run` を実行します。無料の Apple ID でも動かせますが、インストールしたアプリは 7 日で期限切れになります。
- **他の人に配布する**：Apple Developer Program（有料）に登録し、TestFlight でテスターを招待します。

## 位置情報について

「近くの場所」の機能で位置情報を使います。初回起動時に位置情報の許可を求められるので、許可してください。

## テスト

```bash
flutter test
```

## トラブルシューティング

**Q. 起動時に `.env` が見つからないというエラーが出ます。**
A. `flutterUI/.env` が作成されていません。「2. `.env` ファイルを作成する」を行ってください。

**Q. 画面に `Error loading ...` と表示されます。**
A. `API_BASE_URL` が間違っているか、API に接続できません。URL とネットワークを確認してください。

**Q. リリース版の APK だけ通信できません。**
A. `AndroidManifest.xml` に `INTERNET` 権限がありません。上記の手順 1 を行ってください。

**Q. AI の返信が遅いです。**
A. 返信には 10〜20 秒、まれに 1〜2 分かかります。「考え中...」が表示されている間はお待ちください。

**Q. `.env` を書き換えたのに反映されません。**
A. `.env` はアプリに組み込まれます。アプリを完全に再起動（必要なら再ビルド）してください。

仕組みの詳細は [docs/](./docs/README.md) を見てください。
