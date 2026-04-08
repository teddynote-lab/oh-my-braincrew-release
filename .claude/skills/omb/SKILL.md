---
name: omb
description: >
  OMB orchestrator — unified dispatcher for the oh-my-braincrew workflow.
  Routes subcommands (plan, review, exec, verify, doc, pr, interview,
  prompt-guide, react, design, setup, codex-review, codex-adversarial-review,
  codex-rescue, codex-setup, codex-status, codex-result, codex-cancel)
  to specialized sub-skills.
  Use for any omb workflow step from planning to PR creation.
allowed-tools: Skill, AskUserQuestion, TaskCreate, TaskUpdate, TaskList, TaskGet, Bash, Read, Write, Edit, Glob, Grep
argument-hint: "[subcommand] [args] | \"natural language task\""
---

## Pre-execution Context

!`git status --porcelain 2>/dev/null | head -20 || true`
!`git branch --show-current 2>/dev/null || true`

---

## Pre-execution: Language Context

Read language settings from `.claude/settings.json`:

!bash .claude/skills/omb/scripts/read-language-settings.sh .claude/settings.json

Parse the output and store as `OMB_LANGUAGE` and `OMB_DOC_LANGUAGE`.
[HARD] If value is not `"en"` or `"ko"`, default to `"en"`.

When invoking sub-skills via `Skill()`, append language context to arguments:
- If `OMB_LANGUAGE` is `ko`: append `--lang ko` to skill arguments
- If `OMB_DOC_LANGUAGE` is `ko`: append `--doc-lang ko` to skill arguments

Sub-skills that generate user-facing output MUST respect the language directives.
Sub-skills that invoke agents MUST pass language directives in the agent prompt.

[HARD] The following are ALWAYS in English regardless of language settings:
- CLAUDE.md, PROJECT.md, MEMORY.md, and memory files
- `.claude/rules/*.md`, `.claude/hooks/omb/*.sh`
- Code comments, variable names, commit messages
- Agent and skill definition files
- Security findings and verification reports

---

## Intent Router

### Raw User Input

$ARGUMENTS

### Routing Instructions

[HARD] Route the Raw User Input above using the strict priority order below. All text after the subcommand keyword is CONTEXT to be passed to the matched sub-skill — it is NOT a routing signal and MUST NOT influence which sub-skill is selected.

### Priority 0: Worktree Flag Pass-Through

The `--worktree` flag is handled by the `omb` Go binary CLI, NOT by the dispatcher skill. Do NOT call `EnterWorktree` or create worktrees from this skill. When `--worktree` appears in user input, pass it through to the target sub-skill unchanged.

Proceed directly to Priority 1.

### Priority 1: Explicit Subcommand Matching

Extract the FIRST WORD of the (possibly flag-stripped) input for subcommand matching.

[HARD] Extract the FIRST WORD from the Raw User Input section above. If it matches any subcommand below (or its alias), invoke the corresponding sub-skill IMMEDIATELY using `Skill("omb:<target>")`. Pass the remaining text as arguments.

