import pg from 'pg'

export const pool = new pg.Pool({
  host: '127.0.0.1',
  port: 5432,
  database: process.env.POSTGRES_DB,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  max: 5,
  connectionTimeoutMillis: 5000,
})

pool.on('error', (error) => {
  console.error('DB接続エラー:', error.message)
})