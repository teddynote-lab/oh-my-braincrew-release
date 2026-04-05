---
name: omb-document
user-invocable: true
description: >
  Use when documenting completed work, updating README, creating ADRs, generating
  API docs, or running Step 5 of the omb workflow. Triggers on: "document",
  "write docs", "update docs", "create ADR", "document this", "update README",
  "generate docs", "write documentation", or after execution completes and user
  says "document it", "write it up", "add docs". Spawns parallel doc-writer agents
  for each documentation type needed. Do NOT use for planning (use
  omb-create-plan) or executing code (use omb-execute).
argument-hint: "[plan-file-path or execution-log-path]"
allowed-tools: Read, Write, Bash, Grep, Glob, Agent, AskUserQuestion
---

# Documentation Workflow

Generate documentation for completed work by detecting documentation types needed and spawning parallel doc-writer agents.

<references>
- `${CLAUDE_SKILL_DIR}/reference.md` § 1 — doc type detection rules
- `${CLAUDE_SKILL_DIR}/reference.md` § 2 — agent prompt templates
- `${CLAUDE_SKILL_DIR}/reference.md` § 3 — documentation templates
- `${CLAUDE_SKILL_DIR}/reference.md` § 4 — docs/ folder structure and routing rules
- `${CLAUDE_SKILL_DIR}/reference.md` § 5 — incremental update rules
- `${CLAUDE_SKILL_DIR}/reference.md` § 6 — document record template
- `${CLAUDE_SKILL_DIR}/reference.md` § 7 — README section detection and update rules
- `.claude/rules/05-documentation.md` — documentation types and requirements
</references>

<completion_criteria>
The documentation is complete when ALL of these hold:
- Every detected doc type has been generated or explicitly skipped
- Document record written to `.omb/documents/`
- verify-docs.sh passes with no failures
- User presented with summary and next step recommendation

Status codes: COMPLETE | PARTIAL | FAILED
</completion_criteria>

<ambiguity_policy>
- No plan file provided and no recent execution: ask user via AskUserQuestion
- Detection script identifies doc types but user disagrees: respect user override, update detection
- doc-writer agent returns NEEDS_CONTEXT: pause that doc type, continue others, report gaps
- README update would change >30% of file: present diff to user for approval
- No code changes detected (plan-only): generate document record with planning notes only
</ambiguity_policy>

<scope_boundaries>
This skill generates documentation — it does NOT:
- Create or modify plans (use omb-create-plan)
- Execute code (use omb-execute)
- Run verification step (Step 4)
- Modify application source code
- Make architecture decisions
- Create PRs (Step 6)
</scope_boundaries>

<anti_patterns>
- Documenting without reading the actual code — produces inaccurate docs that mislead developers
- Rewriting entire README instead of updating sections — destroys existing content and creates merge conflicts
- Skipping document record creation — breaks audit trail between plans and their documentation
- Generating all 12 doc types when only 2 are needed — wastes agent budget and creates noise
- Writing documentation for unverified code — Step 4 must pass before Step 5; documenting broken code is worse than no docs
- Spawning doc-writer agents sequentially when they can run in parallel — wastes time without quality gain
</anti_patterns>

<examples>
<example type="positive" label="Filled doc-writer prompt for README update">
Plan: BC-PLAN-000042, Doc Type: readme, Target Path: README.md
Operation: UPDATE, Audience: developer, Stack Layer: backend-python
Code Context: "Added POST /api/auth/refresh (src/api/auth.py), JWT middleware (src/middleware/jwt.py), Redis token store (src/cache/tokens.py)"

Result: Agent reads current README, identifies "## API" and "## Quick Start" sections, updates only those two sections, preserves all others untouched.
</example>
<example type="negative" label="Bad: empty code context">
Plan: BC-PLAN-000042, Doc Type: readme, Target Path: README.md
Code Context: ""

Result: Agent writes generic placeholders ("This project has authentication features") that don't match actual implementation. Inaccurate docs mislead developers.
Fix: Always provide code context from Step 2.
</example>
</examples>

---

## STEP 0 — Locate Source Context

1. Parse `$ARGUMENTS` for plan file path or execution log path.

2. If no path provided:
   ```bash
   ls -t .omb/plans/*.md 2>/dev/null | head -5
   ```
   Also check for recent execution logs:
   ```bash
   ls -t .omb/executions/*.md 2>/dev/null | head -5
   ```
   Ask the user which plan/execution to document via `AskUserQuestion`.

3. Locate the plan file and its corresponding execution log:
   - If given a plan path: look for execution log at `.omb/executions/{same-filename}.md`
   - If given an execution log: extract plan file path from the log's Metadata section

4. Read the plan file. Extract:
   - Tracking code (pattern: `[A-Z]{2,6}-PLAN-\d{6}`)
   - Architecture Decisions section (if present)
   - Tasks table (to understand what was built)
   - Verification Criteria section

