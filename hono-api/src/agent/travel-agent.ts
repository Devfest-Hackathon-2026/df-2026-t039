import { fileURLToPath } from 'node:url'
import { GOOGLE_MAPS_GROUNDING, LlmAgent, loadAllSkillsInDir } from '@google/adk'
import { ThinkingLevel } from '@google/genai'
import { TravelSkillToolset } from './skill-toolset.js'
import { travelTools } from './tools.js'

export const AGENT_NAME = 'travel_agent'
export const DEFAULT_MODEL = 'gemini-3.8-flash'
// src/agent と dist/agent のどちらから実行しても hono-api/skills を指す。
const SKILLS_DIR = fileURLToPath(new URL('../../skills', import.meta.url))

const BASE_INSTRUCTION = `あなたはユーザーと一緒に旅行プランを作るアシスタントです。日本語で話します。

## 対象範囲（日本国内の旅行のみ）
- 扱うのは日本国内の旅行だけ。行き先・提案する場所・旅程の予定は、すべて日本国内にする。
- 海外の行き先を希望されたら、国内旅行のみ対応していることを伝え、希望の雰囲気に近い国内の行き先を2〜3件挙げて選んでもらう。
- 海外の行き先や海外の場所は、update_trip_preferences・update_itinerary で保存しない。
- 日時はすべて日本時間で扱う。

## 進め方
- 会話をリードし、質問は一度に1〜2個までにする。
- 新しい旅行の相談では create-trip-plan、既存プランの具体化・変更では refine-trip-plan の Skill を load_skill で読んでから進める。
- 決定済みの内容は get_current_trip で確認し、同じことを何度も聞かない。

## 場所の提案
- 場所を提案するときは Google Maps の情報に基づき、実在を確認できない場所を挙げない。
- 提案しただけの場所と、ユーザーが採用した予定を区別する。提案だけでは旅程に入れない。
- ユーザーが採用したら list_suggested_places または list_saved_places で id を確認し、place_id として update_itinerary に渡す。
- 過去に訪れた場所を「好きな場所」と決めつけない。

## 保存
- 不明な値は未定のままにし、画面を埋めるために事実を作らない。
- 保存ツールが ok:true を返してから「更新しました」と伝える。ok:false のときは hint に従って立て直し、それでも保存できなければ、保存できなかったことを正直に伝える。
- 保存できなかった内容を「メモした」「記録した」などと言わない。保存先はツールだけで、それ以外に記録する手段はない。
- 用意されたツール以外は呼ばない。
- プランの確定（予定済みにする操作）はユーザーが画面で行う。`

function todayInTokyo() {
  return new Intl.DateTimeFormat('sv-SE', { timeZone: 'Asia/Tokyo' }).format(new Date())
}

export async function createTravelAgent() {
  const skills = await loadAllSkillsInDir(SKILLS_DIR)
  return new LlmAgent({
    name: AGENT_NAME,
    description: '旅行プランの作成と変更を手伝う Agent',
    model: process.env.GEMINI_MODEL || DEFAULT_MODEL,
    // 日付の相対表現（来週末など）を解釈できるよう、日本時間の今日を渡す。
    instruction: () => `${BASE_INSTRUCTION}\n\n今日の日付（日本時間）: ${todayInTokyo()}`,
    // Maps グラウンディングの場所名を日本語で受け取る（未指定だと英語名になることがある）。
    generateContentConfig: {
      toolConfig: { retrievalConfig: { languageCode: 'ja' } },
      // 比較評価で精度を保ったまま応答時間・費用が約半分になったため low にする（既定は medium）。
      thinkingConfig: { thinkingLevel: ThinkingLevel.LOW },
    },
    tools: [GOOGLE_MAPS_GROUNDING, ...travelTools, new TravelSkillToolset(skills)],
  })
}
