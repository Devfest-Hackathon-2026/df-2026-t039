import { Hono } from 'hono'
import type { ApiEnv } from '../lib/api.js'
import { body, idSchema, validate } from '../lib/api.js'
import { savePlaceSchema } from '../schema/saved-place.js'
import { paginationSchema } from '../schema/pagination.js'
import {
  listSavedPlaces,
  savePlace,
  unsavePlace,
} from '../service/saved-place-service.js'

const savedPlaces = new Hono<ApiEnv>()

savedPlaces.get('/', async (c) => {
  const q = validate(paginationSchema, c.req.query())
  return c.json({ places: await listSavedPlaces(c.var.userId, q.limit, q.offset) })
})
savedPlaces.post('/', async (c) => {
  const data = await body(c, savePlaceSchema)
  return c.json({ place: await savePlace(c.var.userId, data.place_id) })
})
savedPlaces.delete('/:id', async (c) => {
  await unsavePlace(c.var.userId, validate(idSchema, c.req.param('id')))
  return c.body(null, 204)
})
export default savedPlaces
