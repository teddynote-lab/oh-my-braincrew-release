# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.4] - 2026-04-29

### Documentation
- tweak whitespace in prompt-evaluation note

### Maintenance
- Merge pull request #104 from teddynote-lab/fix/pyinstaller-missing-bin-resources
- apply ruff format to new regression tests



## [0.2.3] - 2026-04-29

### Maintenance
- Merge pull request #103 from teddynote-lab/fix/omb-init-bin-wrappers



## [0.2.2] - 2026-04-25

### Improved
- remove stub redirects after migration to common/
- restructure .claude/rules/ for progressive disclosure

### Documentation
- remove external attribution from coding-principles
- refresh 30_Constraints notes after rules restructure
- migrate rules paths and document agent rules: frontmatter

### Maintenance
- Merge pull request #102 from teddynote-lab/refactor/rules-stub-cleanup
- Merge pull request #101 from teddynote-lab/refactor/claude-rules-happy-blanket
- ruff format test_rules_contract.py



## [0.2.1] - 2026-04-21

### Fixed
- use canonical pipe form in omb-tag prose reference

### Improved
- remove guidance HTML comments from omb-setup CLAUDE.md template
- exclude 99_Settings/ registry from INDEX.md

### Documentation
- expand tags REGISTRY with 122 tech-spec tags

### Maintenance
- Merge pull request #98 from teddynote-lab/docs/wiki-tags-registry-expand
- Merge pull request #99 from teddynote-lab/refactor/omb-setup-claude-md-reactive-turtle
- accept slash-delimited prose in canonical status guard
- Merge pull request #97 from teddynote-lab/refactor/wiki-index-exclude-settings
- apply ruff format to test_wiki_index_rebuild.py



## [0.2.0] - 2026-04-21

### Added
- add DEV_NOTE PR-style template and body-structure rule
- add v2 schema foundation - ADR-003, 5 templates, 6 rules, vocab MOCs
- optimize omb-prompt-guide and omb-prompt-review for Claude 4.7

### Fixed
- tag validation bug + keywords/change-type rules
- remove 6 more orphan v1 skill tests
- remove orphan v1 tests and stale hook-conventions reference
- replace literal f-string placeholder in fact-43
- resolve verify CV-P1 findings

### Improved
- update 6 orchestrator skills + root docs for v2 paths
- v2 scripts, SKILL rewrite, hook + graph cleanup, content migration
- canonicalize omb status vocabulary

### Documentation
- update README + skills/agents/architecture for v2
- sync for PR #88 focus-ring rule
- sync wiki for status vocabulary canonicalization
- capture prompt-guide/evaluation/review 4.7 update
- replace placeholder with apps/web/src in fallback check

### Maintenance
- Merge pull request #96 from teddynote-lab/fix/wiki-vocab-tags-keywords
- apply ruff format
- Merge pull request #95 from teddynote-lab/feat/wiki-dev-note-template
- Merge pull request #94 from teddynote-lab/feat/wiki-v2-obsidian-native
- apply ruff format to 6 scripts/tests
- update path-script regression test for wiki-summary.sh rename
- add script tests + migrate sensitive-guard to @security-audit
- Merge pull request #91 from teddynote-lab/docs/wiki-sync-focus-ring
- regenerate graph.json post-merge
- merge origin/main — accept canonical fact-43 phrasing
- Merge pull request #92 from teddynote-lab/docs/wiki-status-vocabulary-sync
- update INDEX timestamps for SPEC and ADR-002 after merge
- merge main into docs/wiki-status-vocabulary-sync
- merge origin/main, regenerate INDEX and graph files
- Merge pull request #93 from teddynote-lab/docs/wiki-prompt-4-7-lessons
- extend placeholder skip in status vocabulary gate
- merge origin/main into docs/wiki-prompt-4-7-lessons
- Merge pull request #90 from teddynote-lab/refactor/canonicalize-status-vocabulary
- Merge pull request #89 from teddynote-lab/feat/prompt-guide-4-7-optimization
- apply ruff format to test_status_vocabulary.py
- Merge pull request #88 from teddynote-lab/feat/focus-ring-transient-yao



