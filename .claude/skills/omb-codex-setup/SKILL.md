---
name: omb-codex-setup
description: "Verify Codex CLI installation, authentication status, and run a quick connectivity test."
user-invocable: true
allowed-tools: Bash, Read, AskUserQuestion
---

# Codex CLI Setup

Verify that the Codex CLI is installed, authenticated, and functioning.

## Step 1: Check Installation

```bash
which codex 2>/dev/null && codex --version 2>&1
```

If `codex` is not found:
1. Ask: "Codex CLI is not installed. Install it now?"
2. If yes: run `npm install -g @openai/codex`
3. Verify: `which codex && codex --version`

## Step 2: Check Authentication

```bash
codex login status 2>&1 || echo "AUTH_CHECK_FAILED"
```

If not authenticated:
1. Check if `OPENAI_API_KEY` is set: `printenv OPENAI_API_KEY | head -c4`
2. If set, inform the user that Codex will use the API key.
3. If not set, tell the user:
   ```
   Set your OpenAI API key:
     export OPENAI_API_KEY="sk-..."
   Or run: codex login
   ```

## Step 3: Quick Connectivity Test

Run a minimal test to verify Codex responds:

```bash
codex review --help 2>&1 | head -5
```

If the command succeeds, report:
```
Codex CLI setup complete:
  Version: <version>
  Auth: <status>
  Test: passed
```

## Step 4: Summary

Report the overall status. If all checks pass, confirm Codex is ready to use with `/omb codex review` and `/omb codex run`.
