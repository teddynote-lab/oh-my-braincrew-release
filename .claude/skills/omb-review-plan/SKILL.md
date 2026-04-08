---
name: omb-review-plan
user-invocable: true
description: >
  Use when reviewing a plan before execution, validating architecture decisions,
  checking plan feasibility, or running Step 2 of the workflow. Triggers on:
  review plan, critique plan, validate plan, "is this plan ready", check plan quality.
  Spawns 3-13 parallel review teams based on plan domains. Do NOT use for creating
  plans (use omb-create-plan) or reviewing code (use reviewer agent directly).
argument-hint: "[plan-file-path] [--teams N]"
allowed-tools: Read, Write, Bash, Grep, Glob, Agent, AskUserQuestion
---

# Plan Review Workflow

Multi-agent parallel review system for plans in `.omb/plans/`.
Spawns domain-aware review teams, organizes findings into prioritized tickets, loops until blocking issues are resolved.

<references>
- `${CLAUDE_SKILL_DIR}/reference.md` § 2 — team selection rules and agent assignments
- `${CLAUDE_SKILL_DIR}/reference.md` § 3 — agent prompt templates (T1-T13)
- `${CLAUDE_SKILL_DIR}/reference.md` § 4-8 — issue format, tracker template, report template, dedup rules, fix strategies
</references>

<completion_criteria>
The review is complete when ALL of these hold:
- Every selected team has returned a report (or been noted as timed out)
- All issues are deduplicated and tracked with RPR-NNN IDs
- ALL priorities cleared: P0=0, P1=0, P2=0, P3=0 (every issue FIXED, ESCALATED, or WONTFIX)
- Updated plan written to disk (if any fixes applied)
- Review report presented to user with verdict
- TDD Implementation Plan section validated by T3 (coverage achievability, edge cases, test granularity)
- Every team finding passes the adversarial quality gate: material (not stylistic), grounded (supported by plan text), and actionable (concrete fix)
- Findings below the material finding bar (style, naming, low-value cleanup) are rejected during dedup

Status codes: APPROVED | NEEDS_REVISION | BLOCKED
</completion_criteria>

<ambiguity_policy>
- Agent returns garbage/non-standard output: extract what you can, log "non-standard report from [team]", do NOT re-spawn — proceed with partial data
- Two teams contradict each other (e.g., T5 says "add middleware" vs T8 says "remove middleware"): create a P1 conflict issue, escalate to user via AskUserQuestion — never resolve contradictions autonomously
- Plan section is ambiguous (could be interpreted multiple ways): flag as P2 "Ambiguous plan section", suggest the user clarify — do not guess intent
- Domain detection fires on false positive (e.g., "table" triggers database but plan is about HTML tables): review the spawned team's report — if findings are irrelevant, discard them silently
- Unsure whether an issue is P0 or P1: default to P0 — over-escalation is safer than under-escalation
- Grounding rule: every finding must be defensible from the plan content. Do not invent failure modes, attack chains, or runtime behavior not supported by the plan text. If a conclusion depends on inference, state it explicitly and keep confidence honest.
- Calibration rule: prefer one strong finding over several weak ones. Do not dilute serious issues with filler. If the plan section looks sound, say so directly.
- Final check: before accepting findings from any team, verify each is adversarial (not stylistic), tied to a concrete plan section, plausible under a real failure scenario, and actionable for a plan revision.
- Operating stance integration: the adversarial stance sets the review *approach*, while severity assignment still follows ambiguity_policy rules — default to P1 when uncertain, P0 for security.
</ambiguity_policy>

<scope_boundaries>
This skill reviews plans — it does NOT:
- Create or rewrite plans (use omb-create-plan)
- Review code or PRs (use reviewer agent directly)
- Execute any plan tasks
- Modify files outside `.omb/plans/`
- Make architecture decisions — it surfaces issues for the user or planner to resolve
</scope_boundaries>

<adversarial_stance>
All review teams operate under an adversarial review pattern:

**Operating principle:** Default to skepticism. Assume the plan can fail in subtle, high-cost, or user-visible ways until the evidence says otherwise. Do not give credit for good intent, partial solutions, or likely follow-up work. If something only works on the happy path, treat that as a real weakness.

**Intensity tiers:**
- Full adversarial (T1: Architecture, T8: Security): actively try to break confidence in the plan. Look for the strongest reasons it should not proceed. 5 new sections: operating_stance, attack_surface, review_method, grounding_rules, final_check.
- Calibrated adversarial (T2-T7, T9-T13): skeptical but proportional. Challenge assumptions and surface risks, but do not block on speculative concerns without evidence. 3 new sections: operating_stance, attack_surface, grounding_rules.

