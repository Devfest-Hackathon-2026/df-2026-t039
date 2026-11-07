import { z } from 'zod'
import { placeSchema } from './place.js'

const numberQuery = z.string().trim().min(1).pipe(z.coerce.number())
export const textSearchSchema = z
  .object({
    q: z.string().trim().min(1).max(500),
    limit: numberQuery.pipe(z.number().int().min(1).max(20)).default(20),
    page_token: z.string().min(1).max(10000).optional(),
  })
  .strict()
export const nearbySearchSchema = z
  .object({
    latitude: numberQuery.pipe(z.number().min(-90).max(90)),
    longitude: numberQuery.pipe(z.number().min(-180).max(180)),
    radius: numberQuery.pipe(z.number().positive().max(50000)).default(1000),
    limit: numberQuery.pipe(z.number().int().min(1).max(20)).default(20),
    included_types: z
      .string()
      .regex(/^[a-z_]+(,[a-z_]+)*$/)
      .max(2000)
      .optional(),
    rank: z.enum(['DISTANCE', 'POPULARITY']).default('DISTANCE'),
  })
  .strict()
  .refine(
    (v) => !v.included_types || v.included_types.split(',').length <= 50,
    '種類は50件までです',
  )
export const searchPlaceSchema = placeSchema.extend({
  id: placeSchema.shape.id.nullable(),
  google_place_id: z.string().min(1),
  maps_url: z.string().nullable(),
  attributions: z.array(z.object({ provider: z.string(), provider_uri: z.string() })),
})
export type TextSearch = z.infer<typeof textSearchSchema>
export type NearbySearch = z.infer<typeof nearbySearchSchema>
