import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { pool } from './db.js'
import { firebaseAuth } from './firebase.js'

const app = new Hono()

app.get('/', (c) => c.json({ message: 'Hello Hono!' }))
app.get('/health', (c) => c.json({ ok: true }))

app.get('/health/db', async (c) => {
  try {
    await pool.query('SELECT 1')
    return c.json({ ok: true })
  } catch (error) {
    console.error('DB接続確認に失敗:', error)
    return c.json({ ok: false }, 503)
  }
})

app.get('/me', async (c) => {
  const authorization = c.req.header('Authorization')
  const match = authorization?.match(/^Bearer\s+(\S+)$/i)

  if (!match) {
    return c.json({ error: '認証トークンが必要です' }, 401)
  }

  try {
    const decodedToken = await firebaseAuth.verifyIdToken(match[1])

    return c.json({
      uid: decodedToken.uid,
    })
  } catch {
    return c.json({ error: '認証トークンを検証できませんでした' }, 401)
  }
})

// cloud runで実際に動いたNode.jsのバージョンを確認する
console.log(JSON.stringify({ event: 'runtime_start', nodeVersion: process.version }))

serve({
  fetch: app.fetch,
  hostname: '0.0.0.0',
  port: Number(process.env.PORT ?? 8080),
})
