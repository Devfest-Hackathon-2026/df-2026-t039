import { z } from 'zod'
import { idSchema } from '../lib/api.js'
import { placeSchema } from './place.js'

const time = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/)
export const itemTypeSchema = z.enum([
  'place_entertainment',
  'place_food',
  'place_accommodation',
  'movement',
])
export const movementSchema = z.enum([
  'walk',
  'train',
  'bus',
  'car',
  'taxi',
  'airplane',
  'boat',
  'other',
])
export const tripItemInputSchema = z
  .object({
    type: itemTypeSchema,
    title: z.string().trim().min(1).max(300).nullable().default(null),
    place_id: idSchema.nullable().default(null),
    from: time.nullable().default(null),
    to: time.nullable().default(null),
    end_day_offset: z.number().int().min(0).max(366).default(0),
    price: z.number().int().min(0).max(Number.MAX_SAFE_INTEGER).nullable().default(null),
    movement_type: movementSchema.nullable().default(null),
    estimated_travel_minutes: z
      .number()
      .int()
      .min(0)
      .max(2147483647)
      .nullable()
      .default(null),
    notes: z.string().max(5000).nullable().default(null),
  })
  .strict()
  .superRefine((item, ctx) => {
    if (item.from && item.to && item.end_day_offset === 0 && item.to < item.from)
      ctx.addIssue({ code: 'custom', message: '終了時刻は開始時刻以降にしてください' })
    if (
      item.type !== 'movement' &&
      (item.movement_type !== null || item.estimated_travel_minutes !== null)
    )
      ctx.addIssue({
        code: 'custom',
        message: '移動以外に移動手段・移動時間は指定できません',
      })
  })
export const itineraryInputSchema = z
  .object({
    itinerary: z.array(z.array(tripItemInputSchema).max(300)).max(366),
    unassigned_items: z.array(tripItemInputSchema).max(300).default([]),
  })
  .strict()
  .refine(
    (v) =>
      v.itinerary.reduce((n, day) => n + day.length, v.unassigned_items.length) <= 300,
    '予定は合計300件までです',
  )
export const tripItemSchema = z.object({
  id: idSchema,
  type: itemTypeSchema,
  title: z.string().nullable(),
  from: time.nullable(),
  to: time.nullable(),
  end_day_offset: z.number().int().nonnegative(),
  price: z.number().int().min(0).max(Number.MAX_SAFE_INTEGER).nullable(),
  movement_type: movementSchema.nullable(),
  estimated_travel_minutes: z.number().int().nullable(),
  notes: z.string().nullable(),
  place: placeSchema.nullable(),
})
export type ItineraryInput = z.infer<typeof itineraryInputSchema>
export type TripItem = z.infer<typeof tripItemSchema>
