---
description: "Docker standards: Dockerfile best practices, compose config, image optimization"
paths: ["**/Dockerfile*", "**/docker-compose*", "**/.dockerignore"]
---

# Docker Standards

## Dockerfile Best Practices

- Use multi-stage builds to keep final images small.
- Pin base image versions: `python:3.12-slim`, not `python:latest`.
- Order layers by change frequency: system deps → app deps → source code.
- Use `.dockerignore` to exclude `node_modules/`, `.git/`, `__pycache__/`, `.env*`.

### Python
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN pip install --no-cache-dir uv && uv sync --no-dev --no-install-project

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv .venv
COPY src/ src/
ENV PATH="/app/.venv/bin:$PATH"
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Node.js
```dockerfile
FROM node:20-slim AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile

FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/node_modules node_modules
COPY . .
CMD ["node", "dist/server.js"]
```

## Docker Compose

- Use `docker-compose.yml` for development, `docker-compose.prod.yml` for production overrides.
- Define health checks for all services.
- Use named volumes for persistent data (Postgres, Redis).
- Network isolation: backend services on internal network, only API exposed.

```yaml
services:
  api:
    build: .
    ports: ["8000:8000"]
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_healthy }
    env_file: .env

  postgres:
    image: postgres:16
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]

  redis:
    image: redis:7
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
```

## Security

- Run containers as non-root user.
- No secrets in Dockerfiles or images — use env vars or secrets management.
- Scan images for vulnerabilities: `docker scout cves`.
- Minimize installed packages — use slim base images.

## Anti-Patterns

- Large images (>500MB for Python, >300MB for Node.js).
- Running as root in production.
- Secrets baked into image layers.
- Missing health checks on services.
