---
name: omb-create-plan
user-invocable: true
description: >
  (omb) Use when planning before implementation, decomposing tasks, scoping work,
  creating execution plans, or breaking down features. Triggers on: plan, design,
  scope, architect, decompose, break down, create a plan, "how should we build".
  Do NOT use for trivial single-file fixes or when user wants immediate execution.
argument-hint: "[description of what to plan]"
allowed-tools: Read, Write, Bash, Grep, Glob, Agent, Skill, AskUserQuestion, ExitPlanMode
---

## PLAN MODE GUARD

[HARD] Before starting any planning step, check if Claude Code's native plan mode is active.

**Detection:** Plan mode is active when the conversation contains a system-reminder with "Plan mode is active" or "Plan mode still active", and a designated plan file path like `~/.claude/plans/*.md`.

**Action:** If plan mode is detected:
1. Call `ExitPlanMode` immediately — braincrew's planning workflow manages its own plan output at `.omb/plans/` with tracking code allocation. Native plan mode's write restrictions prevent this skill from functioning correctly.
2. Log: "Exited native plan mode to enable braincrew planning at `.omb/plans/`."
3. Proceed with the normal workflow below.

**If ExitPlanMode is unavailable or fails:** Inform the user: "Native plan mode is active and blocks writes to `.omb/plans/`. Please press Shift+Tab to exit plan mode, then re-invoke `/braincrew plan`."

# Planning Workflow

Create a comprehensive, actionable execution plan through structured analysis.

## MODE SELECTION

Before starting, determine the planning mode from the user's request:

| Signal | Mode | Flow |
|--------|------|------|
| Broad/vague request (default) | **Full** | All 4 steps |
| Recent interview summary in `.omb/interviews/` | **Direct** | Interview already gathered context — skip clarification |
| Detailed request with specific files/endpoints, or `--direct` | **Direct** | Skip Step 1 clarification, streamlined Step 2, full Steps 3-4 |
| `--review` or "review this plan" | **Review** | Jump to Review Mode section |
| "skip planning" or EMERGENCY tier | **Abort** | Stop immediately |

## STEP 1 — Analyze Intent

Read the user's request from `$ARGUMENTS`.

### Prior Interview Check

Check for recent interview summaries from the `full` pipeline:
!`ls -t .omb/interviews/*.md 2>/dev/null | head -1`

If a recent interview document exists (created today or within the active pipeline):
1. Read the interview summary in full
2. Auto-select **Direct mode** — the interview already gathered requirements
3. Use the interview's "Functional Requirements" and "Constraints" sections as primary input for plan tasks
4. Use the interview's "Open Questions" section to identify remaining gaps (address in plan Risks)
5. Skip Step 1 clarification questions — proceed directly to Step 2

### Workflow Tier Detection

Detect the tier per `.claude/rules/01-plan.md`:

| Tier | Criteria | Plan Response |
|------|----------|---------------|
| TRIVIAL | <10 lines, 1 file, no behavior change | Inline plan (no file), skip to Step 4 with TRIVIAL template |
| STANDARD | Most tasks | Full 4-step workflow |
| EMERGENCY | Hotfix, user says "skip plan" | Abort with note: `Skipped: plan,review,docs | hotfix urgency` |

### Classify the Request

| Signal | Classification | Action |
|--------|---------------|--------|
| Specific files, functions, or endpoints named | **Specific** | Proceed to Step 2 |
| Vague verbs ("improve", "add"), no file targets, 3+ areas | **Broad** | Clarify before Step 2 |

### Question Classification

Never ask the user about things you can discover from the codebase:

| Type | Examples | Action |
|------|----------|--------|
| Codebase Fact | "What patterns exist?", "Where is X defined?" | Explore first, never ask user |
| User Preference | "Priority?", "Which approach do you prefer?" | Ask user via AskUserQuestion |
| Scope Decision | "Include Y in scope?", "Which layers?" | Ask user |
| Constraint | "Timeline?", "Breaking changes allowed?" | Ask user |

### If Broad

Ask **one question at a time** using `AskUserQuestion` to narrow scope:
- What is the primary goal?
- Which stack layers are involved? (Python backend, Node.js, React frontend, Electron, data, infra)
- What are the constraints? (timeline, breaking changes, backward compat)

**Max 3 question rounds.** Gather codebase facts via `explore` agent BEFORE asking the user.

### Prior Plan Check

Check for existing plans that may conflict or inform the current task:

Existing plans: !`ls .omb/plans/*.md 2>/dev/null | wc -l | tr -d ' '` files

If >0, run `bash ${CLAUDE_SKILL_DIR}/scripts/list-prior-plans.sh` and check for:
- Architecture decisions that constrain the current plan
- Active plans for the same stack layers
- Conflicting approaches or scope overlap

