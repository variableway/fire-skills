# SkillOpt Method for Skill Creator / SkillOpt 优化方法

This reference adapts the local `references-projects/SkillOpt` project into a practical method for editing agent skills. It is a workflow reference, not a requirement to copy the full SkillOpt Python runtime.

## Core Idea / 核心思想

Treat the skill document as trainable state. The target agent stays the same; the optimizer improves the natural-language `SKILL.md` by learning from scored runs, failures, successful patterns, and validation gates.

角色对应：

- Target skill: the deployed `SKILL.md` being used by an agent.
- Target agent: the agent that performs user tasks with that skill.
- Optimizer: the current coding agent or toolchain rewriting the skill.
- Eval set: realistic tasks used to measure whether the skill helps.
- Gate: an acceptance rule that prevents harmful rewrites from replacing the current best skill.
- Meta-skill memory: compact optimizer-side notes about what kinds of edits help or hurt.

## Loop / 闭环

1. Rollout / 运行
   Run representative tasks with the current skill. Save prompts, outputs, tool traces if available, pass/fail scores, timing, token use, and user feedback.

2. Reflect / 反思
   Convert evidence into proposed edits. Focus first on failures and regressions, then on successful patterns worth preserving.

3. Aggregate / 聚合
   Merge semantically similar edits. Remove duplicates and combine small local fixes into broader reusable guidance.

4. Select / 选择
   Rank proposed edits under a small edit budget. Prefer edits with:
   - systematic impact: fixes recurring failures across many tasks;
   - complementarity: fills a real gap in the current skill;
   - generality: applies beyond one benchmark item or example;
   - actionability: gives clear behavior, not vague advice.

5. Update / 更新
   Rewrite the full skill document. Preserve effective guidance, consolidate overlapping rules, and keep the document coherent.

6. Gate / 门禁
   Validate the rewritten skill against held-out or previously successful cases. Accept only if it improves the validation result, fixes an accepted user pain point without unacceptable regressions, or the user explicitly chooses the tradeoff.

## Patch Shape / 编辑建议格式

Use a compact patch record while reflecting, even if the final output is a full rewrite:

```json
{
  "source_type": "failure",
  "op": "append",
  "target": "Writing Rules",
  "content": "Add a rule that commands, paths, and config keys must remain exact when translating a bilingual skill.",
  "evidence": ["Chinese rewrite changed CLI flags in eval-2"],
  "support_count": 1,
  "risk": "Low"
}
```

Use `source_type: "failure"` for corrective edits and `source_type: "success"` for reinforcement edits. Failure-driven edits usually take priority because the purpose of reflection is to repair observed weakness.

## Rewrite Rules / 重写规则

- Produce a complete standalone `SKILL.md`, not a patch list.
- Keep effective existing guidance unless a selected edit clearly says to remove or merge it.
- Prefer consolidation and clarity over length.
- Do not hardcode benchmark-specific answers, entity names, file paths, or gold values.
- Preserve the skill's scope as reusable behavioral guidance.
- Keep protected slow-update blocks intact if present:
  ```markdown
  <!-- SLOW_UPDATE_START -->
  ...
  <!-- SLOW_UPDATE_END -->
  ```
- Make the new version internally consistent and easier to follow than the old one.

## Gate Criteria / 门禁标准

Accept a rewrite only when the evidence supports it:

- Validation pass rate improves, or qualitative review clearly improves without unacceptable regressions.
- Existing passing cases remain passing unless the user accepts the tradeoff.
- Trigger behavior improves: fewer missed useful triggers and fewer false triggers.
- No secrets, hidden credentials, `.env` content, or unrelated private data are added.
- No benchmark-specific hardcoding or one-off answer leakage is added.
- The skill remains concise enough for progressive disclosure.

If the gate fails, keep the previous best skill and store the rejected edit with the reason. Rejected edits are useful memory because they tell future optimization what not to repeat.

## Meta-Skill Memory / 元优化记忆

For multi-epoch optimization, maintain a short optimizer-side note such as `skillopt-meta.md` in the eval workspace. This note should address the future optimizer, not the target user. Capture:

- which edit styles helped;
- which edits were too vague, redundant, brittle, or harmful;
- what abstraction level worked best;
- what regression risks to watch;
- what evidence should be collected next.

Do not paste this memory into the deployed skill unless it is also useful target-facing guidance.

## Minimal Manual Loop / 最小手工流程

When no automated runner exists, use this manual loop:

1. Pick 3-5 real prompts.
2. Run each prompt with the current skill and, if possible, with a baseline.
3. Record failures and successes in a simple table.
4. Draft patches from evidence.
5. Rank patches with the criteria above.
6. Rewrite `SKILL.md` once.
7. Re-run the same prompts plus at least one held-out prompt.
8. Keep the rewrite only if the gate passes.

## Product Integration / 产品化整合

Use this method inside a skill manager as the optimization layer:

- Search/discovery finds candidate skills and similar prior art.
- Install/sync moves skills to target agents.
- Eval runner records with-skill and baseline runs.
- SkillOpt-style optimizer proposes and gates rewrites.
- Lock/update/remove governance preserves version history and reproducibility.

This makes SkillOpt a method for continuous skill improvement while keeping `skill-spark` or another CLI responsible for installation and agent directory management.
