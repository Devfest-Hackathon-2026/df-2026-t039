import { Hono } from 'hono'
import type { MiddlewareHandler } from 'hono'
import { cors } from 'hono/cors'
import { bodyLimit } from 'hono/body-limit'
import { pool } from './db.js'
import type { ApiEnv } from './lib/api.js'
import { ApiError } from './lib/api.js'
import trips from './api/trips.js'
import places from './api/places.js'
import savedPlaces from './api/saved-places.js'
import messages from './api/messages.js'

type VerifyToken = (token: string) => Promise<{ uid: string }>
// 認証検証の注入はテスト用。起動時はFirebaseの検証関数を渡す。
export function createApp(verifyToken: VerifyToken) {
  const app = new Hono<ApiEnv>()
  const origins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean)
  if (origins.length)
    app.use(
      '*',
      cors({
        origin: origins,
        allowHeaders: ['Authorization', 'Content-Type'],
        allowMethods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
      }),
    )
  app.use(
    '/api/*',
    bodyLimit({
      maxSize: 1024 * 1024,
      onError: (c) =>
        c.json(
          { error: { code: 'BODY_TOO_LARGE', message: 'リクエストが大きすぎます' } },
          413,
        ),
    }),
  )
  // 設定時は全リクエストをこのユーザーとして扱う。本物のログイン導入後は外す。
  const noAuthUserId = process.env.AUTH_DISABLED_USER_ID?.trim()
  if (noAuthUserId)
    console.warn(
      `認証なしモードです。すべてのリクエストをユーザー ${noAuthUserId} として扱います`,
    )
  const authenticate: MiddlewareHandler<ApiEnv> = async (c, next) => {
    let userId: string
    if (noAuthUserId) {
      userId = noAuthUserId
    } else {
      const match = c.req.header('Authorization')?.match(/^Bearer\s+(\S+)$/i)
      if (!match) throw new ApiError(401, 'UNAUTHORIZED', '認証トークンが必要です')
      try {
        userId = (await verifyToken(match[1])).uid
      } catch {
        throw new ApiError(401, 'UNAUTHORIZED', '認証トークンを検証できませんでした')
      }
    }
    c.set('userId', userId)
    // Firebaseの初回利用者も、旅行・場所をそのまま作成できる。
    await pool.query('INSERT INTO users(id) VALUES($1) ON CONFLICT DO NOTHING', [userId])
    await next()
  }
  app.use('/api/*', authenticate)
  app.use('/me', authenticate)
  app.get('/', (c) => c.json({ message: 'Hello Hono!' }))
  app.get('/health', (c) => c.json({ ok: true }))
  app.get('/health/db', async (c) => {
    try {
      await pool.query('SELECT 1')
      return c.json({ ok: true })
    } catch {
      return c.json({ ok: false }, 503)
    }
  })
  app.get('/me', (c) => c.json({ uid: c.var.userId }))
  app.route('/api/trips', trips)
  app.route('/api/trips', messages)
  app.route('/api/places', places)
  app.route('/api/saved-places', savedPlaces)
  app.notFound((c) =>
    c.json({ error: { code: 'NOT_FOUND', message: '対象が見つかりません' } }, 404),
  )
  app.onError((error, c) => {
    if (error instanceof ApiError)
      return c.json({ error: { code: error.code, message: error.message } }, error.status)
    console.error('API処理に失敗:', error)
    return c.json(
      { error: { code: 'INTERNAL_ERROR', message: '処理に失敗しました' } },
      500,
    )
  })
  return app
}
