import type { Context } from 'hono'
import { z } from 'zod'

export type ApiEnv = { Variables: { userId: string } }
export class ApiError extends Error {
  constructor(
    public status: 400 | 401 | 404 | 409 | 502 | 503 | 504,
    public code: string,
    message: string,
  ) {
    super(message)
  }
}
export const idSchema = z
  .string()
  .regex(/^[1-9]\d*$/)
  // zod v4 は regex に失敗しても refine を実行するため、数字以外で BigInt が例外を投げないよう先に確かめる。
  .refine((v) => !/^\d+$/.test(v) || BigInt(v) <= 9223372036854775807n, 'IDが範囲外です')
export function validate<T extends z.ZodType>(schema: T, value: unknown): z.output<T> {
  const result = schema.safeParse(value)
  if (!result.success)
    throw new ApiError(
      400,
      'INVALID_INPUT',
      result.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; '),
    )
  return result.data
}
export async function body<T extends z.ZodType>(
  c: Context,
  schema: T,
): Promise<z.output<T>> {
  let value: unknown
  try {
    value = await c.req.json()
  } catch {
    throw new ApiError(400, 'INVALID_JSON', 'JSON形式で送信してください')
  }
  return validate(schema, value)
}
export function notFound(): never {
  throw new ApiError(404, 'NOT_FOUND', '対象が見つかりません')
}
