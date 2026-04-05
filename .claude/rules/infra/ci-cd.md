---
description: "CI/CD standards: GitHub Actions workflows, test pipeline, deployment gates"
paths: ["**/.github/workflows/**", "**/.github/actions/**"]
---

# CI/CD Standards (GitHub Actions)

## Pipeline Structure

```
PR opened/updated:
  ├── Lint (ruff, eslint, prettier)
  ├── Type check (mypy/pyright, tsc)
  ├── Unit tests (pytest, vitest) — parallel by stack
  ├── Integration tests (testcontainers)
  └── Build (Docker image, Vite build)

Merge to main:
  ├── All PR checks (re-run)
  ├── Build & push Docker image
  └── Deploy to staging

Release tag:
  ├── All checks
  ├── Build production images
  └── Deploy to production (manual approval gate)
```

## Workflow Best Practices

- Use `on.pull_request` for PR checks, `on.push` for main branch.
- Cache dependencies: `actions/cache` for `node_modules/`, `.venv/`, uv cache.
- Run independent jobs in parallel (lint, test, build).
- Fail fast: cancel in-progress runs on new push to same branch.

```yaml
name: CI
on:
  pull_request:
    branches: [main]
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: uv tool run ruff check .
  test-python:
    runs-on: ubuntu-latest
    services:
      postgres: { image: 'postgres:16', ... }
      redis: { image: 'redis:7', ... }
    steps:
      - uses: actions/checkout@v4
      - run: uv pip install -e ".[test]" --system && pytest -v
```

## Secrets Management

- Store secrets in GitHub Actions secrets — never in workflow files.
- Use environment-scoped secrets for staging/production separation.
- Rotate secrets regularly.

## Deployment Gates

- Staging: automatic on merge to main (after all checks pass).
- Production: manual approval required (GitHub Environments).
- Rollback: documented procedure, practiced regularly.

## Anti-Patterns

- Skipping tests for "quick fixes" (`[skip ci]` in commit message).
- Long-running pipelines (>15 minutes) — parallelize or optimize.
- Deploying without running the full test suite.
- Storing secrets in environment variables in workflow files.
