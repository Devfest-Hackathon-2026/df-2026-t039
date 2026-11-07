import { z } from 'zod'
import { idSchema } from '../lib/api.js'

export const createPlaceSchema = z
  .object({
    name: z.string().trim().min(1).max(300),
    location: z.string().trim().max(1000).nullable().optional(),
    google_place_id: z.string().trim().min(1).max(300).nullable().optional(),
    latitude: z.number().min(-90).max(90).nullable().optional(),
    longitude: z.number().min(-180).max(180).nullable().optional(),
  })
  .strict()
export const placeSchema = z.object({
  id: idSchema,
  name: z.string(),
  location: z.string(),
  category: z.string(),
  google_place_id: z.string().nullable(),
  latitude: z.number().nullable(),
  longitude: z.number().nullable(),
  is_saved: z.boolean(),
})
export type Place = z.infer<typeof placeSchema>
export type CreatePlace = z.infer<typeof createPlaceSchema>
