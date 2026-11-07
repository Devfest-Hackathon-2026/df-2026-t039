import { ApiError, notFound } from '../lib/api.js'
import { transaction } from '../lib/transaction.js'
import type { ItineraryInput } from '../schema/trip-item.js'
import { getTrip, ownedTrip } from './trip-service.js'

const dbType = {
  movement: 'transport',
  place_food: 'meal',
  place_accommodation: 'accommodation',
  place_entertainment: 'sightseeing',
}
// 全置換を1トランザクションで保存する。APIと将来のAgentツールで共有する。
export async function replaceItinerary(
  userId: string,
  tripId: string,
  input: ItineraryInput,
) {
  return transaction(async (db) => {
    const trip = await ownedTrip(db, userId, tripId, true)
    if (trip.duration_days !== null && input.itinerary.length > trip.duration_days)
      throw new ApiError(400, 'ITINERARY_OUT_OF_RANGE', '旅程が予定日数を超えています')
    const entries = [
      ...input.itinerary.flatMap((day, index) =>
        day.map((item) => ({ day: index + 1, item })),
      ),
      ...input.unassigned_items.map((item) => ({ day: null, item })),
    ]
    const ids = [
      ...new Set(entries.flatMap(({ item }) => (item.place_id ? [item.place_id] : []))),
    ]
    if (ids.length) {
      const { rows } = await db.query(
        'SELECT id FROM places WHERE user_id=$1 AND id=ANY($2::bigint[])',
        [userId, ids],
      )
      if (rows.length !== ids.length) notFound()
    }
    await db.query('DELETE FROM trip_items WHERE trip_id=$1', [tripId])
    for (const [index, { day, item }] of entries.entries()) {
      await db.query(
        `INSERT INTO trip_items(trip_id,type,sort_order,place_id,day_number,title,start_time,end_time,
        end_day_offset,estimated_cost_per_person,transport_mode,estimated_travel_minutes,notes)
        VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
        [
          tripId,
          dbType[item.type],
          index + 1,
          item.place_id,
          day,
          item.title,
          item.from,
          item.to,
          item.end_day_offset,
          item.price,
          item.movement_type === 'walk' ? 'walking' : item.movement_type,
          item.estimated_travel_minutes,
          item.notes,
        ],
      )
    }
    await db.query('UPDATE trips SET updated_at=now() WHERE id=$1', [tripId])
    return getTrip(userId, tripId, db)
  })
}
