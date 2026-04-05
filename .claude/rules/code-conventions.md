---
description: "Cross-language code conventions for the oh-my-braincrew tech stack"
---

# Code Conventions

## Language

- All comments, docstrings, variable names, commit messages, and documentation MUST be in English.

## Naming

| Language | Variables/Functions | Classes/Types | Constants | Files |
|----------|-------------------|---------------|-----------|-------|
| Python | `snake_case` | `PascalCase` | `UPPER_SNAKE` | `snake_case.py` |
| TypeScript | `camelCase` | `PascalCase` | `UPPER_SNAKE` | `camelCase.ts` / `PascalCase.tsx` |
| React Components | — | `PascalCase` | — | `PascalCase.tsx` |

## Secrets and Configuration

- Never hardcode secrets, tokens, API keys, or connection strings.
- Use environment variables for all configuration that varies by environment.
- Use `.env` files for local development only — never commit them.
- Validate env vars at startup, not at first use.

## Error Handling

- Handle errors explicitly at system boundaries (API routes, IPC handlers, external calls).
- Never swallow errors silently — log or propagate.
- Use structured error responses with consistent shape:
  - Python/FastAPI: `HTTPException` with `detail` dict containing `code` and `message`.
  - Node.js: error middleware with `{ error: { code, message } }` JSON response.
  - React: error boundaries for component trees, try/catch for async operations.

## Import Organization

- Python: stdlib → third-party → local (enforced by isort/ruff).
- TypeScript: node builtins → external packages → internal aliases → relative imports.
- No circular imports — if detected, refactor to break the cycle.

## Type Safety

- Python: type hints on all function signatures. Use `mypy --strict` or Pyright.
- TypeScript: `strict: true` in tsconfig. No `any` unless explicitly justified with a comment.
- Prefer explicit types at function boundaries; infer within function bodies.

## Code Style

- Python: follow ruff defaults (PEP8 superset). Max line length: 120.
- TypeScript: follow ESLint + Prettier defaults. Max line length: 120.
- Prefer early returns over deep nesting.
- One concept per function — if a function does two things, split it.

## Comments

- Write comments only where the logic is non-obvious.
- Prefer self-documenting code (clear names, small functions) over comments.
- TODO comments must include author and issue reference: `# TODO(author): description [#issue]`.

## Dependencies

- Pin major versions in package.json / pyproject.toml.
- No unused dependencies — audit periodically.
- Prefer well-maintained packages with active security patching.
