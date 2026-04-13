# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
