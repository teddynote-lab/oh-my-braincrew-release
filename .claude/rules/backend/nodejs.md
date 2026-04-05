---
description: "Node.js backend standards: Express/Fastify, async patterns, middleware, error handling"
paths: ["**/server/**/*.ts", "**/routes/**/*.ts", "**/middleware/**/*.ts", "**/package.json"]
---

# Node.js Backend Standards

## Framework Patterns

### Express
```typescript
import express, { Request, Response, NextFunction } from 'express';

const router = express.Router();

router.post('/api/users', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = await userService.create(req.body);
    res.status(201).json(user);
  } catch (error) {
    next(error);
  }
});
```

### Fastify
```typescript
import Fastify from 'fastify';

const app = Fastify({ logger: true });

app.post('/api/users', {
  schema: { body: CreateUserSchema, response: { 201: UserResponseSchema } },
  handler: async (request, reply) => {
    const user = await userService.create(request.body);
    reply.status(201).send(user);
  },
});
```

## Error Handling

- Use centralized error middleware (Express) or error handler (Fastify).
- Never expose stack traces in production responses.
- Structured error response: `{ error: { code: string, message: string } }`.
- Catch unhandled promise rejections at process level.

```typescript
// Express error middleware — must be registered last
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  logger.error(err);
  const status = err instanceof AppError ? err.statusCode : 500;
  res.status(status).json({ error: { code: err.name, message: err.message } });
});
```

## Async Patterns

- Always `await` promises — no fire-and-forget unless explicitly intended.
- Use `Promise.all()` for independent async operations.
- Set timeouts on external calls (HTTP, DB, Redis).
- Handle `SIGTERM` / `SIGINT` for graceful shutdown.

## Security

- Validate input with a schema library (zod, joi, or Fastify schemas).
- Use parameterized queries — never string interpolation in SQL.
- Set security headers: `helmet` (Express) or equivalent.
- Rate limit auth endpoints.

## Project Structure

```
src/
├── routes/           # Route handlers by domain
├── middleware/        # Auth, logging, error handling
├── services/         # Business logic
├── models/           # TypeScript interfaces/types
├── db/               # Database client, queries
└── config.ts         # Environment variable validation
```

## Configuration

- Validate env vars at startup using zod or similar.
- See `.claude/rules/code-conventions.md` for secrets and env var rules. Node.js-specific: fail fast if required variables are missing.