## [0.1.38] - 2026-04-20

### Improved
- integrate Karpathy coding principles across agents

### Documentation
- merge environment variables section

### Maintenance
- Merge pull request #87 from teddynote-lab/refactor/karpathy-coding-principles
- apply ruff format to assert_rubric_weights_sum_to_1.py



## [0.1.37] - 2026-04-20

### Maintenance
- Merge pull request #86 from teddynote-lab/refactor/omb-federated-peach



## [0.1.36] - 2026-04-20

### Maintenance
- Merge pull request #85 from teddynote-lab/fix/omb-update-preserve-user
- apply ruff format to fix bug fix



## [0.1.35] - 2026-04-19

### Documentation
- document update-gitignore subcommand and init step 9

### Maintenance
- Merge pull request #84 from teddynote-lab/feat/auto-gitignore-harness
- apply ruff format to gitignore migration code



## [0.1.34] - 2026-04-19

### Added
- self-evolving methodology-first feedback loop

### Fixed
- bundle omb-*-settings scripts into harness tarball

### Improved
- remove v1->v2 migration path - single-version clean init
- v1→v2 category restructure — core 7 + adaptive profiles

### Documentation
- seed code_convention and enforce lint contract

### Maintenance
- Merge pull request #83 from teddynote-lab/feat/omb-wiki-kind-boot
- apply ruff format to new feedback-loop tests
- preserve historical MIGRATE-V2 audit log line
- merge refactor/wiki-strip-v2 - remove v1->v2 migration path
- Merge pull request #82 from teddynote-lab/refactor/wiki-categories-v2
- apply ruff format to test_profile_detection
- Merge pull request #81 from teddynote-lab/fix/release-bundle-setup-scripts



## [0.1.33] - 2026-04-19

### Fixed
- narrow parse() return type for pyright in test_yaml_mini

### Documentation
- close §7 gaps — SKILL.md, wiki-reviewer, INDEX rebuild

### Maintenance
- Merge pull request #80 from teddynote-lab/feat/wiki-graphify-alignment
- untrack agent-memory/code-test, revert wiki build artifacts
- apply ruff format to graphify alignment files



## [0.1.32] - 2026-04-18

### Maintenance
- Merge pull request #79 from teddynote-lab/fix/release-patch-omb-cli-sh
- apply ruff format to release workflow test



## [0.1.31] - 2026-04-18

### Maintenance
- Merge pull request #78 from teddynote-lab/feat/omb-wiki-graph-integration
- untrack hypothesis test cache
- apply ruff format to new test and handler files
- merge main into feat/omb-wiki-graph-integration



## [0.1.30] - 2026-04-18

### Maintenance
- Merge pull request #77 from teddynote-lab/feat/omb-pr-preflight-conflict



## [0.1.29] - 2026-04-18

### Added
- sync main from remote after omb:clean teardown

### Fixed
- auto-route omb:fix and omb:plan in Plan Mode

### Improved
- remove AUTO-GENERATED markers from omb-setup template
- extract fix-writer section-structure into rule file

### Maintenance
- enable OMB_USE_CODEX in project settings
- Merge pull request #76 from teddynote-lab/feat/omb-clean-foamy-star
- Merge pull request #75 from teddynote-lab/chore/remove-deprecated-skills
- remove deprecated omb-deploy-vercel, omb-vercel-cli, omb-pgvector-search
- Merge pull request #74 from teddynote-lab/fix/omb-fix-plan-mode-support
- Merge pull request #73 from teddynote-lab/fix/codex-use-scope



## [0.1.28] - 2026-04-18

### Fixed
- preserve user hooks in omb-setup-settings merge

### Maintenance
- Merge pull request #72 from teddynote-lab/fix/setup-settings-array-merge
- ruff format test_omb_setup_settings.py



## [0.1.27] - 2026-04-18

### Fixed
- enforce canonical Section 3/4 in plan output + add plan-mode preflight

### Improved
- redesign CLAUDE.md v2 schema with 150-line cap