**Attack surface (combined plan-level + code-level):**
Plan-level: dependency ordering errors, missing scope, vague deliverables, absent rollback strategy, unverifiable criteria, parallel execution assumptions
Code-level: auth/permissions gaps, data loss/corruption risks, race conditions, idempotency gaps, empty-state handling, version skew, observability blind spots

**Finding bar:** Report only material findings. Exclude style feedback, naming preferences, low-value cleanup, or speculative concerns without evidence. Every finding must answer: (1) what can go wrong, (2) why this plan section is vulnerable, (3) likely impact, (4) concrete fix.

**Severity assignment:** The adversarial stance does NOT override existing severity rules. Default to P1 when uncertain, P0 for security issues. The UNCERTAIN: prefix convention remains in effect for low-confidence findings.
</adversarial_stance>

---

## STEP 0 — Locate Plan

1. Parse `$ARGUMENTS` for:
   - Plan file path (positional argument)
   - `--teams N` override (optional, range 3-13)

2. If no path provided:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/../omb-create-plan/scripts/list-prior-plans.sh
   ```
   Ask the user which plan to review via `AskUserQuestion`.

3. Read the plan file. Abort if missing: "Plan file not found: {path}"

4. Validate the plan has a tasks table. Abort if missing: "Plan has no task table — cannot review"

5. Store plan content for distribution to review teams.

**Step output:** plan content in memory, validated and ready for distribution.

---

## STEP 1 — Analyze Plan & Spawn Review Teams

### 1a. Detect Domains

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/detect-plan-domains.sh <plan-path>
```

Parse the JSON output. Each key maps to a boolean: `frontend`, `electron`, `backend_api`, `database`, `langchain`, `security`, `infra`, `async`, `prompt`, `designer`, `architect`.

### 1b. Determine Team Count

If `--teams N` provided, use N (clamped 3-13).
Otherwise auto-scale:

| Domains detected | Default teams |
|-----------------|---------------|
| 1 | 3 (minimum) |
| 2-3 | 4-5 |
| 4-5 | 5-7 |
| 6+ | 7-13 (cap) |

If zero domains detected: spawn T1, T2, T3 only. Log warning: "No domain keywords matched — running core review teams only."

### 1c. Select & Spawn Teams

Three always-on teams (T1, T2, T3) plus conditional teams (T4-T13) based on detected domains.

Read `${CLAUDE_SKILL_DIR}/reference.md` § 2 for the full team-to-agent mapping and spawn conditions.

Domain-to-team mappings for the three new conditional teams:
- `prompt: true` → spawn T11 (prompt-engineer agent)
- `designer: true` → spawn T12 (web-designer agent)
- `architect: true` → spawn T13 (planner + critic agents)

For each selected team:
1. Read the matching prompt template from `${CLAUDE_SKILL_DIR}/reference.md` § 3
2. Replace `{PLAN_CONTENT}` with the actual plan content
3. Set `subagent_type` to the agent name matching `.claude/agents/omb/{name}.md` and `model` per the team table in reference.md § 2

Invoke the `Agent` tool for ALL selected teams **in a single parallel batch** — one `Agent` call per agent, all in the same response. Each call specifies `subagent_type`, `model`, `prompt`, and `description`. Multi-agent teams (T1, T2, T4-T7, T13) invoke each agent separately — both run in parallel.

**Step output:** N agents running in parallel, each reviewing the plan from their domain perspective.

---

## STEP 2 — Gather Reports

Collect agent reports as they complete. For each report:

1. Extract issues matching the standardized format from `${CLAUDE_SKILL_DIR}/reference.md` § 4
2. Tag each issue with its source team (T1-T13)
3. Handle special statuses:
   - `NEEDS_CONTEXT` — log the gap, proceed with available results
   - `BLOCKED` — log the blocker, proceed with available results
   - Non-standard output — extract what you can, note "non-standard report from [team]"
4. Extract the pre-mortem statement from T1 (Architecture) — this is mandatory for the final report

Expect ~90 seconds per agent. If an agent returns minimal findings, that domain may not be well-represented in the plan — this is fine, not an error.

**Step output:** raw issue list from all teams, plus T1's pre-mortem statement.

---

## STEP 3 — Organize Issues as Tickets

### 3a. Deduplicate

Apply rules from `${CLAUDE_SKILL_DIR}/reference.md` § 7:
- Same file + same concern → merge, keep highest severity
- Same concern + different files → keep separate
- Severity conflict → escalate to higher severity
- Contradictory recommendations → create P1 conflict issue, escalate to user

### 3b. Assign Priority & Build Tracker

