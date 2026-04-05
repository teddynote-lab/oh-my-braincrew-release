---
description: "Async/concurrency patterns for Python (asyncio) and TypeScript (async/await)"
paths: ["**/api/**/*.py", "**/services/**/*.py", "**/server/**/*.ts", "**/workers/**/*.ts"]
---

# Async Patterns

## Python (asyncio)

### Rules
- All FastAPI handlers MUST be `async def`.
- Never mix sync blocking calls in async code — use `asyncio.to_thread()` for CPU-bound work.
- Use `asyncio.gather()` for concurrent independent operations.
- Always set timeouts on async operations: `asyncio.wait_for(coro, timeout=N)`.

### Connection Pools
- Use async connection pools for Postgres (`asyncpg`) and Redis (`aioredis`/`redis.asyncio`).
- Size pools based on expected concurrency — not too large (Postgres `max_connections`).
- Close pools on shutdown: use FastAPI `lifespan` context manager.

### Common Pitfalls
- Blocking the event loop: `time.sleep()` → use `asyncio.sleep()`.
- Fire-and-forget tasks: use `asyncio.create_task()` with error handling.
- Resource leaks: always close async resources (sessions, connections) in `finally`.

## TypeScript (Node.js)

### Rules
- Always `await` promises unless explicitly fire-and-forget.
- Use `Promise.all()` for independent operations, `Promise.allSettled()` when partial failure is acceptable.
- Set timeouts on all external calls.
- Handle `unhandledRejection` at process level.

### Common Pitfalls
- Forgetting `await`: creates silent unhandled promise.
- Sequential awaits when parallel is possible: `await a(); await b()` → `await Promise.all([a(), b()])`.
- Not handling errors in `Promise.all()` — one rejection rejects all.

## React (Concurrent)

- Use `useTransition` for non-urgent state updates.
- Use `Suspense` boundaries for async data loading.
- Clean up async operations in `useEffect` return function.
- Cancel in-flight requests on unmount (AbortController).

## General

- Log async errors — never swallow silently.
- Use structured concurrency: parent scope waits for all child tasks.
- Prefer backpressure (bounded queues) over unbounded task spawning.