### Maintenance
- Merge pull request #71 from teddynote-lab/refactor/omb-setup-claude-md-v2
- resolve conflicts with main (SPEC.md/INDEX.md wiki)
- Merge pull request #70 from teddynote-lab/fix/omb-fix-plan-format
- Merge pull request #69 from teddynote-lab/fix/wiki-realpath-macos



## [0.1.26] - 2026-04-17

### Added
- display effort level from settings

### Documentation
- always run omb:wiki init, remove optional prompt

### Maintenance
- Merge pull request #68 from teddynote-lab/fix/codex-skills-preflight-127
- apply ruff format to test_codex_preflight.py



## [0.1.25] - 2026-04-16

### Maintenance
- Release v0.1.25


## [0.1.24] - 2026-04-15

### Added
- add /omb:fix skill for bug-fix plan authoring
- add centralized settings reader and gate Codex integration
- auto-install jq during omb init/update

### Fixed
- replace wiki-route-guard keywords to fix false positives
- resolve merge conflicts with main
- resolve merge conflict and drift gate precision
- add OMB_DEBUG trace logging for SKILL.md permission prompt diagnosis

### Maintenance
- Merge pull request #67 from teddynote-lab/feat/omb-fix-skill
- Merge pull request #66 from teddynote-lab/fix/skill-md-permission-prompt
- apply ruff format to test_permission_request
- Merge pull request #65 from teddynote-lab/feat/codex-settings-env
- resolve conflict with origin/main for cli.md frontmatter
- Merge pull request #64 from teddynote-lab/feat/auto-install-jq
- apply ruff format to new modules and tests
- ruff format test_update_command.py
- ruff format new files
- rephrase drift marker mentions in log prose



## [0.1.23] - 2026-04-15

### Maintenance
- Release v0.1.23


## [0.1.22] - 2026-04-14

### Maintenance
- Release v0.1.22


## [0.1.21] - 2026-04-14

### Maintenance
- Merge pull request #63 from teddynote-lab/fix/wiki-writer-routing



## [0.1.20] - 2026-04-14

### Added
- authoritative code-convention wiki + omb:run auto-load

### Fixed
- auto-approve all .claude/ writes including settings

### Maintenance
- inject wiki env defaults
- Merge pull request #62 from teddynote-lab/fix/claude-auto-approve-all
- Merge pull request #61 from teddynote-lab/feat/wiki-code-conventions
- apply ruff format to test_permission_request
- Merge pull request #60 from teddynote-lab/fix/ship-commands-in-releases
- apply ruff format to test_release_workflow.py



## [0.1.19] - 2026-04-14

### Added
- auto-inject wiki env defaults via omb init and /omb:wiki init

### Fixed
- force cron-status --all in omb-cron to prevent hidden jobs

### Documentation
- scaffold project blueprint wiki for monorepo

### Maintenance
- sync omb-release with README badge and content updates
- Merge pull request #59 from teddynote-lab/feat/snoopy-inventing-key
- apply ruff format to test_omb_wiki_settings.py



## [0.1.18] - 2026-04-14

### Added
- add omb:wiki blueprint wiki skill

### Improved
- split model rendering into Line 5 of statusline

### Documentation
- add omb:wiki core feature section

### Maintenance
- Merge pull request #56 from teddynote-lab/refactor/statusline-5line-layout
- sync main into statusline-5line-layout
- Merge pull request #58 from teddynote-lab/chore/ruff-format-fix
- apply ruff format to 4 python files
- Merge pull request #57 from teddynote-lab/feat/omb-wiki-skill
- apply ruff format to pass python-lint CI



## [0.1.17] - 2026-04-14

### Maintenance
- drop darwin/amd64 build, support darwin/arm64 only



## [0.1.16] - 2026-04-14

### Maintenance
- Release v0.1.16


## [0.1.15] - 2026-04-13

### Added
- add post-PR conflict and CI verification to omb-pr
- add omb:cron skill for scheduling Claude Code tasks
- add issue claim mechanism to omb-resolve-issue
- add omb init survey and Slack notification module
- add --bypass flag to omb-resolve-issue

### Fixed
- add explicit os import to cron handlers for CI ruff
- add resolve_project_dir() fallback for manual CLI usage
- auto-approve .claude/ writes via PreToolUse
- update script path in test_setup_settings

