---
description: "Integration and E2E test standards: testcontainers, cross-layer verification"
paths: ["**/tests/integration/**", "**/tests/e2e/**", "**/integration/**"]
---

# Integration Tests

## Purpose

Integration tests verify that components work together across stack boundaries:
API + Database, Frontend + API, LangGraph + external tools.

## Infrastructure

### Testcontainers (Python)
```python
# conftest.py for integration tests
import pytest
from testcontainers.postgres import PostgresContainer
from testcontainers.redis import RedisContainer

@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:16") as pg:
        yield pg.get_connection_url()

@pytest.fixture(scope="session")
def redis():
    with RedisContainer("redis:7") as r:
        yield r.get_connection_url()
```

### Docker Compose (CI)
- Use `docker-compose.test.yml` for CI integration test services.
- Services: Postgres, Redis, any external dependencies.
- Health checks on all services before tests run.

## Patterns

### API + Database
- Test full request lifecycle: HTTP request → handler → DB → response.
- Use real database (testcontainers), not mocks.
- Seed data in fixtures, clean up after each test.

### Frontend + API
- Use MSW for API layer in component integration tests.
- For full E2E: Playwright against running dev server.

### LangGraph + Tools
- Mock LLM responses (deterministic), but use real tool execution.
- Verify state transitions and checkpoint behavior.

## Test Isolation

- Each test gets a clean database state (transaction rollback or truncate).
- No shared mutable state between tests.
- Tests must pass when run in any order.

## CI Configuration

- Integration tests run in a separate CI job from unit tests.
- Timeout: 10 minutes max per test suite.
- Retry flaky tests once — if still flaky, fix or quarantine.

## When to Write Integration Tests

- New API endpoint that reads/writes to database.
- Cross-service communication (FastAPI → Redis pub/sub → Node.js).
- LangGraph workflows with external tool calls.
- Authentication/authorization flows end-to-end.

## Anti-Patterns

- Mocking the database in integration tests.
- Tests that depend on external services (use containers instead).
- Integration tests for pure logic (use unit tests).
- Long-running tests without timeouts.