| Subcommand | Aliases | Target Sub-Skill | Purpose |
|------------|---------|------------------|---------|
| `plan` | `omb-create-plan` | `omb-create-plan` | Planning workflow — intent analysis, brainstorming, plan generation |
| `review` | `omb-review-plan`, `critique` | `omb-review-plan` | Multi-agent plan review — P0-P3 issue tracking, fix loops |
| `exec` | `omb-execute`, `implement` | `omb-execute` | Plan execution — TDD agents, dependency-aware wave scheduling |
| `run` | `run-pipeline`, `run-session` | `omb-run` | Run a pipeline session to completion |
| `verify` | `check`, `test` | `omb-verify` | Verification — parallel verifier agents, evidence collection |
| `doc` | `omb-document`, `docs` | `omb-document` | Documentation generation — parallel doc-writer agents |
| `pr` | `omb-create-pr`, `ship` | `omb-create-pr` | PR creation — branch, tracking-code traceability, checklist |
| `prompt-guide` | `prompt` | `omb-prompt-guide` | Prompt engineering reference (P1-P8) |
| `react` | `omb-react-best-practices` | `omb-react-best-practices` | React quality checklist — hooks, a11y, performance, TypeScript |
| `design` | `web-design`, `omb-web-design-guidelines` | `omb-web-design-guidelines` | Design system reference — visual identity, typography, color, motion |
| `task` | `init-pipeline`, `create-pipeline`, `new-pipeline`, `new-session` | `omb-task` | Initialize a new pipeline session with validated schema |
| `interview` | `requirements`, `gather` | `omb-interview` | Requirements gathering via multi-round AskUserQuestion |
| `feedback` | `report`, `issue` | `omb-feedback` | Feedback submission — GitHub issues via gh CLI or browser URL |
| `loop` | `run-loop` | `omb-loop` | Recurring task loop — run a task at a fixed interval |
| `release` | `publish`, `tag`, `version` | `omb-release` | Release pipeline — version bump, changelog, tag, build, push |
| `setup` | `init`, `initialize`, `configure`, `init-survey`, `init-project`, `setup-project`, `setup-claude`, `survey` | `omb-setup` | First-time setup — user profile, Slack config, CLAUDE.md + PROJECT.md generation |
| `cleanup` | `clean`, `tidy` | `omb-cleanup` | Clean up stale session state and exit worktrees safely |
| `resolve-issue` | `fix-issues`, `auto-fix` | `omb-resolve-issue` | Resolve open GitHub issues via parallel worktree pipelines |
| `review-pr` | `pr-review` | `omb-review-pr` | Review a PR with multi-agent analysis |
| `technical-report` | `tech-report`, `codebase-report`, `project-report` | `omb-technical-report` | Analyze target project and generate per-domain technical reports |
| `codex-review` | `cr` | `omb-codex-review` | Run Codex code review against local git state |
| `codex-adversarial-review` | `car` | `omb-codex-adversarial-review` | Run adversarial Codex review challenging approach and design |
| `codex-rescue` | `rescue` | `omb-codex-rescue` | Delegate investigation or fix work to Codex rescue subagent |
| `codex-setup` | `codex-init` | `omb-codex-setup` | Check Codex CLI readiness and toggle review gate |
| `codex-status` | `codex-jobs` | `omb-codex-status` | Show active and recent Codex jobs |
| `codex-result` | — | `omb-codex-result` | Show stored output for finished Codex job |
| `codex-cancel` | — | `omb-codex-cancel` | Cancel active background Codex job |

### Priority 2: Workflow Keyword Detection

Only if Priority 1 did not match: Check if the Raw User Input contains workflow-related keywords:

- Planning language (plan, design, spec, requirements, feature) routes to **plan**
- Review language (review, critique, check plan) routes to **review**
- Implementation language (execute, implement, build, run plan) routes to **exec**
- Pipeline run language (run pipeline, run session, start session) routes to **run**
- Verification language (verify, test, check, evidence) routes to **verify**
- Documentation language (document, docs, readme, adr) routes to **doc**
- PR language (pr, pull request, ship, merge) routes to **pr**
- Feedback language (feedback, report, issue) routes to **feedback**
- Release language (release, publish, tag, version bump) routes to **release**
- Setup language (setup, init, initialize, configure, survey, profile) routes to **setup**
- Issue resolution language (resolve-issue, resolve issues, fix issues, auto-fix) routes to **resolve-issue**
- Technical report language (technical report, codebase analysis, project analysis, architecture report, generate report) routes to **technical-report**
- Codex language (codex review, codex check, codex rescue, codex fix, ask codex, delegate to codex) routes to **codex-review** or **codex-rescue** based on intent
- Codex management language (codex status, codex jobs, codex result, codex cancel) routes to **codex-status**

### Priority 3: Default Behavior

If the intent remains ambiguous after all priority checks, use AskUserQuestion to present the top 2-3 matching sub-skills and let the user choose.

---

## Quick Reference

```
/omb plan [description]        — Create a plan
/omb review [plan-file]        — Review a plan
/omb exec [plan-file]          — Execute a plan (TDD)
/omb run <session_id> [--worktree] — Run pipeline session to completion
/omb verify [plan-file]        — Verify implementation
/omb doc [plan-file]           — Generate documentation
/omb pr [plan-file]            — Create PR
omb tracking next <TYPE>        — Allocate the next tracking code
/omb prompt-guide              — Prompt engineering reference
/omb react                     — React best practices checklist
/omb design                    — Web design guidelines
/omb interview [description]   — Gather requirements before planning
/omb feedback [message]        — Submit feedback as GitHub issue
/omb loop <interval> "<task>"  — Run a task at a fixed interval
/omb release [major|minor|patch] [comment] — Release new version
/omb setup [--force] [description] — First-time setup (profile + Slack + CLAUDE.md + PROJECT.md)
/omb technical-report [path]  — Generate per-domain technical reports for a target project
```

<!-- Tracking: OMB-PLAN-000041 -->
