import { SkillToolset } from '@google/adk'
import type { ReadonlyContext } from '@google/adk'

// 標準の Skill ツール（list_skills / load_skill / load_skill_resource）を使う。
// code executor を用意していないため、スクリプト実行ツールだけ外す。
export class TravelSkillToolset extends SkillToolset {
  override async getTools(ctx?: ReadonlyContext) {
    return (await super.getTools(ctx)).filter((tool) => tool.name !== 'run_skill_script')
  }
}