### Maintenance
- Merge pull request #54 from teddynote-lab/feat/omb-cron
- apply ruff format to cron files
- Merge pull request #55 from teddynote-lab/feat/omb-pr-post-verification
- Merge pull request #53 from teddynote-lab/feat/omb-init-survey
- apply ruff format to new test files
- Merge pull request #50 from teddynote-lab/feat/issue-claim-mechanism
- Merge pull request #52 from teddynote-lab/feat/omb-resolve-bypass
- apply ruff format to test_worktree_handlers
- Merge pull request #51 from teddynote-lab/fix/protected-dir-pretooluse-approve
- Merge pull request #49 from teddynote-lab/feat/omb-resolve-bypass



## [0.1.14] - 2026-04-13

### Maintenance
- Release v0.1.14


## [0.1.12] - 2026-04-13

### Fixed
- revert linux build to direct runner execution
- replace bare except Exception with specific types
- add non-root USER directive to api and ai Dockerfiles

### Documentation
- fix broken blockquote in issue scanner example

### Maintenance
- remove gitleaks secret scanning configuration
- Merge pull request #48 from teddynote-lab/fix/issue-34-error-handling
- Merge pull request #47 from teddynote-lab/fix/issue-40-docker-root-user-directive
- Merge pull request #46 from teddynote-lab/fix/issue-19-chat-pydantic-validation



## [0.1.10] - 2026-04-13

### Maintenance
- Release v0.1.10


## [0.1.9] - 2026-04-13

### Maintenance
- Release v0.1.9


## [0.1.8] - 2026-04-13

### Maintenance
- Merge pull request #45 from teddynote-lab/fix/glibc-compat-linux-binary
- Update .github/workflows/release-binary.yml



## [0.1.7] - 2026-04-13

### Added
- expand omb-postgres references and rules content
- add omb-resolve-issue skill for end-to-end GitHub issue resolution

### Fixed
- add package-lock.json for dependency pinning
- eliminate shell injection in omb-setup-settings.sh Python fallback
- log worktree-status DB errors to stderr
- validate column names in update_status against allowlist
- resolve all CI workflow failures
- use vitest --passWithNoTests CLI flag
- use vitest --passWithNoTests CLI flag
- use vitest --passWithNoTests CLI flag
- allow vitest to pass with no test files
- allow vitest to pass with no test files
- allow vitest to pass with no test files
- add missing jsdom dependency for vitest
- add missing jsdom dependency for vitest
- add missing jsdom dependency for vitest
- add missing @tailwindcss/postcss dependency
- add missing @tailwindcss/postcss dependency
- add missing @tailwindcss/postcss dependency
- add git config for tests and fix eslint dependencies
- add git config for tests and fix eslint dependencies
- add git config for tests and fix eslint dependencies
- add turbo type-check task and suppress certifi import
- add turbo type-check task and suppress certifi import
- add turbo type-check task and suppress certifi import
- scope pyright, add packageManager, fix commit-lint perms
- scope pyright, add packageManager, fix commit-lint perms
- scope pyright, add packageManager, fix commit-lint perms
- resolve CI workflow failures
- resolve CI workflow failures
- resolve CI workflow failures
- update CLAUDE.md verification strategy references
- enforce hook directory conventions

### Improved
- restructure PR and issue templates for improved LLM readability

### Documentation
- add 19 missing agents to CLAUDE.md Sub-Agent Inventory

### Maintenance
- reorder settings.json keys and expand gitignore
- Merge pull request #32 from teddynote-lab/fix/issue-18-missing-package-lock
- Merge pull request #33 from teddynote-lab/fix/issue-15-shell-injection-setup-settings
- fix ruff format on test_setup_settings.py
- Merge pull request #38 from teddynote-lab/fix/issue-21-silent-exception
- Merge pull request #31 from teddynote-lab/fix/issue-16-sql-fstring-column
- apply ruff format to test_worktree_db.py
- Merge pull request #30 from teddynote-lab/fix/issue-14-remove-dead-shared-pkg
- remove unused packages/shared dead code
- Merge pull request #29 from teddynote-lab/refactor/pr-issue-fix
- Merge pull request #27 from teddynote-lab/fix/issue-22-docs-verification
- Merge pull request #26 from teddynote-lab/fix/issue-13-missing-agent-inventory
- Merge pull request #25 from teddynote-lab/fix/issue-12-hook-convention
- Merge pull request #24 from teddynote-lab/feat/omb-resolve-issue



