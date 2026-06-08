---
name: skill-creator
description: Create, update, evaluate, and optimize AI agent skills in English or Chinese. Use when the user wants to create a new SKILL.md, convert a workflow into a skill, improve an existing skill, design evals, compare versions, optimize triggering descriptions, or apply a SkillOpt-style loop with rollout, reflection, edit ranking, rewrite, validation gate, and meta-skill memory. 中文场景：创建 Skill、优化 Skill、写双语 Skill、设计评估集、从失败案例改进技能文档、用 SkillOpt 方法迭代 Skill。
---

# Skill Creator / Skill 创建与优化

Use this skill to turn repeatable agent work into a reusable `SKILL.md`, then improve it with evidence from real runs. 使用这个 skill 时，把技能文档看作可以被训练和评估的产品资产，而不是一次性提示词。

## Purpose / 用途

- Create new skills from user workflows, tools, scripts, examples, documents, or agent habits.
- Improve existing skills with evaluations, qualitative feedback, and SkillOpt-style optimization.
- Produce bilingual Chinese/English skills when the audience or trigger language requires both.
- Keep `SKILL.md` compact, operational, and easy for an agent to follow.
- Use bundled `references/`, `scripts/`, and `assets/` only when they reduce context load or make work repeatable.

## Working Style / 工作方式

- Match the user's language in explanations. If the user writes Chinese, answer in Chinese; keep commands, file names, config keys, and code exact.
- Extract intent from the current conversation before asking questions. Ask only for missing details that would materially change the skill.
- Prefer clear user-facing words over jargon. If using terms such as eval, assertion, rollout, or gate, add a short explanation when the user may not know them.
- Never read or expose secrets such as `.env`, API keys, tokens, private credentials, or unrelated personal files.
- Preserve user changes in a dirty worktree. Snapshot or diff before editing an existing skill if regression risk matters.

## Modes / 模式

### 1. Create / 创建

Use when the user wants a new skill or wants to convert a workflow into a skill.

1. Capture intent: objective, trigger phrases, expected outputs, inputs, dependencies, target agents, safety boundaries, examples, and non-goals.
2. Design the skill directory:
   ```text
   skill-name/
   ├── SKILL.md
   ├── references/   # optional: longer docs loaded only when needed
   ├── scripts/      # optional: deterministic or repeated operations
   └── assets/       # optional: templates, examples, static files
   ```
3. Draft `SKILL.md` with required YAML frontmatter: `name` and `description`.
4. Put all trigger guidance in `description`; put execution guidance in the body.
5. Add resources only when they are directly useful. Do not add README or broad docs inside the skill unless the user asks.
6. Add 2-5 realistic eval prompts when the skill has testable behavior.
7. Validate the skill structure before delivery.

### 2. Improve / 优化

Use when the user already has a skill and wants it clearer, more reusable, more accurate, or better triggered.

1. Read the current `SKILL.md` and only the references needed for the requested change.
2. Identify observed failures, user feedback, unclear steps, missing edge cases, over-triggering, under-triggering, and brittle instructions.
3. If the skill is important or already deployed, snapshot the old version before editing.
4. Use the SkillOpt loop below to propose, rank, rewrite, and gate improvements.
5. Rewrite the full skill document coherently instead of piling patch fragments on top of old text.
6. Keep effective existing guidance unless evidence shows it should be removed or merged.

### 3. Evaluate / 评估

Use when the user wants to know whether a skill helps.

1. Build eval prompts that look like real user requests, not artificial unit-test riddles.
2. Compare at least two conditions when possible:
   - New skill vs no skill for first-time creation.
   - New skill vs old skill for improvements.
3. Draft objective assertions for file transforms, data extraction, code generation, command workflows, and other verifiable outcomes.
4. Keep subjective review for writing style, product taste, design quality, or tasks where human preference matters.
5. Record results in a sibling workspace such as `<skill-name>-workspace/iteration-1/`.
6. Aggregate pass rate, regressions, time, token use, and qualitative feedback before recommending changes.

## SkillOpt Loop / SkillOpt 优化闭环

When improving a skill from evidence, read `references/skillopt-method.md` for details. The short loop is:

1. **Rollout / 运行**: run target tasks with the current skill and collect trajectories, outputs, scores, and user feedback.
2. **Reflect / 反思**: turn failures and useful successes into proposed edit patches.
3. **Aggregate / 聚合**: merge overlapping patches and remove duplicates.
4. **Select / 选择**: rank edits by systematic impact, complementarity, generality, and actionability. Failure-driven patches usually outrank success-only patches.
5. **Update / 更新**: rewrite the complete `SKILL.md` so selected changes form one clear document.
6. **Gate / 门禁**: accept the rewrite only if validation improves or the user explicitly accepts the tradeoff, and reject changes that hardcode benchmark answers, leak secrets, broaden scope carelessly, or break existing successful cases.

At epoch boundaries, keep compact optimizer-side memory if repeated optimization is happening: what edits helped, what caused regressions, and what future rewrites should avoid. This memory is for future skill editing, not for the target user's runtime instructions.

## Writing Rules / 编写规则

- `name` should be kebab-case, stable, and specific.
- `description` is the trigger contract. Make it explicit about when to use the skill, including likely user phrases and contexts. For bilingual skills, include Chinese and English trigger cues when helpful.
- The body should tell the agent how to act after the skill is triggered. Do not bury trigger rules only in the body.
- Keep the main `SKILL.md` under about 500 lines. Move long domain details to `references/` with clear loading instructions.
- Prefer imperative, operational instructions: inspect, run, compare, write, validate, report.
- Include examples only when they clarify behavior. Avoid example-specific overfitting.
- For repeatable logic, prefer scripts over long manual steps.
- Do not include malware, unauthorized access workflows, data exfiltration, or surprising behavior relative to the skill description.

## Bilingual Rules / 双语规则

- Use bilingual headings when the skill itself is intended for both Chinese and English users.
- Do not translate command names, CLI flags, JSON keys, file paths, environment variable names, package names, or code identifiers.
- Avoid duplicating every sentence in both languages. Use bilingual labels plus concise Chinese or English notes where that improves usability.
- Default final answers to the user's language, even if the skill content contains both languages.
- If the skill wraps an English-only tool, explain the user workflow in Chinese but keep the tool's exact syntax unchanged.

## Eval Artifacts / 评估产物

For new or improved skills, create only the artifacts the task needs:

- `evals/evals.json`: prompts, expected output, files, and optional assertions. See `references/schemas.md`.
- `<skill-name>-workspace/iteration-N/`: run outputs, timing, grading, benchmark, and feedback.
- `skillopt-meta.md` or equivalent notes: optimizer-side memory for multi-epoch improvement.
- A short final report: changed files, validation result, remaining risks, and next suggested evals.

## Helper Scripts / 辅助脚本

This skill bundles scripts that can be reused instead of writing one-off tooling:

- Validate a skill directory:
  ```bash
  python3 skills/meta/skill-creator/scripts/quick_validate.py <skill-directory>
  ```
- Aggregate benchmark data from an iteration workspace. Run from the `skills/meta/skill-creator` directory:
  ```bash
  python3 -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
  ```
- Improve trigger descriptions with train/test split when using Claude Code trigger evals:
  ```bash
  python3 skills/meta/skill-creator/scripts/run_loop.py --help
  ```
- Launch the bundled eval viewer when qualitative comparison is useful:
  ```bash
  python3 skills/meta/skill-creator/eval-viewer/generate_review.py --help
  ```

If a script assumes Claude Code but the current agent is Codex, OpenCode, Trae, Kimi, or another agent, reuse the data model and workflow while adapting the runner to that agent's CLI.

## Delivery Checklist / 交付检查

- `SKILL.md` exists and has valid frontmatter with `name` and `description`.
- The trigger description is strong enough to avoid under-triggering and narrow enough to avoid noisy triggering.
- The body is concise, actionable, and not a hidden encyclopedia.
- Any referenced file actually exists and is loaded only when needed.
- Scripts, commands, paths, and install instructions are runnable from the repo context.
- The skill has at least a light eval plan when behavior can be tested.
- The final response tells the user what changed, what was validated, and what risk remains.
