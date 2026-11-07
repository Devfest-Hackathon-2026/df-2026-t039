# apiサーバーの構築
```bash
cd hono-api
npm install
npm run dev
```

# postgreSQLの起動(docker)
```bash
cd hono-api
docker compose up
```

# 実行

- ブラウザで開く
http://localhost:8080/health


- 以下のコマンドを叩く
```bash
curl http://localhost:8080/health
```