### Step 1 Output Contract

```
Produces: tier (TRIVIAL|STANDARD|EMERGENCY), mode (Full|Direct|Review),
scope summary (1-2 sentences), affected layers list, prior plan conflicts (if any)
```

## STEP 2 — Brainstorm Approaches

Propose 2-3 approaches with trade-offs. Follow the approach format and evaluation criteria in `${CLAUDE_SKILL_DIR}/reference.md`.

Present your recommendation with reasoning. Let the user pick or combine approaches.

**Principles:**
- YAGNI — remove unnecessary features from all proposals
- Lead with the recommended option and explain why
- Each approach must name affected stack layers and estimated complexity
- If only one viable approach exists, state why alternatives were rejected

**Conditional skip:** If only one viable approach exists AND mode is Direct, state why alternatives were rejected and proceed without waiting for user confirmation.

Otherwise, wait for user confirmation before proceeding to Step 3.

### Step 2 Output Contract

```
Produces: recommended approach with rationale, affected layers,
estimated task count, user confirmation (or auto-proceed in Direct mode)
```

## STEP 3 — Parallel Exploration

Read `.omb/config.json` for reference project paths.

For each explorer, invoke the `Agent` tool with `subagent_type: "explore"` and `model: "haiku"`. Issue ALL explorer calls in a single parallel batch — one `Agent` call per explorer, all in the same response. Use the prompt templates in `${CLAUDE_SKILL_DIR}/reference.md`.

[HARD] Explorers MUST return actual code snippets, function signatures, and line numbers — not just file paths. The plan needs enough code context for the executor to write implementation code snippets. If an explorer returns only file paths without code context, the plan will lack the code snippets needed for task detail sections.

### Required Explorers

1. **Structure Explorer** — files, modules, routes, entry points, dependency graph for the affected areas
2. **Pattern Explorer** — AST-grep + Grep for code conventions, naming patterns, existing implementations of similar features
3. **Reference Explorer** — search reference projects from `.omb/config.json` for similar patterns and implementations
4. **Test Explorer** — test infrastructure, existing test patterns, fixtures, coverage for affected modules

### Conditional Explorers (spawn if relevant)

5. **Schema/API Explorer** — DB models, API routes, Pydantic/TypeScript types, Redis key patterns for affected data
6. **Prior Plan Explorer** — searches `.omb/plans/` for architecture decisions that constrain the current plan (spawn if prior plans exist from Step 1 check)

### Explorer Output Format

Each explorer returns:
```
## [Explorer Name] Findings
- file:line — one-sentence summary
  ```language
  // relevant code snippet (3-5 lines of context)
  ```
- file:line — one-sentence summary
  ```language
  // relevant code snippet
  ```
```

Each explorer's prompt in reference.md includes an output mapping showing which plan template sections its findings feed into. Code snippets from explorers feed directly into per-task Implementation sections.

**Timeout guidance:** If an explorer hasn't returned results after 60s, proceed with available findings and note the gap in the plan.

## STEP 4 — Generate Master Plan

### 4a. Generate Tracking Code

Run the worktree-safe tracking shim to get a PLAN tracking code:
```
bash ${CLAUDE_SKILL_DIR}/scripts/next-plan-code.sh
```
Capture the output (e.g., `BCRW-PLAN-000001`) and use it for the plan filename.

If the shim fails:
1. Run `omb tracking next PLAN` directly
2. If tracking code generation fails, log the error and proceed — the plan can still be saved with session_id naming.

**TRIVIAL tier:** Skip tracking code generation. Use inline plan (no file).

### 4b. Synthesize Plan

Combine user intent, chosen approach, and explorer findings into a plan. Use the STANDARD template in `${CLAUDE_SKILL_DIR}/reference.md` (or TRIVIAL/EMERGENCY variants when applicable).

The template has three structural layers — the executor agent uses these as direct implementation specs, so missing sections cause blocked tasks:

1. **Header** — Context, Architecture Decisions, Tasks Summary table, Parallelization
2. **Per-Task Detail** — each task gets a `## Task N:` section with 8 subsections (File, Agent, Problem, Rules, Critical Fix, Implementation, Key Design Decisions, Test Strategy)
3. **Footer** — Edge Cases & Solutions, Critical Files, Risks, Verification, Test Cases (Overall)

[HARD] Every implementation task MUST have code snippets in its Implementation section. The executor agent implements tasks by following these snippets directly — without code, the task becomes ambiguous and blocks execution.

**Exceptions to the code snippet rule:**
- **Greenfield with zero existing code:** provide the full new file content instead of annotated diffs
- **Config-only tasks** (env files, JSON, YAML): show the final config content — no `[NEW]` markers needed
- **Tasks dependent on prior task output:** provide the code skeleton with `# [PLACEHOLDER: depends on Task N output]` markers and describe the expected shape

