import { Hono } from 'hono'
import type { ApiEnv } from '../lib/api.js'
import { body, idSchema, validate } from '../lib/api.js'
import { sendMessageSchema } from '../schema/agent.js'
import { listMessages, sendMessage } from '../service/agent-service.js'

// /api/trips/:id/messages。旅行1件につき会話セッション1件。
const messages = new Hono<ApiEnv>()

messages.get('/:id/messages', async (c) =>
  c.json({
    messages: await listMessages(c.var.userId, validate(idSchema, c.req.param('id'))),
  }),
)
messages.post('/:id/messages', async (c) =>
  c.json(
    await sendMessage(
      c.var.userId,
      validate(idSchema, c.req.param('id')),
      await body(c, sendMessageSchema),
    ),
  ),
)
export default messages
