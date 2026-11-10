import { isFinalResponse } from '@google/adk'
import type { Event } from '@google/adk'
import { APP_NAME, getRunner, getSessionService, sessionIdOf } from '../agent/runtime.js'
import { TRIP_ID_STATE_KEY } from '../agent/tools.js'
import { AGENT_NAME } from '../agent/travel-agent.js'
import { pool } from '../db.js'
import { ApiError } from '../lib/api.js'
import { sendMessageResponseSchema } from '../schema/agent.js'
import type {
  ChatMessage,
  SendMessageInput,
  SendMessageResponse,
  SuggestedPlace,
} from '../schema/agent.js'
import { createPlace } from './place-service.js'
import { recordSuggestions } from './suggestion-service.js'
import { getTrip, ownedTrip } from './trip-service.js'

// 実行中のまま残ったリクエスト（プロセス停止など）を失敗扱いにするまでの時間。
const STALE_MINUTES = 5

function textOf(event: Event) {
  return (event.content?.parts ?? [])
    .filter((part) => part.text && !part.thought)
    .map((part) => part.text)
    .join('')
}

function isAgentReply(event: Event) {
  return event.author === AGENT_NAME && !event.partial && isFinalResponse(event)
}

// 同じIDの再送なら前回の結果を返す。同じ旅行で実行中のリクエストがあれば409。
async function claimRequest(
  userId: string,
  tripId: string,
  clientMessageId: string,
): Promise<SendMessageResponse | null> {
  await pool.query(
    `UPDATE agent_requests SET status='failed', updated_at=now()
    WHERE trip_id=$1 AND status='running' AND updated_at < now() - make_interval(mins => $2)`,
    [tripId, STALE_MINUTES],
  )
  try {
    const { rows } = await pool.query(
      `INSERT INTO agent_requests(user_id,client_message_id,trip_id,status)
      VALUES($1,$2,$3,'running')
      ON CONFLICT (user_id,client_message_id) DO UPDATE SET status='running', updated_at=now()
      WHERE agent_requests.status='failed' AND agent_requests.trip_id=EXCLUDED.trip_id
      RETURNING status`,
      [userId, clientMessageId, tripId],
    )
    if (rows[0]) return null
  } catch (error) {
    if ((error as { code?: string }).code === '23505')
      throw new ApiError(
        409,
        'TRIP_BUSY',
        'この旅行の返答を作成中です。完了してから送信してください',
      )
    throw error
  }
  const { rows } = await pool.query(
    `SELECT trip_id::text, status, response FROM agent_requests
    WHERE user_id=$1 AND client_message_id=$2`,
    [userId, clientMessageId],
  )
  const row = rows[0]
  if (row?.trip_id !== tripId)
    throw new ApiError(
      409,
      'DUPLICATE_MESSAGE_ID',
      'client_message_id が別の旅行で使用されています',
    )
  if (row.status === 'done') return sendMessageResponseSchema.parse(row.response)
  throw new ApiError(409, 'REQUEST_IN_PROGRESS', 'このメッセージは処理中です')
}

async function finishRequest(
  userId: string,
  clientMessageId: string,
  response: SendMessageResponse | null,
) {
  await pool.query(
    `UPDATE agent_requests SET status=$3, response=$4, updated_at=now()
    WHERE user_id=$1 AND client_message_id=$2`,
    [
      userId,
      clientMessageId,
      response ? 'done' : 'failed',
      response ? JSON.stringify(response) : null,
    ],
  )
}

// Vertex AI のグラウンディングは「店名 - Google Maps」や口コミ由来の「Review of 店名」の形で返すことがある。
function placeNameOf(title: string) {
  const name = title
    .replace(/^Review of\s+/i, '')
    .replace(/\s*-\s*Google\s*Maps\s*$/i, '')
    .trim()
  return name || title
}

// Maps グラウンディングの結果だけを候補場所にする。モデルの文章中の店名は候補カードにしない。
async function saveGroundedPlaces(
  userId: string,
  tripId: string,
  grounded: Map<string, { title: string; uri: string | null }>,
) {
  const places: SuggestedPlace[] = []
  for (const [googlePlaceId, { title, uri }] of grounded) {
    const place = await createPlace(userId, {
      name: title.slice(0, 300),
      google_place_id: googlePlaceId,
    })
    places.push({ ...place, maps_url: uri })
  }
  await recordSuggestions(
    userId,
    tripId,
    places.map((place) => place.id),
  )
  return places
}

export async function sendMessage(
  userId: string,
  tripId: string,
  input: SendMessageInput,
): Promise<SendMessageResponse> {
  await ownedTrip(pool, userId, tripId)
  const previous = await claimRequest(userId, tripId, input.client_message_id)
  if (previous) return previous

  try {
    const runner = await getRunner()
    let replyId = `${input.client_message_id}:reply`
    let replyText = ''
    const grounded = new Map<string, { title: string; uri: string | null }>()

    for await (const event of runner.runAsync({
      userId,
      sessionId: sessionIdOf(tripId),
      newMessage: { role: 'user', parts: [{ text: input.text }] },
      // ツールはこの値から対象の旅行を特定する。
      stateDelta: { [TRIP_ID_STATE_KEY]: tripId },
    })) {
      if (event.errorCode)
        throw new Error(
          `Agent の実行に失敗しました: ${event.errorCode} ${event.errorMessage ?? ''}`,
        )
      for (const chunk of event.groundingMetadata?.groundingChunks ?? []) {
        const maps = chunk.maps
        const placeId = maps?.placeId?.replace(/^places\//, '')
        // 同じ場所が口コミとして重ねて返ることがあるため、最初に出た名前・リンクを使う。
        if (placeId && maps?.title && !grounded.has(placeId))
          grounded.set(placeId, { title: placeNameOf(maps.title), uri: maps.uri ?? null })
      }
      if (isAgentReply(event)) {
        const text = textOf(event)
        if (text) {
          replyText += text
          replyId = event.id
        }
      }
    }

    const response: SendMessageResponse = {
      message: {
        id: replyId,
        role: 'assistant',
        text: replyText || 'うまく返答を作成できませんでした。もう一度送信してください。',
      },
      trip: await getTrip(userId, tripId),
      suggested_places: await saveGroundedPlaces(userId, tripId, grounded),
    }
    await finishRequest(userId, input.client_message_id, response)
    return response
  } catch (error) {
    await finishRequest(userId, input.client_message_id, null)
    throw error
  }
}

// 画面表示用の会話履歴は ADK のセッションイベントから組み立てる（独自メッセージテーブルと二重管理しない）。
export async function listMessages(
  userId: string,
  tripId: string,
): Promise<ChatMessage[]> {
  await ownedTrip(pool, userId, tripId)
  const sessionService = await getSessionService()
  const session = await sessionService.getSession({
    appName: APP_NAME,
    userId,
    sessionId: sessionIdOf(tripId),
  })
  const messages: ChatMessage[] = []
  for (const event of session?.events ?? []) {
    const role =
      event.author === 'user' ? 'user' : isAgentReply(event) ? 'assistant' : null
    const text = role ? textOf(event) : ''
    if (role && text) messages.push({ id: event.id, role, text })
  }
  return messages
}
