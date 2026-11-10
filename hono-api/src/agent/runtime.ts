import { DatabaseSessionService, InMemorySessionService, Runner } from '@google/adk'
import type { BaseSessionService } from '@google/adk'
import { createTravelAgent } from './travel-agent.js'

export const APP_NAME = 'travel_agent'
export const sessionIdOf = (tripId: string) => `trip-${tripId}`

let sessionService: BaseSessionService | undefined
let runnerPromise: Promise<Runner> | undefined

// ADK_DATABASE_URL があれば PostgreSQL に会話を保存する。未設定時は開発用のメモリ保存（再起動で消える）。
export async function getSessionService(): Promise<BaseSessionService> {
  if (!sessionService) {
    const url = process.env.ADK_DATABASE_URL
    if (url) {
      const service = new DatabaseSessionService(url)
      await service.init()
      sessionService = service
    } else {
      console.warn(
        'ADK_DATABASE_URL が未設定のため、会話はメモリに保存されます（再起動で消えます）',
      )
      sessionService = new InMemorySessionService()
    }
  }
  return sessionService
}

export function getRunner(): Promise<Runner> {
  runnerPromise ??= (async () =>
    new Runner({
      appName: APP_NAME,
      agent: await createTravelAgent(),
      sessionService: await getSessionService(),
      // sessionId は所有者確認済みの旅行IDから作るため、初回に自動作成してよい。
      autoCreateSession: true,
    }))().catch((error) => {
    runnerPromise = undefined // 初期化失敗時は次のリクエストで再試行する
    throw error
  })
  return runnerPromise
}
