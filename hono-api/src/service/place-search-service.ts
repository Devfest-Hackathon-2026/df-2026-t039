import { z } from 'zod'
import { pool } from '../db.js'
import { ApiError } from '../lib/api.js'
import { searchPlaceSchema } from '../schema/place-search.js'
import type { TextSearch, NearbySearch } from '../schema/place-search.js'

const googleResponseSchema = z.object({
  places: z
    .array(
      z.object({
        id: z.string().min(1),
        displayName: z.object({ text: z.string() }).optional(),
        formattedAddress: z.string().optional(),
        location: z.object({ latitude: z.number(), longitude: z.number() }).optional(),
        primaryTypeDisplayName: z.object({ text: z.string() }).optional(),
        primaryType: z.string().optional(),
        googleMapsUri: z.string().optional(),
        attributions: z
          .array(
            z.object({
              provider: z.string().optional(),
              providerUri: z.string().optional(),
            }),
          )
          .optional(),
      }),
    )
    .default([]),
  nextPageToken: z.string().optional(),
})
const fields = [
  'id',
  'displayName',
  'formattedAddress',
  'location',
  'primaryType',
  'primaryTypeDisplayName',
  'googleMapsUri',
  'attributions',
].map((field) => `places.${field}`)

async function search(
  userId: string,
  method: 'searchText' | 'searchNearby',
  input: object,
) {
  const key = process.env.GOOGLE_PLACES_API_KEY
  if (!key)
    throw new ApiError(503, 'PLACES_NOT_CONFIGURED', '場所検索が設定されていません')
  let response: Response
  let data: unknown
  try {
    response = await fetch(`https://places.googleapis.com/v1/places:${method}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': [
          ...fields,
          ...(method === 'searchText' ? ['nextPageToken'] : []),
        ].join(','),
      },
      body: JSON.stringify({ ...input, languageCode: 'ja' }),
      signal: AbortSignal.timeout(10000),
    })
    if (response.ok) data = await response.json()
  } catch (error) {
    if (
      error instanceof Error &&
      (error.name === 'TimeoutError' || error.name === 'AbortError')
    )
      throw new ApiError(504, 'PLACES_TIMEOUT', '場所検索がタイムアウトしました')
    throw new ApiError(502, 'PLACES_UNAVAILABLE', '場所検索に接続できませんでした')
  }
  if (!response.ok) {
    if (response.status === 400)
      throw new ApiError(
        400,
        'INVALID_SEARCH',
        '検索条件・場所の種類・ページトークンを確認してください',
      )
    if (response.status === 429)
      throw new ApiError(
        503,
        'PLACES_RATE_LIMITED',
        '場所検索が混み合っています。時間をおいて再試行してください',
      )
    throw new ApiError(502, 'PLACES_UNAVAILABLE', '場所検索を利用できませんでした')
  }
  const parsed = googleResponseSchema.safeParse(data)
  if (!parsed.success)
    throw new ApiError(
      502,
      'INVALID_PLACES_RESPONSE',
      '場所検索の応答を処理できませんでした',
    )
  const ids = parsed.data.places.map((place) => place.id)
  const { rows } = await pool.query(
    `SELECT p.id::text, p.google_place_id,
    EXISTS(SELECT 1 FROM saved_places s WHERE s.user_id=$1 AND s.place_id=p.id) AS is_saved
    FROM places p WHERE p.user_id=$1 AND p.google_place_id=ANY($2::text[])`,
    [userId, ids],
  )
  const registered = new Map(rows.map((row) => [row.google_place_id, row]))
  return {
    places: parsed.data.places.map((place) => {
      const existing = registered.get(place.id)
      return searchPlaceSchema.parse({
        id: existing?.id ?? null,
        google_place_id: place.id,
        name: place.displayName?.text ?? '',
        location: place.formattedAddress ?? '',
        category: place.primaryTypeDisplayName?.text ?? place.primaryType ?? '',
        latitude: place.location?.latitude ?? null,
        longitude: place.location?.longitude ?? null,
        is_saved: existing?.is_saved ?? false,
        maps_url: place.googleMapsUri ?? null,
        attributions: (place.attributions ?? []).map((a) => ({
          provider: a.provider ?? '',
          provider_uri: a.providerUri ?? '',
        })),
      })
    }),
    next_page_token: parsed.data.nextPageToken ?? null,
  }
}
export function textSearch(userId: string, query: TextSearch) {
  return search(userId, 'searchText', {
    textQuery: query.q,
    pageSize: query.limit,
    ...(query.page_token ? { pageToken: query.page_token } : {}),
  })
}
export function nearbySearch(userId: string, query: NearbySearch) {
  return search(userId, 'searchNearby', {
    locationRestriction: {
      circle: {
        center: { latitude: query.latitude, longitude: query.longitude },
        radius: query.radius,
      },
    },
    maxResultCount: query.limit,
    rankPreference: query.rank,
    ...(query.included_types ? { includedTypes: query.included_types.split(',') } : {}),
  })
}
