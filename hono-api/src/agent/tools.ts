import { FunctionTool } from '@google/adk'
import type { Context } from '@google/adk'
import { z } from 'zod'
import { ApiError } from '../lib/api.js'
import { itineraryInputSchema } from '../schema/trip-item.js'
import { listSavedPlaces } from '../service/saved-place-service.js'
import { listSuggestedPlaces } from '../service/suggestion-service.js'
import { replaceItinerary } from '../service/trip-item-service.js'
import { getTrip, listTrips, updateTrip } from '../service/trip-service.js'

export const TRIP_ID_STATE_KEY = 'trip_id'

// ユーザーと旅行は実行コンテキストから取る。モデルに引数で選ばせない。
function scope(ctx?: Context) {
  const tripId = ctx?.state.get<string>(TRIP_ID_STATE_KEY)
  if (!ctx || !tripId) throw new Error('セッションに trip_id がありません')
  return { userId: ctx.userId, tripId }
}

// 業務エラーは例外にせずモデルへ返し、言い直しや確認をさせる。想定外の例外はそのまま投げる。
async function safe<T>(fn: () => Promise<T>) {
  try {
    return { ok: true as const, result: await fn() }
  } catch (error) {
    if (error instanceof ApiError)
      return { ok: false as const, error: { code: error.code, message: error.message } }
    throw error
  }
}

export const getCurrentTrip = new FunctionTool({
  name: 'get_current_trip',
  description: '相談中の旅行プランを最新状態で取得する。プランを変更する前には必ず呼ぶ。',
  parameters: z.object({}),
  execute: (_, ctx) => {
    const s = scope(ctx)
    return safe(() => getTrip(s.userId, s.tripId))
  },
})

export const listPastTrips = new FunctionTool({
  name: 'list_past_trips',
  description:
    'ユーザーの過去の旅行（完了済み）を取得する。訪れた場所を好きな場所と決めつけず、参考情報として使う。',
  parameters: z.object({
    limit: z.number().int().min(1).max(10).default(5).describe('取得件数'),
  }),
  execute: ({ limit }, ctx) => {
    const s = scope(ctx)
    return safe(() => listTrips(s.userId, 'completed', limit, 0))
  },
})

export const listSavedPlacesTool = new FunctionTool({
  name: 'list_saved_places',
  description: 'ユーザーが保存した場所を取得する。返る id は旅程の place_id に使える。',
  parameters: z.object({}),
  execute: (_, ctx) => {
    const s = scope(ctx)
    return safe(() => listSavedPlaces(s.userId, 50, 0))
  },
})

export const listSuggestedPlacesTool = new FunctionTool({
  name: 'list_suggested_places',
  description:
    'この相談で過去に Google Maps に基づいて提案した場所を取得する。返る id は旅程の place_id に使える。提案した場所を旅程に入れる前に呼ぶ。',
  parameters: z.object({}),
  execute: (_, ctx) => {
    const s = scope(ctx)
    return safe(() => listSuggestedPlaces(s.userId, s.tripId))
  },
})

export const updateTripPreferences = new FunctionTool({
  name: 'update_trip_preferences',
  description:
    'ユーザーが合意した旅行の基本情報を保存する。不明な項目や推測した値は送らない。',
  parameters: z.object({
    title: z.string().trim().min(1).max(300).optional().describe('旅行のタイトル'),
    destination: z
      .string()
      .trim()
      .min(1)
      .max(300)
      .optional()
      .describe('日本国内の行き先（例: 京都、北海道・函館）。海外は不可'),
    start_date: z.iso.date().optional().describe('出発日 YYYY-MM-DD'),
    end_date: z.iso.date().optional().describe('最終日 YYYY-MM-DD'),
    duration_days: z
      .number()
      .int()
      .min(1)
      .max(366)
      .optional()
      .describe('日程未定のときの予定日数'),
    participant_count: z.number().int().min(1).max(100).optional().describe('人数'),
    budget: z
      .number()
      .int()
      .min(0)
      .max(Number.MAX_SAFE_INTEGER)
      .optional()
      .describe('一人当たりの予算（日本円）'),
    preferences: z
      .array(z.string().trim().min(1).max(500))
      .max(30)
      .optional()
      .describe('希望のリスト。既存の希望も含めた全体を送る'),
  }),
  // status は受け取らない。draft→planned の確定はユーザーが画面で行う。
  execute: (input, ctx) => {
    const s = scope(ctx)
    if (!Object.keys(input).length)
      return {
        ok: false,
        error: { code: 'NO_CHANGES', message: '更新する項目がありません' },
      }
    return safe(() => updateTrip(s.userId, s.tripId, input))
  },
})

export const updateItinerary = new FunctionTool({
  name: 'update_itinerary',
  description:
    '旅程全体を置き換えて保存する。get_current_trip の結果を元に、既存の予定を残したうえで、ユーザーが採用した予定だけを入れる。itinerary[0] が1日目。何日目か未定の予定は unassigned_items に入れる。',
  parameters: itineraryInputSchema,
  execute: async (input, ctx) => {
    const s = scope(ctx)
    const result = await safe(() => replaceItinerary(s.userId, s.tripId, input))
    // 推測した place_id で失敗したとき、モデルが自力で立て直せるよう次の手を示す。
    if (!result.ok && result.error.code === 'NOT_FOUND')
      return {
        ...result,
        hint: 'place_id が存在しません。place_id を推測で作らず、list_suggested_places または list_saved_places で id を確認してください。該当する場所がなければ place_id を null にして title だけで登録できます。',
      }
    return result
  },
})

export const travelTools = [
  getCurrentTrip,
  listPastTrips,
  listSavedPlacesTool,
  listSuggestedPlacesTool,
  updateTripPreferences,
  updateItinerary,
]
