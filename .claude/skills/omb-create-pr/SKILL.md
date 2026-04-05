---
name: omb-create-pr
user-invocable: true
description: >
  Use when creating a pull request, finalizing work for review, or running
  Step 6 of the omb workflow. Triggers on: "create pr", "make pr",
  "open pr", "submit pr", "ready for pr", "step 6", "ship it".
argument-hint: "[plan-file-path]"
allowed-tools: Read, Write, Bash, Grep, Glob, Agent, AskUserQuestion
---

# PR Creation Workflow

Create a pull request by locating the plan, creating a feature branch, generating a PR tracking code via `omb tracking next PR` linked to the original plan, detecting categories, collecting change summaries, building a PR body from template, validating the checklist, and delegating PR creation to `git-master`.

<references>
- `${CLAUDE_SKILL_DIR}/reference.md` § 1 — PR template (STANDARD and LIGHT tiers). Read in STEP 6 to build the PR body.
- `${CLAUDE_SKILL_DIR}/reference.md` § 2 — git-master agent prompt template. Read in STEP 8 to delegate PR creation.
- `${CLAUDE_SKILL_DIR}/reference.md` § 3 — category detection rules. Read in STEP 4 if `detect-pr-category.sh` output needs interpretation.
- `${CLAUDE_SKILL_DIR}/reference.md` § 4 — PR record state JSON schema. Read in STEP 9 to write the state file.
- `${CLAUDE_SKILL_DIR}/reference.md` § 5 — PR record template. Read in STEP 9 to write the record markdown.
- `${CLAUDE_SKILL_DIR}/reference.md` § 6 — checklist validation rules. Read in STEP 7 to interpret validation results.
- `.claude/rules/06-create-pr.md` — branch naming, conventional commits, merge strategy
</references>

<completion_criteria>
The PR creation is complete when ALL of these hold:
- Feature branch created (or already existed) — NOT on main/master
- PR tracking code generated via `omb tracking next PR` (format: `{PROJECT}-PR-{6digits}`)
- PR body filled from template with plan traceability (PLAN code → PR code chain)
- Plan Tasks table populated from the original plan's Tasks section
- Branch pushed and PR created via `gh pr create` OR PR body saved as markdown file
- PR record written to `.omb/prs/`
- User presented with PR URL or file path

Status codes: COMPLETE | PARTIAL | FAILED
</completion_criteria>

<ambiguity_policy>
- `gh` CLI not installed: save PR body to `.omb/prs/{PR_CODE}-body.md` with manual instructions
- `gh` CLI not authenticated: warn user, save PR body as markdown file fallback
- No verification record found: warn user "No verification evidence found — Step 4 not completed" via AskUserQuestion; if user proceeds, mark verification status as NOT RUN
- No execution log found: proceed with git diff as source of changes; log "No execution log — using git diff"
- Already on a feature branch: skip branch creation in STEP 2, use existing branch
- Already on main/master with uncommitted changes: stash → create branch → pop stash → proceed
- Already on main/master with committed changes not on remote: create branch from current HEAD (commits carry over)
- Existing open PR for branch: report existing PR URL and skip creation — do not create duplicate
- PR body exceeds 65536 chars: truncate Changes section to `git diff --stat` only, add note "Full changes in execution log: {path}"
</ambiguity_policy>

<scope_boundaries>
This skill creates PRs — it does NOT:
- Run full test suite management or write feature code (use omb-execute)
- Run verification (use omb-verify)
- Generate documentation (use omb-document)
- Create or modify plans (use omb-create-plan)
- Review plans (use omb-review-plan)
- Make architecture decisions

This skill DOES run local Python CI checks (ruff, pyright, pytest) as a pre-PR gate with auto-fix loop (max 3 retries). See STEP 7.5.
</scope_boundaries>

<anti_patterns>
- Creating a PR without first creating a feature branch — PRs must come from feature branches, never from main/master directly; STEP 2 must run before STEP 8
- Creating a PR without verification evidence (Step 4 not completed) — PRs without verification evidence ship untested code; always verify first or explicitly acknowledge the gap
- Missing plan traceability — every STANDARD PR must link back to its PLAN tracking code in the Tracking section; the PLAN→PR chain is the backbone of the omb workflow
- Skipping the Plan Tasks table — the template's Plan Tasks section maps plan tasks to deliverables; omitting it breaks reviewer traceability
- Skipping checklist validation — checklist catches secrets, non-conventional commits, and missing trailers that would fail review
- Hardcoding branch names or PR titles — always derive from plan context and git state
- Creating duplicate PRs for the same branch — always check `gh pr list --head {branch}` first
- Using `git push --force` without user confirmation — force pushes can overwrite upstream work
- Filling template sections with placeholder text ("TODO", "TBD") — empty sections should be omitted, not filled with noise
- Running this skill before Steps 3-5 are complete — the PR body depends on execution logs, verification records, and documentation status from prior steps
</anti_patterns>