Priority criteria (from `${CLAUDE_SKILL_DIR}/reference.md` § 4):
- **P0/P1** → status: `OPEN` (must fix — loop continues, highest priority)
- **P2/P3** → status: `OPEN` (must fix — loop continues after P0/P1 cleared)

**TDD-specific priority rules** (enforced by T3, see reference.md § 4):
- **P1**: Plan has no TDD Implementation Plan section (T3 direct-fixes by adding skeleton)
- **P0**: TDD section present but coverage target below domain threshold
- **P1**: Tests only cover happy path for critical tasks (auth, data access, payment, external APIs)

Build the issue tracker table per `${CLAUDE_SKILL_DIR}/reference.md` § 5.
Issue IDs: `RPR-001`, `RPR-002`, etc. (sequential within this session).

### 3c. Count Blockers

```bash
echo "<tracker-table>" | bash ${CLAUDE_SKILL_DIR}/scripts/count-open-blockers.sh
```

**Step output:** deduplicated issue tracker table with OPEN issue counts by priority (P0/P1/P2/P3).

---

## STEP 4 — Fix All OPEN Issues (P0 → P3)

If no OPEN issues remain (P0=0, P1=0, P2=0, P3=0): skip to STEP 5.

Process OPEN issues in priority order (P0 first, then P1, then P2, then P3). For each issue, determine fix type per `${CLAUDE_SKILL_DIR}/reference.md` § 8.

**Direct fixes** (apply immediately to plan in memory):
Dependency reordering, missing deps, agent/model reassignment, missing verification criteria, missing risks, vague deliverables, missing rollback, parallelization updates.

Apply direct fixes in this order — dependency changes first, since they affect downstream fixes:
1. Dependency ordering and missing `Depends On`
2. Agent/model reassignment
3. Verification criteria, risks, rollback
4. Deliverable specificity, parallelization

**Escalated fixes** (require user input):
Scope changes, conflicting recommendations, missing external deps, architecture alternatives, security policy decisions, resource constraints.

For each escalated issue:
1. Present via `AskUserQuestion`: state the issue, the options, and the tradeoffs
2. Apply the user's decision
3. Mark as `FIXED` or `WONTFIX` per response

After all fixes: update tracker statuses.

**Step output:** updated plan content in memory, updated tracker with FIXED/WONTFIX/ESCALATED statuses.

---

## LOOP GATE

| Condition | Action |
|-----------|--------|
| All OPEN=0 (P0=0, P1=0, P2=0, P3=0) | Proceed to STEP 5 (finalize) |
| Iteration < 3 AND any OPEN issues remain | Re-review (see below) |
| Iteration >= 3 | Force stop — report all unresolved issues, escalate to user |

### Re-review procedure (iterations 2-3)

On re-review, do NOT repeat full domain detection. Instead:
1. Identify which teams are relevant to the applied fixes (e.g., if dependency order changed, re-spawn T1 and T2; if security fix applied, re-spawn T8)
2. Skip to STEP 1c — spawn only the relevant subset of teams with the UPDATED plan content
3. Continue from STEP 2

If a re-review surfaces NEW issues not present in the previous iteration, add them to the tracker and process them in STEP 4. New P0/P1 issues reset the fix cycle for this iteration but do NOT reset the iteration counter.

---

## STEP 5 — Finalize

### 5a. Write Updated Plan

If any fixes were applied, write the updated plan to the original file path.

### 5b. Generate Review Report

Build the report using `${CLAUDE_SKILL_DIR}/reference.md` § 6.

Determine verdict:
- **APPROVED** — all OPEN issues cleared (P0=0, P1=0, P2=0, P3=0 — every issue FIXED, ESCALATED, or WONTFIX)
- **NEEDS_REVISION** — unresolved OPEN issues still require another review loop or plan revision
- **BLOCKED** — external dependency or user decision prevents approval

### 5c. Report to User

Present:
1. **Verdict** (bold, prominent)
2. **Summary metrics** — iterations, teams spawned, issue counts by priority
3. **Issue tracker table** — full table with final statuses
4. **Pre-mortem** — from T1 Architecture team
5. **Next step**:
   - APPROVED → "Proceed to Step 3: Execute (TDD)"
   - NEEDS_REVISION → "Revise the plan and run Step 2 again"
   - BLOCKED → "Resolve listed P0/P1 issues before proceeding"

**Step output:** review report presented to user, updated plan on disk.

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>review-plan(brief summary of verdict)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `APPROVED` — plan is sound, proceed to execution
- `NEEDS_REVISION` — specific issues must be addressed
- `BLOCKED` — external dependency or missing information

[HARD] NEVER report "DONE" for plan review — use the three verdict codes above.
