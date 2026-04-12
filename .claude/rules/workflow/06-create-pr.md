---
description: PR creation rules and conventions
---

# PR Creation Rules

## Branch Naming

PR source branch must follow the branch naming convention: `{type}/{short-kebab-description}`

Valid types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `perf`, `style`, `build`

See `git/branch-naming.md` for full rules and examples.

## Conventional Commit Messages

Format: `type(scope): description`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`, `perf`, `style`, `build`

Examples:
- `feat(auth): add OAuth2 login flow`
- `fix(api): handle null response from payment provider`
- `refactor(db): migrate to SQLAlchemy 2.0 async syntax`

Breaking changes: add `BREAKING CHANGE:` in commit footer.

For detailed commit message structure, see `git/commit-template.md`.

## Language Support

PR body language follows `OMB_DOCUMENTATION_LANGUAGE` environment variable:
- `en` (default): English headers and body text
- `ko`: Korean headers and body text (technical terms, file paths, commands, code references stay English)
- PR title is ALWAYS English (conventional commit format)

<!-- Keep in sync with .claude/agents/omb/git-commit.md <pr_template> -->

## PR Template

### Required Sections (always include)

```markdown
## Summary / 요약
- {WHAT changed — concrete description}
- {WHY it was needed — the problem or requirement}
- {HOW it was approached — key design choice}

## Motivation / Context / 동기 / 배경
{Detailed problem statement or requirement that triggered this change.
Explain what was wrong, missing, or needed before this change.
Link to related issues, discussions, or user reports if available.}

## Changes / 변경 사항

### Added / 추가
- {new files, features, APIs, endpoints}

### Changed / 변경
- {modified behavior, refactored code, updated configs}

### Removed / 삭제
- {deleted files, deprecated features, removed dependencies}

(If fewer than 5 items total, use a flat bullet list without sub-headers.)

## Test Plan / 테스트 계획
- [ ] `{specific test command 1}` — expected: {result}
- [ ] `{specific test command 2}` — expected: {result}
- [ ] Manual testing: {specific steps to verify the change}
- [ ] Lint check passes (`/omb-lint-check`)
- [ ] Type check passes (`tsc --noEmit` or `pyright`)

## Related Issues / 관련 이슈
{Closes #N, Refs #N — or "None"}

## Checklist / 체크리스트
- [ ] Branch name follows naming convention (`type/description`)
- [ ] Commit messages follow conventional commit template
- [ ] Type check passes
- [ ] Linter passes
- [ ] No secrets committed
- [ ] Documentation updated if needed
- [ ] No unrelated changes bundled in this PR
```

### Optional Sections (include only when condition is met)

**Architecture / 아키텍처** — when diff touches 3+ directories or adds new modules/APIs:
- Include a Mermaid `flowchart TD` or `graph LR` (3-8 nodes max)
- Brief explanation of the architectural change

**Screenshots / 스크린샷** — when diff modifies UI components, CSS, or visual output

**Breaking Changes / 호환성 변경** — when API signatures change, exports removed, defaults changed:
- What Breaks: specific impact description
- Migration Guide: step-by-step instructions

**Reviewer Notes / 리뷰어 참고 사항** — when non-obvious design decisions or trade-offs exist

## Changelog Format

```markdown
## [version] - YYYY-MM-DD
### Added
### Changed
### Fixed
### Removed
```

## PR Review Checklist

- PR title follows conventional commit format
- Branch name follows naming convention
- Description explains WHY, not just WHAT
- Single responsibility — one logical change per PR
- No unrelated changes bundled
- All CI checks pass before requesting review
- Draft PR if work is still in progress
- PR size: < 400 lines ideal, > 800 needs justification