<examples>
<example type="positive" label="Full STANDARD PR with branch creation and plan traceability">
Plan: BCRW-PLAN-000042 (auth middleware) in `.omb/plans/202603211045-abc123.md`.
STEP 0: Plan found, execution log found, verification record (PASS), document record (COMPLETE).
STEP 1: Tier = STANDARD.
STEP 2: On main → create branch `feature/add-auth-middleware` derived from plan title.
STEP 3: PR code generated via `omb tracking next PR`: BCRW-PR-000001. Linked to BCRW-PLAN-000042.
STEP 4: Categories: ["backend", "security"], primary: "security".
STEP 5: 12 files changed, 340 insertions, 45 deletions, 5 commits.
STEP 6: STANDARD template filled. Tracking table shows PLAN→PR chain. Plan Tasks table populated from plan's 9 tasks.
STEP 7: Checklist: all pass. gh authenticated.
STEP 8: git-master pushes `feature/add-auth-middleware`, `gh pr create` succeeds. PR URL: https://github.com/org/repo/pull/42.
STEP 9: PR record written to `.omb/prs/2026-03-21-BCRW-PLAN-000042.md`.
STEP 10: User sees PR URL + record path.
</example>
<example type="positive" label="Already on feature branch — skip branch creation">
Plan: BCRW-PLAN-000099 (redis pool fix). Already on branch `fix/redis-pool-exhaustion`.
STEP 2: Already on feature branch `fix/redis-pool-exhaustion` → skip branch creation.
STEP 3: PR code: BCRW-PR-000002. Linked to BCRW-PLAN-000099.
Proceeds normally from STEP 4 onward.
</example>
<example type="negative" label="Bad: PR created directly from main — unacceptable">
Plan: BCRW-PLAN-000042. Currently on main. Skill skips branch creation and pushes from main.
WHY BAD: PRs must come from feature branches. The skill MUST create a branch in STEP 2 before proceeding. Creating a PR from main pollutes the main branch history and prevents proper code review.
</example>
<example type="negative" label="Bad: PR without plan traceability — unacceptable">
Plan: BCRW-PLAN-000042. PR code generated but template omits plan tracking code.
WHY BAD: The traceability chain (PLAN→PR) is broken. Reviewers cannot trace the PR back to its plan. The Tracking section must always show both PLAN and PR codes.
</example>
<example type="negative" label="Bad: PR without Plan Tasks table — unacceptable">
Plan has 9 tasks. PR template filled but Plan Tasks section is empty or omitted.
WHY BAD: The Plan Tasks table is the reviewer's map from plan intent to delivered code. Without it, the reviewer must manually cross-reference the plan file.
</example>
<example type="positive" label="gh CLI fallback — saves PR body as markdown">
Plan: BCRW-PLAN-000099. Branch: fix/redis-pool-exhaustion.
STEP 7: Checklist warns: "gh CLI not authenticated".
STEP 8: Fallback. PR body written to `.omb/prs/BCRW-PR-000002-body.md`.
STEP 10: User sees: "PR body saved — create the PR manually on GitHub."
</example>
</examples>

---

## STEP 0 — Locate Plan and Load Upstream Artifacts

1. Parse `$ARGUMENTS` for plan file path.

2. If no path provided:
   ```bash
   ls -t .omb/plans/*.md 2>/dev/null | head -5
   ```
   Ask the user which plan to create a PR for via `AskUserQuestion`.

3. Ensure PR directories exist:
   ```bash
   mkdir -p .omb/prs/state
   ```

4. Read the plan file (if provided). Extract:
   - Tracking code (pattern: `[A-Z]{2,6}-PLAN-\d{6}`)
   - Plan title (first heading or text before tracking code)
   - Context section (what and why)
   - Architecture Decisions section
   - Tasks table (all rows — needed for Plan Tasks in template)