5. Read the execution log (if exists). Extract:
   - Files created and modified (Changes table)
   - Per-task summaries
   - Status (COMPLETE/PARTIAL/FAILED)

6. Ensure documentation directory exists:
   ```bash
   mkdir -p .omb/documents
   ```

**Step output:** Plan content read. Execution context loaded. Tracking code extracted. Documentation directory created.

---

## STEP 1 — Detect Documentation Types Needed

1. Run the detection script:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/detect-doc-types.sh <plan-file-path> [execution-log-path]
   ```
   Capture the JSON output.

2. Parse the JSON result. The script outputs a JSON object mapping doc types to `{needed: bool, reason: string}` for these categories:
   - `readme` — README updates needed
   - `adr` — Architecture Decision Records needed
   - `api` — API documentation needed
   - `db` — Database documentation needed
   - `architecture` — Architecture diagrams/docs needed
   - `guides` — Setup/deployment/migration guides needed
   - `langchain` — LangChain/LangGraph workflow docs needed
   - `frontend` — Frontend component docs needed
   - `electron` — Electron-specific docs needed
   - `infra` — Infrastructure/CI/CD docs needed
   - `testing` — Test strategy/coverage docs needed
   - `security` — Security model/audit docs needed
   - `prompts` — Prompt documentation needed
   - `document_record` — Always true (audit trail)

3. If `readme` is `needed` and `readme.languages` array is non-empty, note the language variants. These will be handled automatically in STEP 3 — no separate user confirmation needed.

4. Present detected types to user:
   ```
   Documentation types detected:
   - README update (reason: new API endpoints added)
     - Includes translation: README.ko.md (Korean) [if languages detected]
   - ADR (reason: architecture decision in plan)
   - API docs (reason: FastAPI routes modified)
   - Document record (always generated)

   Proceed with these? Override any? [y/override/skip]
   ```
   Use `AskUserQuestion` for confirmation.

5. Apply user overrides if any.

**Step output:** List of doc types to generate, confirmed by user. Each type has a reason string for context.

---

## STEP 2 — Read Changed Files for Code Context

1. Collect all file paths from the execution log's Changes table.

2. For each file (up to 20 files):
   - Read the file to understand its current implementation
   - Note key exports, functions, classes, API endpoints

3. If no execution log exists:
   - Use `Grep` to find files containing the tracking code
   - Read those files instead

4. Build a code context summary: a concise map of what was built, organized by stack layer.

5. Scan existing documentation in `docs/` for files that may need updates:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/detect-doc-types.sh <plan-file-path> [execution-log-path] \
     | bash ${CLAUDE_SKILL_DIR}/scripts/detect-existing-docs.sh
   ```
   Parse the JSON output. For each doc type with a non-empty array, set `{OPERATION}` to `UPDATE` and `{TARGET_PATH}` to the existing file path (instead of generating a new filename).

6. For doc types where `docs/{type}/` does not exist but documentation is needed, the doc-writer agent will create the directory with `mkdir -p` before writing.

**Step output:** Code context summary as structured text: one section per stack layer (backend, frontend, DB, infra), each listing files changed, key exports/classes/endpoints, and their purpose. Existing docs inventory per type (paths of files needing updates vs. new directories to create). This feeds directly into doc-writer agent prompts as `{CODE_CONTEXT}`.

---

## STEP 3 — Spawn Doc-Writer Agents in Parallel

For each documentation type marked as needed:

1. Build the doc-writer agent prompt using templates from `${CLAUDE_SKILL_DIR}/reference.md` § 2.

2. Fill placeholders:
   - `{DOC_TYPE}` — the documentation category
   - `{TRACKING_CODE}` — from plan
   - `{PLAN_CONTEXT}` — architecture decisions, task descriptions
   - `{CODE_CONTEXT}` — code summary from STEP 2
   - `{TARGET_PATH}` — where the doc should be written (see § 4 routing rules)
   - `{TEMPLATE}` — the doc template from § 3
   - `{OPERATION}` — NEW or UPDATE (based on whether target file exists)
   - `{AUDIENCE}` — developer, operator, or end-user (inferred from doc type)
   - `{STACK_LAYER}` — which layer the change affects (backend-python, frontend-react, etc.)

2b. For doc types where existing docs were found in `docs/` (from STEP 2 scan):
   - Set `{OPERATION}` to `UPDATE`
   - Set `{TARGET_PATH}` to the existing file path
   - Add `{EXISTING_DOC_HEADERS}` (the `##` headers from the existing file) so the agent knows the current structure and can merge incrementally

2c. For doc types where `docs/{type}/` directory does not exist:
   - Set `{OPERATION}` to `NEW`
   - Include `mkdir -p docs/{type}` in the agent instructions (before writing the file)

