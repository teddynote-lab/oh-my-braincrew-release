---
description: "FastAPI backend standards: async routes, Pydantic models, dependency injection, middleware"
paths: ["**/api/**/*.py", "**/routes/**/*.py", "**/middleware/**/*.py", "**/pyproject.toml"]
---

# FastAPI Standards

## Route Design

- All route handlers MUST be `async def`.
- Use `Depends()` for dependency injection — never instantiate services inline.
- Use Pydantic v2 models for request/response validation.
- Use `HTTPException` for error responses with structured `detail`.

```python
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/api/users", tags=["users"])

class CreateUserRequest(BaseModel):
    name: str
    email: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    body: CreateUserRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    ...
```

## Middleware

- Order matters: auth → rate limiting → logging → CORS.
- Use `@app.middleware("http")` for cross-cutting concerns.
- Never block the event loop in middleware — use async throughout.

## Error Handling

- Use `HTTPException` with status codes and structured detail.
- Global exception handler for unhandled errors → 500 with generic message (no stack trace in production).
- Log full error details server-side, return safe messages client-side.

## Security

- Never trust client input — validate with Pydantic.
- Use `Depends(get_current_user)` for auth on every protected route.
- Parameterized queries only — no string interpolation in SQL.
- Rate limit sensitive endpoints (login, password reset).

## Project Structure

```
src/
├── api/
│   ├── routes/          # Route handlers grouped by domain
│   ├── dependencies.py  # Shared Depends() functions
│   └── middleware.py     # Custom middleware
├── models/              # Pydantic models (request/response)
├── services/            # Business logic
├── db/                  # SQLAlchemy models, session, migrations
└── config.py            # Settings from env vars (Pydantic BaseSettings)
```

## Configuration

- Use `pydantic-settings` (BaseSettings) for configuration.
- See `.claude/rules/code-conventions.md` for secrets and env var rules. FastAPI-specific: validate at startup with BaseSettings.
