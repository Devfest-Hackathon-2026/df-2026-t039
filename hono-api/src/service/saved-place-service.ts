import { pool } from '../db.js'
import { notFound } from '../lib/api.js'
import { getPlace, placeColumns } from './place-service.js'
import { placeSchema } from '../schema/place.js'

export async function listSavedPlaces(userId: string, limit: number, offset: number) {
  const { rows } = await pool.query(
    `SELECT ${placeColumns} FROM saved_places s
    JOIN places p ON p.id=s.place_id AND p.user_id=s.user_id
    WHERE s.user_id=$1 ORDER BY s.created_at DESC, p.id DESC LIMIT $2 OFFSET $3`,
    [userId, limit, offset],
  )
  return rows.map((row) => placeSchema.parse(row))
}
export async function savePlace(userId: string, placeId: string) {
  await getPlace(userId, placeId)
  await pool.query(
    `INSERT INTO saved_places(user_id,place_id) VALUES($1,$2) ON CONFLICT DO NOTHING`,
    [userId, placeId],
  )
  return getPlace(userId, placeId)
}
export async function unsavePlace(userId: string, placeId: string) {
  const { rows } = await pool.query('SELECT id FROM places WHERE user_id=$1 AND id=$2', [
    userId,
    placeId,
  ])
  if (!rows[0]) notFound()
  await pool.query('DELETE FROM saved_places WHERE user_id=$1 AND place_id=$2', [
    userId,
    placeId,
  ])
}
