import { Hono } from 'hono'
import type { ApiEnv } from '../lib/api.js'
import { body, validate } from '../lib/api.js'
import { createPlaceSchema } from '../schema/place.js'
import { createPlace } from '../service/place-service.js'

import { textSearchSchema, nearbySearchSchema } from '../schema/place-search.js'
import { textSearch, nearbySearch } from '../service/place-search-service.js'

const places = new Hono<ApiEnv>()

places.get('/search', async (c) =>
  c.json(await textSearch(c.var.userId, validate(textSearchSchema, c.req.query()))),
)
places.get('/nearby', async (c) =>
  c.json(await nearbySearch(c.var.userId, validate(nearbySearchSchema, c.req.query()))),
)
places.post('/', async (c) =>
  c.json(
    { place: await createPlace(c.var.userId, await body(c, createPlaceSchema)) },
    201,
  ),
)
export default places
