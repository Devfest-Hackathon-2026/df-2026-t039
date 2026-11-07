import type { PoolClient } from 'pg'
import { pool } from '../db.js'
import { ApiError, notFound } from '../lib/api.js'
import { transaction } from '../lib/transaction.js'
import { tripSchema } from '../schema/trip.js'
import type { Trip, TripInput } from '../schema/trip.js'
import { tripItemSchema } from '../schema/trip-item.js'
import type { TripItem } from '../schema/trip-item.js'

type Db = Pick<PoolClient, 'query'>
const tripColumns = `id::text, name AS title, destination,
  to_char(start_date,'YYYY-MM-DD') AS start_date, to_char(end_date,'YYYY-MM-DD') AS end_date,
  duration_days, participant_count, budget_per_person_jpy::text AS budget, preferences, status`

export async function ownedTrip(db: Db, userId: string, id: string, lock = false) {
  const { rows } = await db.query(
    `SELECT ${tripColumns} FROM trips WHERE user_id=$1 AND id=$2${lock ? ' FOR UPDATE' : ''}`,
    [userId, id],
  )
  if (!rows[0]) notFound()
  return rows[0]
}

export async function getTrip(userId: string, id: string, db: Db = pool): Promise<Trip> {
  const row = await ownedTrip(db, userId, id)
  const { rows } = await db.query(
    `SELECT i.id::text, i.day_number, i.title,
    CASE i.type WHEN 'transport' THEN 'movement' WHEN 'meal' THEN 'place_food'
      WHEN 'accommodation' THEN 'place_accommodation' ELSE 'place_entertainment' END AS type,
    to_char(i.start_time,'HH24:MI') AS "from", to_char(i.end_time,'HH24:MI') AS "to",
    i.end_day_offset, i.estimated_cost_per_person::text AS price,
    CASE WHEN i.transport_mode='walking' THEN 'walk' ELSE i.transport_mode END AS movement_type,
    i.estimated_travel_minutes, i.notes,
    CASE WHEN p.id IS NULL THEN NULL ELSE json_build_object(
      'id',p.id::text,'name',p.name,'location',COALESCE(p.address,''),'category','',
      'google_place_id',p.google_place_id,'latitude',p.latitude::float8,'longitude',p.longitude::float8,
      'is_saved',EXISTS(SELECT 1 FROM saved_places s WHERE s.user_id=$2 AND s.place_id=p.id)) END AS place
    FROM trip_items i LEFT JOIN places p ON p.id=i.place_id AND p.user_id=$2
    WHERE i.trip_id=$1 ORDER BY i.sort_order, i.id`,
    [id, userId],
  )
  const days = Math.max(row.duration_days ?? 0, ...rows.map((i) => i.day_number ?? 0))
  if (days > 366) throw new Error('旅程の日数がAPI上限を超えています')
  const itinerary: TripItem[][] = Array.from({ length: days }, () => [])
  const unassigned: TripItem[] = []
  for (const item of rows) {
    const parsed = tripItemSchema.parse({
      ...item,
      price: item.price === null ? null : Number(item.price),
    })
    if (item.day_number === null) unassigned.push(parsed)
    else itinerary[item.day_number - 1].push(parsed)
  }
  return tripSchema.parse({
    ...row,
    destination: row.destination ?? '行き先未定',
    budget: row.budget === null ? null : Number(row.budget),
    itinerary,
    unassigned_items: unassigned,
  })
}

export async function getUpcomingTrip(userId: string): Promise<Trip | null> {
  const { rows } = await pool.query(
    `SELECT id::text FROM trips WHERE user_id=$1
    AND status <> 'completed' AND start_date >= (now() AT TIME ZONE 'Asia/Tokyo')::date
    ORDER BY start_date,id LIMIT 1`,
    [userId],
  )
  return rows[0] ? getTrip(userId, rows[0].id) : null
}

export async function listTrips(
  userId: string,
  status: string | undefined,
  limit: number,
  offset: number,
): Promise<Trip[]> {
  const { rows } = await pool.query(
    `SELECT id::text FROM trips WHERE user_id=$1
    AND ($2::text IS NULL OR status=$2) ORDER BY start_date DESC NULLS FIRST,id DESC LIMIT $3 OFFSET $4`,
    [userId, status ?? null, limit, offset],
  )
  const trips: Trip[] = []
  for (const row of rows) trips.push(await getTrip(userId, row.id))
  return trips
}

function normalize(input: TripInput) {
  const value = {
    title: null,
    destination: null,
    start_date: null,
    end_date: null,
    duration_days: null,
    participant_count: null,
    budget: null,
    preferences: [] as string[],
    status: 'draft',
    ...input,
  }
  if (value.start_date && value.end_date) {
    const days =
      (Date.parse(value.end_date) - Date.parse(value.start_date)) / 86400000 + 1
    if (days < 1 || days > 366)
      throw new ApiError(400, 'INVALID_DATES', '旅行日数は1〜366日で指定してください')
    if (value.duration_days !== null && value.duration_days !== days)
      throw new ApiError(400, 'INVALID_DURATION', '日程と予定日数が一致しません')
    value.duration_days = days
  }
  return value
}

export async function createTrip(userId: string, input: TripInput) {
  const v = normalize(input)
  const { rows } = await pool.query(
    `INSERT INTO trips(user_id,name,destination,start_date,end_date,duration_days,
    participant_count,budget_per_person_jpy,preferences) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id::text`,
    [
      userId,
      v.title,
      v.destination,
      v.start_date,
      v.end_date,
      v.duration_days,
      v.participant_count,
      v.budget,
      v.preferences,
    ],
  )
  return getTrip(userId, rows[0].id)
}

export async function updateTrip(userId: string, id: string, input: TripInput) {
  return transaction(async (db) => {
    const current = await ownedTrip(db, userId, id, true)
    // 日付変更時、日数の明示指定がなければ新日程から再計算する。
    const recompute =
      (input.start_date !== undefined || input.end_date !== undefined) &&
      input.duration_days === undefined
    const v = normalize({
      ...current,
      budget: current.budget === null ? null : Number(current.budget),
      ...input,
      ...(recompute ? { duration_days: null } : {}),
    })
    const { rows } = await db.query(
      'SELECT max(day_number) AS last_day FROM trip_items WHERE trip_id=$1',
      [id],
    )
    if (v.duration_days !== null && rows[0].last_day > v.duration_days)
      throw new ApiError(
        409,
        'ITINERARY_OUT_OF_RANGE',
        '先に予定日数を超える旅程を移動・削除してください',
      )
    await db.query(
      `UPDATE trips SET name=$3,destination=$4,start_date=$5,end_date=$6,duration_days=$7,
      participant_count=$8,budget_per_person_jpy=$9,preferences=$10,status=$11 WHERE user_id=$1 AND id=$2`,
      [
        userId,
        id,
        v.title,
        v.destination,
        v.start_date,
        v.end_date,
        v.duration_days,
        v.participant_count,
        v.budget,
        v.preferences,
        v.status,
      ],
    )
    return getTrip(userId, id, db)
  })
}

export async function deleteTrip(userId: string, id: string) {
  const result = await pool.query('DELETE FROM trips WHERE user_id=$1 AND id=$2', [
    userId,
    id,
  ])
  if (!result.rowCount) notFound()
}
