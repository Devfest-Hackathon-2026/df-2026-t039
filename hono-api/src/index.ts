import { serve } from '@hono/node-server'
import { Hono } from 'hono'

const app = new Hono()

app.get('/', (c) => c.json({ message: 'Hello Hono!' }))
app.get('/health', (c) => c.json({ ok: true }))


// cloud runで実際に動いたNode.jsのバージョンを確認する
console.log(JSON.stringify({ event: 'runtime_start', nodeVersion: process.version }))

serve({
  fetch: app.fetch,
  hostname: '0.0.0.0',
  port: Number(process.env.PORT ?? 8080),
})
