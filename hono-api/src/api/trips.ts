import { Hono } from 'hono'
import type { ApiEnv } from '../lib/api.js'
import { body, idSchema, validate } from '../lib/api.js'
import { createTripSchema, updateTripSchema, tripStatusSchema } from '../schema/trip.js'
import { itineraryInputSchema } from '../schema/trip-item.js'
import {
  createTrip,
  deleteTrip,
  getTrip,
  getUpcomingTrip,
  listTrips,
  updateTrip,
} from '../service/trip-service.js'
import { replaceItinerary } from '../service/trip-item-service.js'
import { paginationSchema } from '../schema/pagination.js'

const trips = new Hono<ApiEnv>()

trips.get('/', async (c) => {
  const q = validate(
    paginationSchema.extend({ status: tripStatusSchema.optional() }),
    c.req.query(),
  )
  return c.json({ trips: await listTrips(c.var.userId, q.status, q.limit, q.offset) })
})
trips.get('/upcoming', async (c) => c.json({ trip: await getUpcomingTrip(c.var.userId) }))
trips.post('/', async (c) =>
  c.json({ trip: await createTrip(c.var.userId, await body(c, createTripSchema)) }, 201),
)
trips.get('/:id', async (c) =>
  c.json({ trip: await getTrip(c.var.userId, validate(idSchema, c.req.param('id'))) }),
)
trips.patch('/:id', async (c) =>
  c.json({
    trip: await updateTrip(
      c.var.userId,
      validate(idSchema, c.req.param('id')),
      await body(c, updateTripSchema),
    ),
  }),
)
trips.put('/:id/itinerary', async (c) =>
  c.json({
    trip: await replaceItinerary(
      c.var.userId,
      validate(idSchema, c.req.param('id')),
      await body(c, itineraryInputSchema),
    ),
  }),
)
trips.delete('/:id', async (c) => {
  await deleteTrip(c.var.userId, validate(idSchema, c.req.param('id')))
  return c.body(null, 204)
})
export default trips
