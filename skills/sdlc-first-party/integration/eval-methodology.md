# Evaluation methodology

How the two integration approaches — **A** (shared layer + sibling mode skills) and **B** (single router skill) — are tested and compared. This documents the token-counting method, the cost model, the scenarios, how to run, and how to interpret results. The declarative inputs live in `eval.json`; the runner is `run-eval.mjs`; the output is `results.md`.

## What we are comparing

| | Approach A | Approach B |
|---|---|---|
| Entry | Two triggerable skills: `frontend-build`, `frontend-redesign` | One triggerable skill: `frontend-studio` |
| Dispatch | Implicit — the right skill matches the request | Explicit — router SKILL.md picks a `modes/*.md` |
| Shared knowledge | `frontend-shared/references/*` + `stacks/*` (referenced by both) | Same `frontend-shared/*` (referenced by the router + modes) |
| Question | Does a shared layer with thin mode skills cost less per task than a single fat router? | Does routing-in-one-skill pay off when both modes run in a session? |

Both approaches load the **same** `frontend-shared` reference content. The only difference is the dispatch structure. That keeps the comparison fair: it measures *structure*, not content volume.

## Token-counting method

- **Library:** `gpt-tokenizer` (pure JS, no native deps), encoding `cl100k_base`.
- **Accuracy:** Claude uses a different BPE, so absolute token counts are **indicative, not exact** — expect ~5–15% drift from the real Claude count. The **relative** comparison (A vs B vs baseline) is sound, which is what this eval is for.
- **Fallback:** if `gpt-tokenizer` is missing, the script falls back to `chars / 4` and tags every number `est` so it is never silently wrong.
- **What is counted:** the raw text of each file (markdown source, as the agent would read it). No prompt wrapping, no system prompt — this measures the *skill content* the agent pulls into context, not the whole turn.
- **Per-file granularity:** the script reports each file's token count, so you can see which references dominate.

## The cost model

A skill firing has two phases:

1. **Always-loaded** — the `SKILL.md` that matched the request. This is read as soon as the skill triggers, before any reference. For B this also includes the `modes/<mode>.md` the router selects (the router must load the mode file to know the workflow).
2. **On-demand** — the reference files the workflow tells the agent to read at specific steps (progressive disclosure). These vary by mode and stack.

**Scenario total = always-loaded + on-demand.**

The on-demand set is the **same 7 files** for every design task (1 stack adapter + 6 references), counted once even when both modes run in a session — because progressive disclosure means each is read once and stays cached.

### What this isolates

- **S4 dispatch-overhead** — always-loaded only, no refs. This is the pure A-vs-B dispatch delta. A = one mode SKILL; B = router + mode file.
- **S1 / S2** — a single task. Total = dispatch + the 7 shared refs. The 7-file block is identical for A and B, so the difference is *only* the dispatch structure.
- **S3 build-then-redesign** — both modes in one session. A loads two mode SKILLs; B loads one router + two mode files. This is where B's shared router can win (the router is paid once).
- **Baseline** — the 6 source design skills fully loaded (SKILL.md + all their reference files). The "before" number; shows how much the integration cut.

## Scenarios

| ID | Mode | What it measures |
|----|------|------------------|
| S1-build-landing | build | One build task on Next.js |
| S2-redesign-component | redesign | One redesign task on Next.js |
| S3-build-then-redesign | both | Both modes, one session (shared refs once) |
| S4-dispatch-overhead | build | Always-loaded only — the dispatch delta |

A `tanstack` / `sveltekit` / `single-html` run swaps only the stack adapter file; the structure of the result is identical, so the eval uses `nextjs` as the representative stack and notes this.

## How to run

```bash
# from repo root
node skills/sdlc/integration/run-eval.mjs
#   → prints a comparison table to stdout
#   → writes results.md next to the script
```

The script:
1. Reads `eval.json`.
2. Resolves every file path under `skills/sdlc/`.
3. Counts tokens per file (gpt-tokenizer, fallback chars/4).
4. For each `cost_eval`, sums always-loaded + on-demand for A and B.
5. Sums the `baseline` (6 source skills, all files).
6. Prints a table and writes `results.md`.

## How to interpret

- **S4 (dispatch overhead):** A should be smaller — one thin mode SKILL vs router + mode file. If A is *not* smaller, the router didn't earn its keep.
- **S1 / S2 (single task):** the 7-file shared block dominates, so A and B land close together; the gap ≈ the S4 delta.
- **S3 (both modes):** B can win if its router (paid once) is cheaper than A's two mode SKILLs. If B loses here too, the router is strictly worse and A is the better structure.
- **Baseline vs after:** the headline reduction. Expect a large cut — the 6 originals duplicated the catalog/checklist/intake/directions six ways; the integration holds one copy.

### Decision rule

- If **S4 favors A** and **S3 does not clearly favor B** → ship **A** (shared layer + sibling mode skills). It is leaner per task and the repo already follows the `skill-shared/_shared` convention.
- If **S3 clearly favors B** (both-mode sessions are common and the shared router saves more than it costs) → ship **B**.
- In practice (see `results.md`), A tends to win on single tasks and B only breaks even when both modes run — so the recommendation is **A**, with B kept as the documented alternative for users who want a single entry point.

## Quality evals (lightweight)

`eval.json` also carries `quality_evals` — rubric checks (Q1–Q4) that the shared content is genuinely de-duplicated, stack-agnostic, and that A/B load the same reference content. These are *structural* checks, not LLM-judged quality; they can be verified by the runner or by reading the files. Real output-quality eval (does the generated UI actually look good?) needs an LLM judge + API key and is intentionally out of scope for this offline harness — see "Limitations".

## Trigger evals

`trigger_evals` (8 queries) test routing: given a request, does the right skill/mode activate? For A, this is "does `frontend-build` vs `frontend-redesign` match correctly"; for B, "does the router pick build vs redesign". These are verified by the trigger descriptions; a full automated trigger test would run each query through the agent and check which skill fired — left as a manual check here.

## Limitations

- **Tokenizer approximation** — cl100k_base ≠ Claude BPE. Relative comparison valid; absolute numbers indicative.
- **No LLM judge** — output quality (does the de-slopped UI actually look better?) is not measured. The eval measures *structure and load cost*, not *taste*. The quality_evals only check that the knowledge is correctly consolidated, not that it produces better UI.
- **Progressive disclosure is modeled, not observed** — the on-demand set assumes the agent reads exactly the 7 shared files. A real agent might read a subset (fewer tokens) or re-read (more). The model is a reasonable upper bound for a complete task.
- **Slides / structure excluded** — `frontend-slides` and `fe-code-structure` are different products; they're listed in `index.md` and the route tables but not in the A/B cost comparison.