3. For ADR docs: determine the next ADR number:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/next-adr-number.sh
   ```
   Include the number in the prompt.

4. Invoke the `Agent` tool for ALL doc types **in a single parallel batch** — one call per doc type.
   - Set `subagent_type: "doc-writer"` for standard docs (matches `.claude/agents/omb/doc-writer.md`)
   - For ADR docs: use `model: "sonnet"` (architecture reasoning needs more capability)
   - For all others: use `model: "haiku"`

5. For README updates specifically:
   - Agent reads the full current README first — overwriting unseen content destroys existing docs and creates merge conflicts
   - Agent uses incremental update rules from § 5 — full rewrites destroy content from other plans
   - If update would change >30% of README, agent returns the diff for user approval — large rewrites often accidentally delete existing content

6. For README i18n variants (when `readme.languages` array is non-empty):
   - Invoke one additional `Agent` call with `subagent_type: "doc-writer"` per language variant in the SAME parallel batch
   - Each translation agent uses the "README i18n Translation Template" from `${CLAUDE_SKILL_DIR}/reference.md` § 2
   - Placeholders:
     - `{DOC_TYPE}`: `readme-i18n`
     - `{TARGET_PATH}`: `README.{lang}.md` (e.g., `README.ko.md`)
     - `{TARGET_LANGUAGE}`: language name (e.g., "Korean" for "ko")
     - `{LANG_CODE}`: the code (e.g., "ko")
     - `{SOURCE_README_PATH}`: `README.md`
     - Same `{CODE_CONTEXT}` and `{PLAN_CONTEXT}` as the primary README agent
   - Model: `haiku`

**Step output:** All doc-writer agents spawned in parallel, including i18n translation agents for README variants. Existing docs targeted for UPDATE rather than NEW where applicable. Each agent will write its documentation file directly.

---

## STEP 4 — Collect and Validate Agent Outputs

For each completed doc-writer agent:

1. Parse the output for STATUS, files created/modified, summary.

2. Validate:
   - `DONE` — doc file exists at expected path, non-empty
   - `DONE_WITH_CONCERNS` — doc file exists, log concerns
   - `NEEDS_CONTEXT` — log what's missing, mark doc type as SKIPPED
   - `BLOCKED` — log blocker, mark doc type as SKIPPED

2b. For i18n README agents: validate that `README.{lang}.md` exists and was updated. Check that the section count (number of `##` headers) matches the English README to ensure structural parity.

3. For README updates that flagged >30% change:
   - Present the diff to user via `AskUserQuestion`
   - If approved: write the update
   - If rejected: mark as SKIPPED with reason

4. Track results per doc type.

**Step output:** All agent outputs collected. Per-type status tracked (DONE, SKIPPED, FAILED).

---

## STEP 5 — Write Document Record

Write the document record to `.omb/documents/{plan-filename}.md` using the template from `${CLAUDE_SKILL_DIR}/reference.md` § 6.

The document record includes:
- Metadata: plan file, tracking code, timestamp, documenter
- Documentation generated: list of doc types with file paths and status
- Code context summary: what was documented
- Skipped types: what was skipped and why
- i18n README entries are included as separate rows in the "Documentation Generated" table:
  `| N | README (ko) | README.ko.md | DONE | Korean translation of updated sections |`

Use the `Write` tool to create the record file.

**Step output:** Document record written to `.omb/documents/{plan-filename}.md`.

---

## STEP 6 — Verify Documentation

1. Run the verification script:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/verify-docs.sh <tracking-code>
   ```

2. Parse the JSON output for pass/fail/warnings.

3. If any failures:
   - For missing files: check if agent wrote to wrong path, attempt to locate and move
   - For broken links: fix relative links in the doc files
   - Re-run verification after fixes

4. Report results:
   ```
   Documentation verification: 4/5 passed, 1 warning
   ```

**Step output:** All doc files verified. Count reported.

---

## STEP 7 — Report to User

Present the documentation summary:

### If COMPLETE:
```
**Documentation COMPLETE**
- Doc types generated: {N}
- Files created/updated: {N}
- Document record: .omb/documents/{filename}.md

Next step: Proceed to Step 6: Create PR (`/omb pr` or delegate to `git-master`)
```

### If PARTIAL:
```
**Documentation PARTIAL**
- Doc types generated: {completed}/{total}
- Skipped: {list with reasons}
- Document record: .omb/documents/{filename}.md

{skipped} doc types need attention. Review the document record for details.
Next step: Address skipped docs or proceed to Step 6: Create PR
```

### If FAILED:
```
**Documentation FAILED**
- No documentation could be generated
- Document record: .omb/documents/{filename}.md

Review the document record for error details.
```

**Step output:** User receives documentation summary with status, counts, record path, and explicit next step recommendation.

## Completion Signal

[HARD] You MUST emit this XML block as your FINAL output:

```
<omb>
<task>document(brief summary of outcome)</task>
<decision>STATUS</decision>
</omb>
```

Decision values for this skill:
- `DONE` — completed successfully
- `DONE_WITH_CONCERNS` — completed with flagged issues
- `FAILED` — could not complete
- `NEEDS_CONTEXT` — missing information, cannot proceed