## [0.1.6] - 2026-04-12

### Added
- add --bypass flag to omb-issue for /loop automation
- register omb-issue as omb:issue slash command

### Fixed
- include plan file absolute path in codex review prompts

### Maintenance
- build tarball from source, remove .claude/ from release repo
- stop copying CLAUDE.md to release repo



## [0.1.5] - 2026-04-13

### Fixed
- Install script now always updates `omb` symlink even when an older binary exists
- PyInstaller binary bundles certifi CA certificates to fix SSL errors on macOS
- HTTP downloader uses certifi SSL context for reliable HTTPS connections

## [0.1.4] - 2026-04-13

### Fixed
- Fixed release pipeline that caused all previous releases (v0.1.1-v0.1.3) to ship with zero assets
- CI publish job now tolerates partial build failures across platforms
- Install script URL corrected (no longer returns 404)
- Binary download asset naming aligned with CI output format
- Hooks and statusline script now properly included in harness distribution
- Eliminated race condition between manual release skill and CI pipeline

## [0.1.3] - 2026-04-13

### Added
- `omb:issue` skill for automated codebase scanning and GitHub issue creation
- `omb:git-setup` skill for git workflow setup with pre-commit hooks and GitHub Actions
- `.gitignore` management integrated into `omb init`
- Documentation language support for PR, issue, and plan skills
- Git hooks and GitHub Actions CI workflows

### Fixed
- Statusline width detection for non-TTY and narrow terminal environments
- PR creation workflow compatibility with worktree environments
- Language environment variable resolution in agents and skills

### Changed
- Updated PR labels and added label sync to git-setup workflow

## [0.1.2] - 2026-04-12

### Changed
- Codex skills renamed for improved consistency
- PR template enhanced with language support and conditional sections
- `omb:document` renamed to `omb:doc` for brevity
- README restructured with usage examples and workflow documentation

### Fixed
- Statusline now uses project root for folder name and displays rate limit reset time

## [0.1.1] - 2026-04-12

### Added
- CLI commands: `omb init`, `omb update`, and `omb version` for harness installation and management
- SQLite-based worktree state management with persistent tracking across sessions
- Verification skill (`omb:verify`) with parallel verifier pool
- Codex CLI integration for code review, adversarial review, and task delegation
- Release pipeline for automated version bumping, changelog, and publishing
- Plan review parallelization across multiple reviewer agents
- Evidence-anchored prompt evaluation with binary rubric scoring

### Changed
- Renamed CLI binary to `oh-my-braincrew` with `omb` as primary command
- Unified ticket schema for all evaluation, review, and verification workflows
- TDD practices integrated across all implementation and verification agents

### Fixed
- Git branch name display in statusline
- Hook fallback for manual invocations

---

## Legacy (v0.2.x)

> The v0.2.x series used a plugin-based architecture that has been replaced by the current harness architecture in v0.1.x. These versions are no longer supported.

<details>
<summary>v0.2.6 — v0.2.17 (2026-04-05 to 2026-04-09)</summary>

- v0.2.17: Fixed Codex hooks and plugin manifest path
- v0.2.16: Added Codex plugin integration, lint checks during verification
- v0.2.15: Pipeline recovery and resilience improvements
- v0.2.14: Codex plugin installation, hook reliability fixes
- v0.2.13: Pipeline stall recovery, hook decision logging
- v0.2.12: Dual-path installation guide, checkpoint setup docs
- v0.2.11: Language settings in setup wizard
- v0.2.10: PROJECT.md, Slack notifications, pipeline stability
- v0.2.9: `omb progress` and `omb sync` commands
- v0.2.8: Hook and auto-update fixes
- v0.2.7: `omb init` command
- v0.2.6: Cross-platform binary distribution, one-liner installers

</details>
