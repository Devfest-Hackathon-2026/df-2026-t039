import { timingSafeEqual } from 'node:crypto'

type VerifyToken = (token: string) => Promise<{ uid: string }>

// ローカル開発専用。Firebase ログインのない Flutter から npm run dev の API を試すために使う。
// DEV_AUTH_USER_ID と DEV_AUTH_TOKEN が両方あるときだけ有効。本番環境では起動を止める。
export function withDevAuth(verify: VerifyToken, env = process.env): VerifyToken {
  const userId = env.DEV_AUTH_USER_ID?.trim()
  const devToken = env.DEV_AUTH_TOKEN?.trim()
  if (!userId && !devToken) return verify
  if (!userId || !devToken)
    throw new Error('開発用認証には DEV_AUTH_USER_ID と DEV_AUTH_TOKEN の両方が必要です')
  // Cloud Run は K_SERVICE を設定する。本番で認証を素通りさせないよう、起動自体を止める。
  if (env.NODE_ENV === 'production' || env.K_SERVICE)
    throw new Error('開発用認証（DEV_AUTH_*）は本番環境では使用できません')
  if (devToken.length < 16) throw new Error('DEV_AUTH_TOKEN は16文字以上にしてください')
  console.warn(
    `開発用認証が有効です。DEV_AUTH_TOKEN のリクエストはユーザー ${userId} として扱います`,
  )
  const expected = Buffer.from(devToken)
  return async (token) => {
    const supplied = Buffer.from(token)
    if (supplied.length === expected.length && timingSafeEqual(supplied, expected))
      return { uid: userId }
    return verify(token) // それ以外は通常どおり Firebase の ID トークンとして検証する
  }
}
