import { z } from 'zod'
import { placeSchema } from './place.js'
import { tripSchema } from './trip.js'

export const sendMessageSchema = z
  .object({
    // クライアント生成の一意ID。同じIDの再送では前回の結果を返す。
    client_message_id: z.uuid(),
    text: z.string().trim().min(1).max(2000),
  })
  .strict()

export const chatMessageSchema = z.object({
  id: z.string(),
  role: z.enum(['user', 'assistant']),
  text: z.string(),
})

// Maps グラウンディング由来の候補。出典表示のため Maps のリンクを付ける。
export const suggestedPlaceSchema = placeSchema.extend({
  maps_url: z.string().nullable(),
})

export const sendMessageResponseSchema = z.object({
  message: chatMessageSchema,
  trip: tripSchema,
  suggested_places: z.array(suggestedPlaceSchema),
})

export type SendMessageInput = z.infer<typeof sendMessageSchema>
export type ChatMessage = z.infer<typeof chatMessageSchema>
export type SuggestedPlace = z.infer<typeof suggestedPlaceSchema>
export type SendMessageResponse = z.infer<typeof sendMessageResponseSchema>