5. Locate upstream artifacts:
   - Execution log: `.omb/executions/{plan-filename}.md`
   - Execution state: `.omb/executions/state/{plan-filename}.json`
   - Verification record: `.omb/verifications/{plan-filename}.md`
   - Verification state: `.omb/verifications/state/{plan-filename}.json`
   - Document record: `.omb/documents/{plan-filename}.md`

6. Read upstream artifacts that exist. Extract:
   - From execution log: status, files changed summary, per-task completion status
   - From verification state: final status (PASS/FAIL/PARTIAL)
   - From document record: status (COMPLETE/PARTIAL)

7. If no verification record found: warn user via `AskUserQuestion`:
   > "No verification evidence found for this plan. Step 4 (Verify) was not completed. Proceed without verification? [y/N]"
   If user declines, abort.

**Step output:** Plan loaded with tracking code and tasks table. Upstream artifact statuses collected. PR directories created. Missing artifacts noted.

---

## STEP 1 — Determine PR Tier

1. If a plan file was provided and contains a tracking code → **STANDARD** tier
2. If no plan file (ad-hoc PR, trivial change) → **LIGHT** tier

3. Report tier to user:
   ```
   PR tier: STANDARD (plan: BCRW-PLAN-000042)
   ```
   or:
   ```
   PR tier: LIGHT (no plan reference — lightweight template)
   ```

**Step output:** PR tier determined (STANDARD or LIGHT). Tier gates template selection in STEP 6.

---

## STEP 2 — Create Feature Branch

This step ensures the PR comes from a feature branch, never from main/master directly.

1. Check current branch:
   ```bash
   git rev-parse --abbrev-ref HEAD
   ```

2. **If already on a feature branch** (not `main` or `master`):
   - Report: `Already on branch '{BRANCH}' — using existing branch.`
   - Skip to STEP 3.

3. **If on `main` or `master`** — create a new branch:

   a. **Determine branch type** from plan context:
      - Plan title or context contains "fix", "bug", "patch", "repair" → `fix/`
      - Plan title or context contains "hotfix", "urgent", "critical", "emergency" → `hotfix/`
      - Default → `feature/`

   b. **Derive branch slug** from plan title:
      - Strip the tracking code (e.g., remove `— BCRW-PLAN-000042`)
      - Lowercase, replace spaces and special characters with hyphens
      - Collapse consecutive hyphens, trim leading/trailing hyphens
      - Truncate to 50 characters
      - Example: "Add JWT Authentication to API" → `add-jwt-authentication-to-api`

   c. **Handle uncommitted changes:**
      ```bash
      git status --porcelain
      ```
      If uncommitted changes exist:
      ```bash
      git stash push -m "omb: stash before branch creation"
      ```

   d. **Create and switch to new branch:**
      ```bash
      git checkout -b {type}/{slug}
      ```

   e. **Restore stashed changes** (if stash was used):
      ```bash
      git stash pop
      ```

   f. Report:
      ```
      Branch created: {type}/{slug} (from plan: {PLAN_TITLE})
      ```

4. **For LIGHT tier** (no plan) on main/master:
   - Ask user for branch name via `AskUserQuestion`:
     > "You're on main. PRs need a feature branch. Enter a branch name (e.g., feature/my-change):"
   - Validate: must match branch naming convention from `.claude/rules/06-create-pr.md`
   - Create branch with the provided name.

**Step output:** On a feature branch. Branch name captured for template and git-master agent.

---

## STEP 3 — Generate PR Tracking Code

1. Run the tracking code generator:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/next-pr-code.sh
   ```

2. Capture the PR code (e.g., `BCRW-PR-000001`).

3. If the script fails:
   - Retry with `omb tracking next PR`
   - If `omb tracking next PR` also fails, report the error to the user and abort.

4. **Link PR code to plan tracking code** (STANDARD tier only):
   - Extract plan tracking code from STEP 0 (e.g., `BCRW-PLAN-000042`)
   - Store the pair: `{PR_CODE}` implements `{PLAN_CODE}`
   - This traceability chain appears in the PR template Tracking section

5. Report:
   ```
   PR code: BCRW-PR-000001 (implements plan: BCRW-PLAN-000042)
   ```
   or for LIGHT tier:
   ```
   PR code: BCRW-PR-000001 (ad-hoc — no plan)
   ```

**Step output:** PR tracking code generated. Traceability chain established: `{PLAN_CODE}` → `{PR_CODE}`.

---

## STEP 4 — Detect Change Categories

1. Run the category detection script:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/detect-pr-category.sh "{PLAN_FILE}" "{EXEC_STATE_PATH}"
   ```

