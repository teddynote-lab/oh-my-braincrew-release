---
description: "Redis standards: cache patterns, pub/sub, connection pooling, key naming"
paths: ["**/cache/**", "**/redis/**", "**/workers/**/*.py", "**/workers/**/*.ts"]
---

# Redis Standards

## Key Naming

- Use colon-separated namespaces: `{service}:{entity}:{id}`.
- Examples: `auth:session:abc123`, `cache:user:42`, `rate:login:192.168.1.1`.
- Keep keys short but descriptive — Redis stores keys in memory.
- Document key patterns in a central reference.

## TTL Policy

- EVERY cache key MUST have a TTL — no indefinite keys.
- Sessions: match JWT expiry (e.g., 24 hours).
- Cache: based on data freshness requirements (minutes to hours).
- Rate limiting: match the rate window (e.g., 60 seconds).
- Set TTL at write time, not after: `SET key value EX seconds`.

## Cache Patterns

### Cache-Aside (most common)
```python
async def get_user(user_id: str) -> User:
    cached = await redis.get(f"cache:user:{user_id}")
    if cached:
        return User.model_validate_json(cached)
    user = await db.get(user_id)
    await redis.set(f"cache:user:{user_id}", user.model_dump_json(), ex=3600)
    return user
```

### Cache Invalidation
- Invalidate on write: when data changes, delete the cache key.
- Use tags for bulk invalidation when related data changes.
- Prefer explicit invalidation over short TTLs for consistency.

## Pub/Sub

- Use for real-time notifications, not for reliable message delivery.
- Channel naming: `{service}:{event}` (e.g., `users:created`, `alerts:critical`).
- Subscribers must handle reconnection — pub/sub messages are not persisted.
- For reliable messaging, use Redis Streams instead.

## Connection Pooling

- Use `redis.asyncio.ConnectionPool` for async Python.
- Pool size: match expected concurrent operations.
- Close pool on application shutdown.
- Handle connection errors with retry logic.

## Security

- Use Redis ACLs in production — don't use the default user.
- Bind to localhost or internal network only — never expose to public internet.
- Enable TLS for connections over untrusted networks.
- Use `READONLY` commands where possible to prevent accidental writes.

## Anti-Patterns

- Keys without TTL (memory leak over time).
- Storing large values (>1MB) — Redis is for small, fast data.
- Using `KEYS *` in production — use `SCAN` instead.
- Relying on pub/sub for critical message delivery.

## Related Rules

- For related Postgres patterns, see `.claude/rules/db/postgres.md`.
