import { z } from 'zod'
import { idSchema } from '../lib/api.js'
import { tripItemSchema } from './trip-item.js'

export const tripStatusSchema = z.enum(['draft', 'planned', 'completed'])
const fields = {
  title: z.string().trim().min(1).max(300).nullable().optional(),
  destination: z.string().trim().min(1).max(300).nullable().optional(),
  start_date: z.iso.date().nullable().optional(),
  end_date: z.iso.date().nullable().optional(),
  duration_days: z.number().int().min(1).max(366).nullable().optional(),
  participant_count: z.number().int().min(1).max(2147483647).nullable().optional(),
  budget: z.number().int().min(0).max(Number.MAX_SAFE_INTEGER).nullable().optional(),
  preferences: z.array(z.string().trim().min(1).max(500)).max(30).optional(),
}
export const createTripSchema = z.object(fields).strict()
export const updateTripSchema = z
  .object({ ...fields, status: tripStatusSchema.optional() })
  .strict()
  .refine((v) => Object.keys(v).length > 0, '更新項目を指定してください')
export const tripSchema = z.object({
  id: idSchema,
  title: z.string().nullable(),
  destination: z.string(),
  start_date: z.iso.date().nullable(),
  end_date: z.iso.date().nullable(),
  duration_days: z.number().int().nullable(),
  participant_count: z.number().int().nullable(),
  budget: z.number().int().min(0).max(Number.MAX_SAFE_INTEGER).nullable(),
  preferences: z.array(z.string()),
  status: tripStatusSchema,
  itinerary: z.array(z.array(tripItemSchema)),
  unassigned_items: z.array(tripItemSchema),
})
export type Trip = z.infer<typeof tripSchema>
export type TripInput = z.infer<typeof createTripSchema> & {
  status?: z.infer<typeof tripStatusSchema>
}
