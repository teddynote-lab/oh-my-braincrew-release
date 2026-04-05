---
description: "Pytest standards for Python backend testing: FastAPI, async, fixtures, coverage"
paths: ["**/test_*.py", "**/conftest.py", "**/tests/**/*.py"]
---

# Pytest Standards

## Structure

```
tests/
├── conftest.py              # Shared fixtures (DB session, auth token, test client)
├── unit/
│   ├── test_models.py       # Pydantic model validation
│   ├── test_services.py     # Business logic
│   └── test_utils.py        # Utility functions
├── api/
│   ├── test_auth.py         # Auth endpoint tests
│   └── test_users.py        # User endpoint tests
├── integration/
│   ├── conftest.py          # Integration-specific fixtures (testcontainers)
│   └── test_db_operations.py
└── langchain/
    ├── test_chains.py       # Chain unit tests with mocked LLM
    └── test_graphs.py       # LangGraph node tests
```

## Fixtures

- Use `conftest.py` for shared fixtures — no fixture imports across test files.
- Scope fixtures appropriately: `function` (default), `module`, `session`.
- Use `pytest-asyncio` with `mode = "auto"` for async fixtures.
- Factory fixtures over static data: `create_user(**overrides)` > `sample_user`.

## Patterns

- **AAA**: Arrange-Act-Assert in every test.
- **Naming**: `test_<function>_<scenario>_<expected>`. Example: `test_login_expired_token_returns_401`.
- **One assertion per concept** — multiple asserts are fine if testing one behavior.
- **Mock at boundaries**: external APIs, time, random. Never mock internal implementation.

## FastAPI Testing

```python
# Use TestClient for sync, httpx.AsyncClient for async
from fastapi.testclient import TestClient

def test_create_user_returns_201(client: TestClient, auth_headers: dict):
    response = client.post("/api/users", json={"name": "test"}, headers=auth_headers)
    assert response.status_code == 201
    assert response.json()["name"] == "test"
```

## Async Testing

```python
import pytest

@pytest.mark.asyncio
async def test_async_operation(async_db_session):
    result = await some_async_function(async_db_session)
    assert result is not None
```

## Coverage

- Minimum coverage target: 80% for new code.
- Run: `pytest --cov=src --cov-report=term-missing`.
- Focus coverage on business logic, not boilerplate.

## Anti-Patterns

- Tests that pass regardless of implementation.
- Tests that depend on execution order.
- Mocking internal implementation details.
- Shared mutable state between tests.
- Overly broad `conftest.py` fixtures that slow all tests.
