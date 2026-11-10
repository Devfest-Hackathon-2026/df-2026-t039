import type { PoolClient } from 'pg'
import { pool } from '../db.js'
import { notFound } from '../lib/api.js'
import { placeSchema } from '../schema/place.js'
import type { CreatePlace, Place } from '../schema/place.js'

type Db = Pick<PoolClient, 'query'>
export const placeColumns = `p.id::text, p.name, COALESCE(p.address, '') AS location,
  ''::text AS category, p.google_place_id, p.latitude::float8, p.longitude::float8,
  EXISTS (SELECT 1 FROM saved_places s WHERE s.user_id=p.user_id AND s.place_id=p.id) AS is_saved`
export async function getPlace(
  userId: string,
  id: string,
  db: Db = pool,
): Promise<Place> {
  const { rows } = await db.query(
    `SELECT ${placeColumns} FROM places p WHERE p.user_id=$1 AND p.id=$2`,
    [userId, id],
  )
  if (!rows[0]) notFound()
  return placeSchema.parse(rows[0])
}
export async function createPlace(userId: string, input: CreatePlace): Promise<Place> {
  const { rows } = await pool.query(
    `INSERT INTO places(user_id,name,address,google_place_id,latitude,longitude)
    VALUES($1,$2,$3,$4,$5,$6)
    ON CONFLICT (user_id,google_place_id) DO UPDATE SET name=EXCLUDED.name,
    address=COALESCE(EXCLUDED.address,places.address),
    latitude=COALESCE(EXCLUDED.latitude,places.latitude), longitude=COALESCE(EXCLUDED.longitude,places.longitude)
    RETURNING id::text`,
    [
      userId,
      input.name,
      input.location ?? null,
      input.google_place_id ?? null,
      input.latitude ?? null,
      input.longitude ?? null,
    ],
  )
  return getPlace(userId, rows[0].id)
}
