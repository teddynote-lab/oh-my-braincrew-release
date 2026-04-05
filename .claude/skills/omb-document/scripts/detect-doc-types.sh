#!/usr/bin/env bash
# Scans a plan file and optional execution log for documentation type signals.
# Usage: bash detect-doc-types.sh <plan-file-path> [execution-log-path]
# Output: JSON mapping doc types to {needed: bool, reason: string}
set -euo pipefail

PLAN_FILE="${1:-}"
EXEC_LOG="${2:-}"

if [[ -z "$PLAN_FILE" ]]; then
  echo "ERROR: Plan file path required" >&2
  exit 1
fi

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

PLAN_CONTENT=$(cat "$PLAN_FILE")
EXEC_CONTENT=""
if [[ -n "$EXEC_LOG" && -f "$EXEC_LOG" ]]; then
  EXEC_CONTENT=$(cat "$EXEC_LOG")
fi

ALL_CONTENT="$PLAN_CONTENT
$EXEC_CONTENT"

# Keyword detection (case-insensitive)
detect_keyword() {
  local pattern="$1"
  if echo "$ALL_CONTENT" | grep -ciE "$pattern" > /dev/null 2>&1; then
    echo "true"
  else
    echo "false"
  fi
}

# File path detection from execution log
detect_file_pattern() {
  local pattern="$1"
  if [[ -n "$EXEC_CONTENT" ]] && echo "$EXEC_CONTENT" | grep -ciE "$pattern" > /dev/null 2>&1; then
    echo "true"
  else
    echo "false"
  fi
}

# Build reason string
build_reason() {
  local keyword_match="$1"
  local file_match="$2"
  local keyword_desc="$3"
  local file_desc="$4"

  local reasons=""
  if [[ "$keyword_match" == "true" ]]; then
    reasons="$keyword_desc"
  fi
  if [[ "$file_match" == "true" ]]; then
    if [[ -n "$reasons" ]]; then
      reasons="$reasons; $file_desc"
    else
      reasons="$file_desc"
    fi
  fi
  echo "$reasons"
}

# --- Detect each doc type ---

# README
README_KW=$(detect_keyword "readme|quick start|getting started|installation|new feature|new skill|new agent")
README_REASON=""
if [[ "$README_KW" == "true" ]]; then
  README_REASON="plan mentions README-related content"
fi

# README i18n variants
README_LANGS=""
for f in README.*.md; do
  [[ -f "$f" ]] || continue
  lang=$(echo "$f" | sed 's/README\.\(.*\)\.md/\1/')
  if [[ -n "$lang" ]]; then
    if [[ -n "$README_LANGS" ]]; then
      README_LANGS="$README_LANGS, \"$lang\""
    else
      README_LANGS="\"$lang\""
    fi
  fi
done

# ADR
ADR_KW=$(detect_keyword "architecture decision|design decision|ADR|tradeoff|alternative considered|Architecture Decisions")
ADR_REASON=""
if [[ "$ADR_KW" == "true" ]]; then
  ADR_REASON="architecture decisions detected in plan"
fi

# API
API_KW=$(detect_keyword "fastapi|express|fastify|route handler|endpoint|pydantic|middleware|REST|openapi|swagger")
API_FP=$(detect_file_pattern "\.(py|ts|js).*(api|route|endpoint)|/api/|/routes/")
API_REASON=$(build_reason "$API_KW" "$API_FP" "API-related keywords in plan" "API files in changes")
API_NEEDED="false"
if [[ "$API_KW" == "true" || "$API_FP" == "true" ]]; then
  API_NEEDED="true"
fi

# DB
DB_KW=$(detect_keyword "postgres|redis|migration|alembic|sqlalchemy|asyncpg|schema|table|column|index|connection pool")
DB_FP=$(detect_file_pattern "migration|alembic|schema|\.sql")
DB_REASON=$(build_reason "$DB_KW" "$DB_FP" "database keywords in plan" "database files in changes")
DB_NEEDED="false"
if [[ "$DB_KW" == "true" || "$DB_FP" == "true" ]]; then
  DB_NEEDED="true"
fi

# Architecture
ARCH_KW=$(detect_keyword "system design|component diagram|data flow|sequence diagram|architecture|topology")
ARCH_REASON=""
if [[ "$ARCH_KW" == "true" ]]; then
  ARCH_REASON="architecture-related keywords in plan"
fi

# Guides
GUIDE_KW=$(detect_keyword "setup guide|deployment|migration guide|breaking change|upgrade path|runbook")
GUIDE_REASON=""
if [[ "$GUIDE_KW" == "true" ]]; then
  GUIDE_REASON="guide-related keywords in plan"
fi

# LangChain
LC_KW=$(detect_keyword "langchain|langgraph|langsmith|rag|retrieval|embedding|vector|agent workflow|llm chain|checkpoint")
LC_FP=$(detect_file_pattern "chain|graph|langchain|langgraph")
LC_REASON=$(build_reason "$LC_KW" "$LC_FP" "LangChain/LangGraph keywords in plan" "LangChain files in changes")
LC_NEEDED="false"
if [[ "$LC_KW" == "true" || "$LC_FP" == "true" ]]; then
  LC_NEEDED="true"
