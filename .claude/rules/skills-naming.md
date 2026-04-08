# Skills Naming Convention

## Dispatcher Pattern

- The primary entry point is the parent `omb` dispatcher skill
- Users invoke `/omb <subcommand> [args]` (e.g., `/omb plan my feature`)
- The dispatcher routes to sub-skills via `Skill("<target>")`
- Sub-skills are also directly invocable via colon-namespace: `/omb:<skill-name>`

## Skill Namespace

- Plugin name is `omb` (in `.claude-plugin/plugin.json`)
- Skills use the `omb:` colon-namespace (plugin-level auto-namespacing)
- Parent dispatcher: `skills/omb/SKILL.md` → `/omb`
- Sub-skills: `skills/omb-<name>/SKILL.md` → `omb-<name>` (directly invocable)
- lc-* reference skills: `skills/lc-<name>/SKILL.md` → `/omb:lc-<name>`

## Dual Access Pattern

Sub-skills support two invocation methods:
1. **Via dispatcher**: `/omb plan my feature` (natural language routing)
2. **Direct colon-namespace**: `/omb:plan my feature` (explicit invocation)

## Naming Rules

- Directory names: kebab-case, lowercase, max 64 characters
- Sub-skill directories: `omb-` prefix required (e.g., `omb-create-plan`, `omb-review-plan`)
- Skill `name` field matches the directory name (e.g., `name: omb-create-plan`)
- Use hyphens for multi-word names: `omb-create-plan`, `omb-review-plan`

## Description Convention (CSO Doctrine)

- Description field starts with "Use when..." — trigger conditions only
- No implementation details, workflow steps, or internal mechanics in the description
- Max ~1024 characters; keep under 200 for budget efficiency
- Third person voice: "Generates..." not "I generate..."

## Available Skills

### Parent Dispatcher

| Skill | Invocation | Description |
|-------|-----------|-------------|
| `omb` | `/omb <subcommand>` | Unified dispatcher — routes subcommands to sub-skills |

### Subcommand Routing Table

| Subcommand | Aliases | Target Sub-Skill | Direct Invocation | Description |
|------------|---------|------------------|-------------------|-------------|
| `plan` | `create-plan` | `omb-create-plan` | `omb-create-plan` | Planning workflow — intent analysis, brainstorming, plan generation |
| `review` | `review-plan`, `critique` | `omb-review-plan` | `omb-review-plan` | Multi-agent plan review — P0-P3 issue tracking, fix loops |
| `exec` | `execute`, `implement` | `omb-execute` | `omb-execute` | Plan execution — TDD agents, dependency-aware wave scheduling |
| `run` | `run-pipeline`, `run-session` | `omb-run` | `omb-run` | Run a pipeline session to completion |
| `verify` | `check`, `test` | `omb-verify` | `omb-verify` | Verification — parallel verifier agents, evidence collection |
| `doc` | `document`, `docs` | `omb-document` | `omb-document` | Documentation generation — parallel doc-writer agents |
| `pr` | `create-pr`, `ship` | `omb-create-pr` | `omb-create-pr` | PR creation — plan traceability, checklist, gh CLI |
| `prompt-guide` | `prompt` | `omb-prompt-guide` | `omb-prompt-guide` | Prompt engineering reference (P1-P8) |
| `react` | `react-best-practices` | `omb-react-best-practices` | `omb-react-best-practices` | React quality checklist — hooks, a11y, performance, TypeScript |
| `interview` | `requirements`, `gather` | `omb-interview` | `omb-interview` | Requirements gathering via multi-round AskUserQuestion |
| `design` | `web-design`, `web-design-guidelines` | `omb-web-design-guidelines` | `omb-web-design-guidelines` | Design system reference — visual identity, typography, color, motion |
| `feedback` | `report`, `issue` | `omb-feedback` | `omb-feedback` | Feedback submission — GitHub issues via gh CLI or browser URL |
| `loop` | `run-loop` | `omb-loop` | `omb-loop` | Recurring task loop — interval execution with sub-pipeline support |
| `release` | `publish`, `tag`, `version` | `omb-release` | `omb-release` | Release pipeline — version bump, changelog, tag, build, push |
| `task` | `init-pipeline`, `create-pipeline`, `new-pipeline`, `new-session` | `omb-task` | `omb-task` | Initialize pipeline from pre-made templates or interactive Manual mode |
| `setup` | `init`, `initialize`, `configure`, `init-survey`, `init-project`, `setup-project`, `setup-claude`, `survey` | `omb-setup` | `omb-setup` | First-time setup — user profile, Slack config, Codex plugin, CLAUDE.md + PROJECT.md generation |
| `cleanup` | `clean`, `tidy` | `omb-cleanup` | `omb-cleanup` | Clean up stale session state and exit worktrees safely |
| `resolve-issue` | `fix-issues`, `auto-fix` | `omb-resolve-issue` | `omb-resolve-issue` | Resolve open GitHub issues via parallel worktree pipelines |
| `review-pr` | `pr-review` | `omb-review-pr` | `omb-review-pr` | Review a PR with multi-agent analysis |
| `codex-review` | `cr` | `omb-codex-review` | `omb-codex-review` | Codex code review against local git state |
| `codex-adversarial-review` | `car` | `omb-codex-adversarial-review` | `omb-codex-adversarial-review` | Adversarial Codex review |
| `codex-rescue` | `rescue` | `omb-codex-rescue` | `omb-codex-rescue` | Delegate to Codex rescue subagent |
| `codex-setup` | `codex-init` | `omb-codex-setup` | `omb-codex-setup` | Check Codex CLI readiness |
| `codex-status` | `codex-jobs` | `omb-codex-status` | `omb-codex-status` | Show Codex job status |
| `codex-result` | — | `omb-codex-result` | `omb-codex-result` | Show finished Codex job output |
| `codex-cancel` | — | `omb-codex-cancel` | `omb-codex-cancel` | Cancel active Codex job |