2. Parse the JSON output for `categories` array and `primary` category.

3. If no categories detected: use git diff file extensions as fallback.

**Step output:** Categories detected: `{categories}`, primary: `{primary}`.

---

## STEP 5 — Analyze Changes

1. Run the change summary collector:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/collect-change-summary.sh
   ```

2. Parse the JSON output for files_changed, insertions, deletions, commits.

3. If execution log exists: read the Changes table and per-task summaries for richer context.

4. Build a concise change description organized by detected categories. For each category:
   - List the key files changed (include file paths)
   - Summarize what was added/modified/removed and why

5. **Map plan tasks to changes** (STANDARD tier only):
   - Cross-reference the plan's Tasks table (from STEP 0) with git diff and execution log
   - For each plan task, determine: Done (deliverable exists and tests pass), Partial (deliverable exists but incomplete), or Skipped (not addressed in this PR)
   - This mapping populates the Plan Tasks table in the template

**Step output:** Change summary collected. Category-organized change descriptions ready. Plan task mapping complete.

---

## STEP 6 — Generate PR Body

1. Read the template from `${CLAUDE_SKILL_DIR}/reference.md` § 1 based on tier:
   - STANDARD → full template with Tracking, Plan Tasks, and all sections
   - LIGHT → minimal template

2. Fill template placeholders:
   - **Tracking table:**
     - `{BCRW-PR-NNNNNN}` → PR code from STEP 3
     - `{BCRW-PLAN-NNNNNN}` → plan tracking code from STEP 0
     - Plan file path → from STEP 0
     - Branch → from STEP 2
   - **Category checkboxes** → check boxes for detected categories from STEP 4
   - **Summary** → derived from plan's Context section (what and scope)
   - **Motivation** → from plan's Context section (why it matters)
   - **Approach** → from plan's Architecture Decisions section
   - **Changes subsections** → only include subsections for checked categories, populated from STEP 5 with file paths
   - **Plan Tasks table** → from STEP 5 task mapping (task #, description, deliverable path, status)
   - **Test Plan** → from verification record or plan's Verification Criteria
   - **Verification Evidence** → status and path from STEP 0
   - **Documentation** → status per doc type from STEP 0
   - **Breaking Changes** → scan plan for "breaking" keyword, default to "None"
   - **Checklist** → will be validated in STEP 7

3. Build the PR title:
   - STANDARD: `type(scope): description` derived from plan title and primary category
     - Example: `feat(auth): add JWT refresh endpoint [BCRW-PLAN-000042]`
   - LIGHT: most recent commit message

4. If PR body exceeds 65536 characters:
   - Truncate the Changes section to `git diff --stat` output only
   - Add note: "Full changes available in execution log: `{path}`"

**Step output:** PR title and body generated as strings. Ready for validation and creation.

---

## STEP 7 — Validate Checklist

1. Run the checklist validator:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/validate-pr-checklist.sh
   ```

2. Parse the JSON output for per-check results.

3. Check `gh auth status`:
   - If `gh_auth` status is `warn`: note that PR will be saved as markdown fallback

4. If `no_secrets` status is `fail`:
   - Alert user via `AskUserQuestion`: "Potential secrets detected in changed files. Review before pushing. Continue? [y/N]"
   - If user declines, abort.

5. Report checklist summary:
   ```
   Checklist: 5 pass, 1 warn (gh_auth — will use markdown fallback)
   ```

**Step output:** Checklist validated. Per-check results stored. Blockers identified (if any).

---

## STEP 7.5 — Python CI Check (Pre-PR Gate)

[HARD] This step is mandatory. Do not skip.