**Per-task field edge cases:**
- **Problem** for new features: describe the gap or user need, not a bug. e.g., "No model validation exists when creating agents — users can select models without API keys"
- **Rules** when none apply: write `None — no specific rule constraints`
- **File** for multi-file tasks: list the primary file; show additional files in separate code blocks in the Implementation section

**ADR stub:** If the plan involves an architecture decision affecting 2+ stack layers, append an ADR stub section:
```markdown
### ADR Stub
- **Status:** Proposed
- **Context:** [Why this decision was needed]
- **Decision:** [What was chosen]
- **Consequences:** [Tradeoffs — positive and negative]
```

### 4c. Quality Gate

Before saving, scan the plan against the STANDARD template. Fix failures before saving.

- [ ] Every `## Task N:` section has all 8 subsections (File through Test Strategy) — compare against template
- [ ] Every implementation task has code snippets with `[NEW]` markers and surrounding context (or uses an exception from 4b)
- [ ] Deliverables in Tasks Summary are specific file paths, not vague words like "implementation"
- [ ] Dependencies follow correct order: DB > API > frontend > integration > verification
- [ ] Edge Cases table has 3+ entries for multi-task plans
- [ ] Verification section has numbered action → result scenarios, not just "run tests"
- [ ] Risks table includes at least one cross-layer risk when 2+ layers are affected

### 4d. Save Plan

Save to `.omb/plans/<session_id>.md` where `<session_id>` is the active pipeline session ID (from pipeline context or `.omb/sessions/` state). If no session is active, generate an ad-hoc session_id using the format `YYYYmmddHHMM-XXXXXX` (6 random lowercase alphanumeric chars).

Example: `.omb/plans/202603201530-ab3x7z.md`

### 4d-bis. Plan Mode Visibility

Create a symlink in `.claude/plans/` so the plan appears in Claude Code's native plan mode:

```bash
mkdir -p .claude/plans
ln -sf "../../.omb/plans/<session_id>.md" ".claude/plans/<session_id>.md"
```

Example: `.claude/plans/202603201530-ab3x7z.md` → `.omb/plans/202603201530-ab3x7z.md`

If symlink creation fails (e.g., Windows), copy the file instead:
```bash
cp ".omb/plans/<session_id>.md" ".claude/plans/<session_id>.md"
```

Report: "Plan linked at `.claude/plans/<session_id>.md` for plan mode visibility."

### 4e. Self-Assessment and Critic Handoff

After saving, output a structured self-assessment for the critic. Use the format in `${CLAUDE_SKILL_DIR}/reference.md` (Critic Handoff Format section).

Include TDD coverage confidence as a dimension in the self-assessment. See the `TDD coverage` row in the Critic Handoff Format in `${CLAUDE_SKILL_DIR}/reference.md`.

### 4f. Report

Tell the user:
- Plan file path
- Summary of tasks (count, key deliverables)
- Self-assessment summary
- Suggested next step: "Ready for critic review (Step 2 of workflow)"

## REVIEW MODE

Triggered by `--review` or "review this plan".

**Delegate to `/omb review`** — the dedicated multi-agent plan review skill.

Pass the plan file path (or let the review skill prompt for it).
This skill handles domain detection, parallel review teams (3-13), issue tracking, and fix loops.

Do NOT review plans inline here — always delegate to `/omb review`.

## Escalation and Limits

- **Max 3 question rounds** in Step 1 — if still unclear, plan with what you have and flag assumptions
- **User says "skip planning"** — stop immediately
- **Tracking allocation fails** — log warning, proceed with session_id naming
- **Explorer timeout** — proceed with available results, note missing coverage in the plan
- **Max plan size** — if the plan exceeds 30 tasks, split into phases with separate plan files linked by dependencies
- **Prior plan conflicts** — if 2+ prior plans conflict with current request, flag conflict and ask user to choose

## Anti-Patterns

- Asking the user about code patterns you could discover with `explore`
- Batching multiple questions in one message
- Generating a plan without codebase exploration
- Skipping the brainstorm step and jumping to a single approach
- Writing code or making changes during planning (config/metadata counter updates are exempt — they are bookkeeping, not business logic)
- Planning without checking `.omb/plans/` for prior decisions
- Using STANDARD tier for a TRIVIAL task (over-planning)
- Writing vague deliverables like "implementation" instead of specific file paths
- Producing a plan with no cross-layer risks when task touches 2+ layers

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>create-plan(brief summary of outcome)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `DONE` — completed successfully
- `DONE_WITH_CONCERNS` — completed with flagged issues
- `FAILED` — could not complete
- `NEEDS_CONTEXT` — missing information, cannot proceed
