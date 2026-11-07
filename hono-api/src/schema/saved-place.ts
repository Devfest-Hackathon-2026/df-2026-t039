import { z } from 'zod'
import { idSchema } from '../lib/api.js'
export const savePlaceSchema = z.object({ place_id: idSchema }).strict()