1. Run the Python CI check script:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/check-python-ci.sh
   ```

2. Parse the JSON output. Display results:
   ```
   Python CI Check:
   - ruff_lint: pass
   - pyright_typecheck: fail (3 type errors found)
   - pytest_tests: pass
   ```

3. If ALL checks pass (exit code 0): proceed to STEP 8.

4. If ANY check fails (exit code 1):
   a. Display the failing checks with detail messages.
   b. Set `FIX_ATTEMPT = 0`, `MAX_FIX_ATTEMPTS = 3`.
   c. **Fix Loop:**
      - Increment `FIX_ATTEMPT`.
      - If `FIX_ATTEMPT > MAX_FIX_ATTEMPTS`: report failures and ask user via `AskUserQuestion`: "Python CI checks still failing after 3 fix attempts. Create PR anyway? [y/N]". If user says yes, proceed to STEP 8 with a warning. If no, abort.
      - Delegate to `executor` agent (sonnet): "Fix the following Python CI errors and commit the fixes:" + error details from check output.
      - After executor completes, re-run `check-python-ci.sh`.
      - If all pass: break loop, proceed to STEP 8.
      - If still failing: continue loop.

5. Display final check status:
   ```
   Python CI: PASS (all 3 checks passed)
   ```
   or
   ```
   Python CI: PASS after 2 fix attempts
   ```

**Step output:** Python CI checks passed (with fix attempt count if applicable). Ready to push.

---

## STEP 8 — Push Branch and Create PR

Branch already exists from STEP 2. This step pushes and opens the PR.

1. Determine base branch:
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
   ```

2. **Check for existing PR** on this branch:
   ```bash
   gh pr list --head {BRANCH_NAME} --json number,url 2>/dev/null
   ```
   If an open PR exists: report the URL and skip creation.

3. **Delegate to `git-master` agent** using the prompt template from `${CLAUDE_SKILL_DIR}/reference.md` § 2:
   - Fill the template with branch, base, PR code, plan code, plan filename, plan spec code, tier, title, and body
   - `{PLAN_FILENAME}` = basename of the plan file from STEP 0 (e.g., `2026-03-29-OMB-PLAN-000044.md`)
   - `{PLAN_SPEC_CODE}` = tracking code extracted in STEP 0 (e.g., `OMB-PLAN-000044`)
   - The agent handles: plan file staging, commit cleanup, push, `gh pr create`
   - If `gh` unavailable: agent writes PR body to `.omb/prs/{PR_CODE}-body.md`

4. Capture the result: PR URL or fallback file path.

**Step output:** PR created (URL) or PR body saved (file path). git-master agent status captured.

---

## STEP 9 — Write PR Record

1. Write PR state JSON to `.omb/prs/state/{plan-filename}.json` (STANDARD) or `.omb/prs/state/{pr-code}.json` (LIGHT).
   Use schema from `${CLAUDE_SKILL_DIR}/reference.md` § 4.
   Include `planCode` field linking PR to the original plan.

2. Write PR record markdown to `.omb/prs/{plan-filename}.md` (STANDARD) or `.omb/prs/{pr-code}.md` (LIGHT).
   Use template from `${CLAUDE_SKILL_DIR}/reference.md` § 5.

3. Include all collected data:
   - PR code, plan code, plan file reference, tier
   - Categories and change summary
   - Checklist results
   - Upstream record statuses (execution, verification, documentation)
   - PR URL or fallback file path
   - Full PR body in collapsible section

**Step output:** PR record written to `.omb/prs/`. State JSON written to `.omb/prs/state/`.

---

## STEP 10 — Report to User

### If COMPLETE (PR created via gh):
```
**PR Created**
- PR: {PR_URL}
- PR Code: {PR_CODE} (plan: {PLAN_CODE})
- Branch: {BRANCH} → {BASE_BRANCH}
- Categories: {CATEGORY_LIST}
- Changes: {FILES_CHANGED} files (+{INSERTIONS} -{DELETIONS})
- Plan Tasks: {N_DONE}/{N_TOTAL} done
- Record: .omb/prs/{filename}.md

Verification: {PASS/FAIL/PARTIAL/NOT RUN}
Documentation: {COMPLETE/PARTIAL/NOT RUN}
```

### If PARTIAL (gh fallback):
```
**PR Body Saved**
- File: .omb/prs/{PR_CODE}-body.md
- PR Code: {PR_CODE} (plan: {PLAN_CODE})
- Branch: {BRANCH}

gh CLI not available — create the PR manually on GitHub and paste the body content.
Record: .omb/prs/{filename}.md
```

### If FAILED:
```
**PR Creation Failed**
- Reason: {error description}
- Record: .omb/prs/{filename}.md

Review the PR record for details.
```

**Step output:** User receives PR summary with URL or fallback path, change stats, plan task completion, and upstream record statuses.

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>create-pr(brief summary of outcome)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `DONE` — completed successfully
- `DONE_WITH_CONCERNS` — completed with flagged issues
- `FAILED` — could not complete
- `NEEDS_CONTEXT` — missing information, cannot proceed