### Codex Internal Skills (reference-only, `user-invocable: false`)

| Skill | Directory | Description |
|-------|-----------|-------------|
| `codex-cli-runtime` | `skills/codex-cli-runtime/` | Internal runtime contract for calling codex-companion from Claude Code |
| `codex-result-handling` | `skills/codex-result-handling/` | Internal guidance for presenting Codex output to the user |
| `gpt-5-4-prompting` | `skills/gpt-5-4-prompting/` | Internal guidance for composing GPT-5.4 prompts for Codex tasks |

### LangChain/LangGraph Reference Skills (unchanged)

| Skill | Invocation | Description |
|-------|-----------|-------------|
| `lc-framework-selection` | `/omb:lc-framework-selection` | Framework decision guide — LangChain vs LangGraph vs Deep Agents |
| `lc-langchain-deps` | `/omb:lc-langchain-deps` | Package versions, installation, environment setup |
| `lc-langchain-fundamentals` | `/omb:lc-langchain-fundamentals` | create_agent(), @tool, middleware, structured output |
| `lc-langchain-middleware` | `/omb:lc-langchain-middleware` | HITL middleware, Command resume, custom hooks |
| `lc-langchain-rag` | `/omb:lc-langchain-rag` | RAG pipeline: loaders, splitters, embeddings, vector stores |
| `lc-langgraph-fundamentals` | `/omb:lc-langgraph-fundamentals` | StateGraph, nodes, edges, Command, Send, streaming |
| `lc-langgraph-persistence` | `/omb:lc-langgraph-persistence` | Checkpointers, thread_id, time travel, Store |
| `lc-langgraph-hitl` | `/omb:lc-langgraph-hitl` | interrupt(), Command(resume), approval/validation workflows |
| `lc-deep-agents-core` | `/omb:lc-deep-agents-core` | create_deep_agent(), harness, SKILL.md format |
| `lc-deep-agents-memory` | `/omb:lc-deep-agents-memory` | StateBackend, StoreBackend, FilesystemMiddleware |
| `lc-deep-agents-orchestration` | `/omb:lc-deep-agents-orchestration` | SubAgentMiddleware, TodoList, HITL interrupts |
