#!/usr/bin/env bash
# Scans a plan file for domain keywords and outputs detected domains as JSON.
# Usage: bash detect-plan-domains.sh <plan-file-path>
# Output: {"frontend":true,"electron":false,"backend_api":true,"database":false,"langchain":false,"security":false,"infra":false,"async":false,"prompt":false,"designer":false,"architect":false}
set -euo pipefail

PLAN_FILE="${1:-}"

if [[ -z "$PLAN_FILE" ]]; then
  echo "ERROR: Plan file path required" >&2
  exit 1
fi

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

CONTENT=$(cat "$PLAN_FILE")

detect_domain() {
  local pattern="$1"
  if echo "$CONTENT" | grep -ciE "$pattern" > /dev/null 2>&1; then
    echo "true"
  else
    echo "false"
  fi
}

FRONTEND=$(detect_domain "react|vite|tailwind|component|tsx|jsx|css|frontend|shadcn|ui|hook|useState|useEffect")
ELECTRON=$(detect_domain "electron|ipc|preload|main process|renderer|contextBridge|desktop|autoUpdater")
BACKEND_API=$(detect_domain "fastapi|express|fastify|route handler|endpoint|api|pydantic|middleware|node.js server|REST|openapi")
DATABASE=$(detect_domain "postgres|redis|migration|alembic|sqlalchemy|asyncpg|schema|table|column|index|connection pool|upstash|neon")
LANGCHAIN=$(detect_domain "langchain|langgraph|langsmith|rag|retrieval|embedding|vector|agent workflow|llm chain|checkpoint|state machine")
SECURITY=$(detect_domain "auth|jwt|token|session|owasp|xss|csrf|injection|rce|acl|rls|permission|credential|secret|encrypt|certificate")
INFRA=$(detect_domain "docker|compose|github actions|ci/cd|pipeline|nginx|caddy|prometheus|grafana|monitoring|deploy|container|kubernetes")
ASYNC=$(detect_domain "asyncio|async/await|concurrent|parallel|worker|queue|pubsub|pub/sub|websocket|sse|streaming|event loop|race condition")
PROMPT=$(detect_domain "system prompt|few-shot|chain-of-thought|prompt template|token efficiency|prompt engineering|instruction tuning|persona prompt|output format|prompt optimization")
DESIGNER=$(detect_domain "design token|design variable|color palette|typography scale|tailwind theme|motion design|animation curve|dark mode|visual identity|spacing system|layout grid|Figma|wireframe|design system|brand identity|aesthetic|gradient system|shadow token")
ARCHITECT=$(detect_domain "architecture decision|ADR|system design|orchestration|dependency graph|trade-off|tradeoff|component boundary|abstraction layer|separation of concern|monorepo|microservice|event-driven")

printf '{"frontend":%s,"electron":%s,"backend_api":%s,"database":%s,"langchain":%s,"security":%s,"infra":%s,"async":%s,"prompt":%s,"designer":%s,"architect":%s}\n' \
  "$FRONTEND" "$ELECTRON" "$BACKEND_API" "$DATABASE" "$LANGCHAIN" "$SECURITY" "$INFRA" "$ASYNC" "$PROMPT" "$DESIGNER" "$ARCHITECT"