fi

# Frontend
FE_KW=$(detect_keyword "react|vite|tailwind|component|tsx|jsx|css|frontend|shadcn|hook|useState|useEffect")
FE_FP=$(detect_file_pattern "\.(tsx|jsx)|/components/|/frontend/")
FE_REASON=$(build_reason "$FE_KW" "$FE_FP" "frontend keywords in plan" "frontend files in changes")
FE_NEEDED="false"
if [[ "$FE_KW" == "true" || "$FE_FP" == "true" ]]; then
  FE_NEEDED="true"
fi

# Electron
EL_KW=$(detect_keyword "electron|ipc|preload|main process|renderer|contextBridge|desktop|autoUpdater")
EL_FP=$(detect_file_pattern "electron|preload|main\.ts|main\.js")
EL_REASON=$(build_reason "$EL_KW" "$EL_FP" "Electron keywords in plan" "Electron files in changes")
EL_NEEDED="false"
if [[ "$EL_KW" == "true" || "$EL_FP" == "true" ]]; then
  EL_NEEDED="true"
fi

# Infra
INFRA_KW=$(detect_keyword "docker|compose|github actions|ci/cd|pipeline|nginx|caddy|prometheus|grafana|monitoring")
INFRA_FP=$(detect_file_pattern "docker|\.github|Dockerfile|ci|deploy")
INFRA_REASON=$(build_reason "$INFRA_KW" "$INFRA_FP" "infrastructure keywords in plan" "infrastructure files in changes")
INFRA_NEEDED="false"
if [[ "$INFRA_KW" == "true" || "$INFRA_FP" == "true" ]]; then
  INFRA_NEEDED="true"
fi

# Testing
TEST_KW=$(detect_keyword "test strategy|coverage|fixture|parametrize|vitest|pytest|jest|testcontainers")
TEST_FP=$(detect_file_pattern "test_|_test\.|\.test\.|\.spec\.|/tests/|/test/")
TEST_REASON=$(build_reason "$TEST_KW" "$TEST_FP" "testing keywords in plan" "test files in changes")
TEST_NEEDED="false"
if [[ "$TEST_KW" == "true" || "$TEST_FP" == "true" ]]; then
  TEST_NEEDED="true"
fi

# Security
SEC_KW=$(detect_keyword "auth|jwt|token|owasp|xss|csrf|injection|rce|acl|rls|permission|credential|encrypt")
SEC_FP=$(detect_file_pattern "auth|security|middleware|permission")
SEC_REASON=$(build_reason "$SEC_KW" "$SEC_FP" "security keywords in plan" "security files in changes")
SEC_NEEDED="false"
if [[ "$SEC_KW" == "true" || "$SEC_FP" == "true" ]]; then
  SEC_NEEDED="true"
fi

# Prompts
PROMPT_KW=$(detect_keyword "prompt template|few-shot|chain-of-thought|system prompt|LLM prompt|prompt engineering")
PROMPT_FP=$(detect_file_pattern "prompt|\.prompt\.|/prompts/")
PROMPT_REASON=$(build_reason "$PROMPT_KW" "$PROMPT_FP" "prompt keywords in plan" "prompt files in changes")
PROMPT_NEEDED="false"
if [[ "$PROMPT_KW" == "true" || "$PROMPT_FP" == "true" ]]; then
  PROMPT_NEEDED="true"
fi

# Escape strings for JSON
json_str() {
  echo "$1" | sed 's/"/\\"/g'
}

# Output JSON
cat <<EOF
{
  "readme": {"needed": $README_KW, "reason": "$(json_str "$README_REASON")", "languages": [$README_LANGS]},
  "adr": {"needed": $ADR_KW, "reason": "$(json_str "$ADR_REASON")"},
  "api": {"needed": $API_NEEDED, "reason": "$(json_str "$API_REASON")"},
  "db": {"needed": $DB_NEEDED, "reason": "$(json_str "$DB_REASON")"},
  "architecture": {"needed": $ARCH_KW, "reason": "$(json_str "$ARCH_REASON")"},
  "guides": {"needed": $GUIDE_KW, "reason": "$(json_str "$GUIDE_REASON")"},
  "langchain": {"needed": $LC_NEEDED, "reason": "$(json_str "$LC_REASON")"},
  "frontend": {"needed": $FE_NEEDED, "reason": "$(json_str "$FE_REASON")"},
  "electron": {"needed": $EL_NEEDED, "reason": "$(json_str "$EL_REASON")"},
  "infra": {"needed": $INFRA_NEEDED, "reason": "$(json_str "$INFRA_REASON")"},
  "testing": {"needed": $TEST_NEEDED, "reason": "$(json_str "$TEST_REASON")"},
  "security": {"needed": $SEC_NEEDED, "reason": "$(json_str "$SEC_REASON")"},
  "prompts": {"needed": $PROMPT_NEEDED, "reason": "$(json_str "$PROMPT_REASON")"},
  "document_record": {"needed": true, "reason": "always generated for audit trail"}
}
EOF
