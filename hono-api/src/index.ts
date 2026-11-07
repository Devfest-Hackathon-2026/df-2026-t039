import { serve } from '@hono/node-server'
import { createApp } from './app.js'
import { firebaseAuth } from './firebase.js'
import { withDevAuth } from './lib/dev-auth.js'

const app = createApp(withDevAuth((token) => firebaseAuth.verifyIdToken(token)))

console.log(
  JSON.stringify({
    event: 'runtime_start',
    nodeVersion: process.version,
  }),
)

serve({
  fetch: app.fetch,
  hostname: '0.0.0.0',
  port: Number(process.env.PORT ?? 8080),
})
