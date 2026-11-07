import { pool } from '../db.js'
import { placeSchema } from '../schema/place.js'
import type { Place } from '../schema/place.js'
import { placeColumns } from './place-service.js'
import { ownedTrip } from './trip-service.js'

// Agent が提案した場所を記録する。呼び出し側で旅行の所有者確認を済ませておくこと。
export async function recordSuggestions(
  userId: string,
  tripId: string,
  placeIds: string[],
) {
  if (!placeIds.length) return
  await pool.query(
    `INSERT INTO trip_suggested_places(user_id,trip_id,place_id)
    SELECT $1,$2,unnest($3::bigint[])
    ON CONFLICT (trip_id,place_id) DO UPDATE SET suggested_at=now()`,
    [userId, tripId, placeIds],
  )
}

export async function listSuggestedPlaces(
  userId: string,
  tripId: string,
  limit = 30,
): Promise<Place[]> {
  await ownedTrip(pool, userId, tripId)
  const { rows } = await pool.query(
    `SELECT ${placeColumns} FROM trip_suggested_places t
    JOIN places p ON p.id=t.place_id AND p.user_id=t.user_id
    WHERE t.user_id=$1 AND t.trip_id=$2 ORDER BY t.suggested_at DESC, p.id DESC LIMIT $3`,
    [userId, tripId, limit],
  )
  return rows.map((row) => placeSchema.parse(row))
}
