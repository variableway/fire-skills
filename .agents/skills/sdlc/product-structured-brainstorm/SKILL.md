---
name: product-structured-brainstorm
description: "Use when the user asks to brainstorm, ideate, or explore product ideas — software features, architecture design, product strategy. Applies 5 structured brainstorming frameworks: First Principles Thinking, SCAMPER, Starbursting, Reverse Brainstorming, and Impact vs Effort Matrix."
---

# Structured Brainstorm Skill for Software Product Ideation

## Why Structured Brainstorming?

Traditional free-form brainstorming has 3 fatal flaws in software product development:
1. **Cognitive bias** — loud voices dominate; introverts' deep thinking gets drowned
2. **Premature convergence** — teams rush to solutions before fully understanding the problem
3. **Lack of actionability** — many ideas generated but none become executable decisions

Use these 5 structured methods to solve these problems systematically.

---

## Five Structured Brainstorm Frameworks

### 1. First Principles Thinking

**When to use:** Product direction exploration, architecture top-level design, tech debt refactoring.

**Process:** Break the problem down to fundamental truths, then rebuild from scratch — not by analogy or convention.

```
Identify existing assumptions → Ask "Why is it this way?" → Strip away all analogies and conventions
→ Define irreducible fundamental truths → Build new solution from scratch
```

**Key application:**
- **Requirements:** Don't ask "what do competitors do?" — ask "what is the user's fundamental problem?"
- **Architecture:** Don't be constrained by "microservice/monolith" labels — derive from system constraints (throughput, consistency, team size)
- **Tech selection:** Don't start from "what's popular" — start from "what are our performance/maintenance/learning cost constraints?"

**Pros:** Break free from industry convention, generate truly innovative solutions.
**Cons:** High time cost; team needs sufficient domain knowledge to identify real "fundamental truths."

---

### 2. SCAMPER — Systematic Innovation Method

**When to use:** Feature iteration, differentiation after competitor analysis, deep optimization of existing functionality.

**Process:** Apply 7 dimensions of questioning to systematically improve an existing product/feature:

| Dimension | Question | Example |
|-----------|----------|---------|
| **S**ubstitute | What can be replaced? | Replace Slack with Discord for team comms? |
| **C**ombine | What can be merged? | Combine CLI + TUI dashboard into unified UX? |
| **A**dapt | What can we borrow from? | Adapt Linear/Jira's issue workflow? |
| **M**odify | What can be changed? | Make stage flow configurable instead of fixed? |
| **P**ut to another use | What else is it good for? | Use markdown engine for PRD docs? |
| **E**liminate | What can be removed? | Drop third-party sync, focus on local integration? |
| **R**everse | What if we flipped it? | Switch from "user creates tasks" to "AI auto-detects todos"? |

**Pros:** Systematic coverage of all improvement directions; clear question templates.
**Cons:** Focuses on "improving" not "disrupting"; all 7 dimensions take time — focus on 2-3 per session.

---

### 3. Starbursting — Star Burst Questioning

**When to use:** Before product requirements definition, requirement clarification meetings.

**Process:** Generate questions (not answers) around a central theme using **Who/What/Why/Where/When/How** dimensions.

```
                Who  (Who will use/maintain/be affected?)
                   ↑
    What (What core problem to solve?) →  ★ CENTRAL THEME ★  ← How (How to measure success/failure?)
                   ↓
    Where (Where to use/deploy?)           Why (Why do it now?)
                   ↓
                When (When to release/iterate?)
```

**Example questions for each dimension:**
- **Who:** Target users? Who maintains config?
- **What:** Core problem? Differentiation from competitors?
- **Why:** Why now? What bottleneck does current approach face?
- **Where:** Local or cloud storage? Per-repo or per-machine?
- **When:** MVP timeline? Priority order of integrations?
- **How:** Success metrics? Retention? Completion rate? Delivery speed?

**Pros:** Forces thorough problem understanding before seeking solutions; reveals hidden assumptions.
**Cons:** Only generates questions, not answers; may seem redundant for experienced teams.

---

### 4. Reverse Brainstorming

**When to use:** Risk assessment, architecture review, pre-release checklist.

**Process:** Instead of thinking "how to succeed", think "how to guarantee failure" — then reverse each failure into a success strategy.

```
Define goal → Reverse question: "How to ensure this project fails COMPLETELY?"
→ List all failure factors → Reverse each into prevention strategy → Prioritize by risk
```

**Example (for a product v2 launch):**

| How to guarantee FAILURE | Reversed prevention strategy |
|---------------------------|------------------------------|
| Make config extremely complex, requiring hand-written YAML | Provide interactive init command with guided setup |
| Sync frequently fails without notification | Implement sync-status and conflict-resolution |
| Data format incompatible with v1, causing data loss | Design v1→v2 auto-migration mechanism |
| Dashboard freezes with 100+ items | Use paginated queries + virtual scrolling |
| Too many concepts confuse users | Progressive concept exposure, hide advanced by default |

**Pros:** Human brains detect threats more readily than opportunities; directly produces risk + mitigation.
**Cons:** Can breed excessive pessimism; needs facilitator to control tone.

---

### 5. Impact vs Effort Matrix

**When to use:** After generating all ideas — prioritization, sprint planning, tech decision making.

**Process:** Map all brainstormed ideas onto a 2×2 matrix with **Impact** and **Effort** axes.

```
High Effort   │  Strategic Projects      │  Quick Wins
              │  (High Impact/High Effort)│  (High Impact/Low Effort) ★ DO FIRST
              │  Needs resource planning  │
              ├───────────────────────────┼───────────────────────→ High Impact
              │  Time Traps               │  Fill-in Work
              │  (Low Impact/High Effort) │  (Low Impact/Low Effort)
              │  DO NOT DO                │  Do when time permits
              └───────────────────────────┴───────────────────────→ Low Impact
                         Low Effort
```

**Priority mapping:**
- **Quick Wins (HI/LE):** P0 — immediate value with minimal cost
- **Strategic Projects (HI/HE):** P1-P2 — high value but needs planning
- **Fill-in Work (LI/LE):** P3 — nice-to-have, no urgency
- **Time Traps (LI/HE):** Never do — expensive with minimal return

**Pros:** Transforms subjective debate into objective 2D mapping; visual, communicable.
**Cons:** Impact/Effort assessment is inherently subjective; ignores strategic dependencies.

---

## Combined Workflow

For full product ideation, use methods in this order:

```
Phase 1: Starbursting
    → Fully understand the problem space, identify key questions

Phase 2: First Principles Thinking
    → From fundamental constraints, define core product differentiation

Phase 3: Reverse Brainstorming
    → Identify all potential failure factors

Phase 4: SCAMPER
    → Based on insights from phases 1-3, systematically generate improvement ideas

Phase 5: Impact vs Effort Matrix
    → Prioritize all ideas, produce executable roadmap
```

---

## How to Use This Skill

When a user asks to brainstorm:
1. **Diagnose** — Which phase are they in? Problem exploration, ideation, risk analysis, or prioritization?
2. **Select method** — Pick the appropriate framework(s) from the 5 above
3. **Guide execution** — Walk through the chosen framework step by step, ask questions, document outputs
4. **Transition** — After ideation, transition to planning with the Impact vs Effort Matrix

**Key principles:**
- Start with Starbursting or First Principles when the problem is fuzzy
- Use Reverse Brainstorming before committing to solutions
- SCAMPER works best when there's already an existing product to improve
- Always end with Impact vs Effort Matrix to make decisions actionable
