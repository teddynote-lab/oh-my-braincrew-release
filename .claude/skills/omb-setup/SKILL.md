---
name: omb-setup
user-invocable: true
description: >
  (omb) Use when setting up omb in a project for the first time or updating user profile and project configuration.
  Collects user identity, optional Slack credentials, scans codebase, asks project questions, generates CLAUDE.md and PROJECT.md.
  Triggers on: setup, init, initialize, first-time setup, configure project, update profile, survey, init-project.
argument-hint: "[--force to re-run] [project description]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Agent
---

# setup Skill

Unified first-time setup: collect user identity, optionally configure Slack notifications,
scan the codebase, ask targeted questions, and generate project-specific `CLAUDE.md` and `PROJECT.md`.

## HARD RULES

- [HARD] All output in English
- [HARD] Ask ONE question at a time via AskUserQuestion (never batch multiple questions)
- [HARD] Never store GitHub tokens — rely on `gh auth` only
- [HARD] Never block setup completion on GitHub API failures — always fall back gracefully
- [HARD] Write profile.json BEFORE attempting Slack config, project scan, or community steps
- [HARD] If CLAUDE.md exists: READ first, backup to `.bak`, then UPDATE (never blind overwrite)
- [HARD] If PROJECT.md exists: READ first, backup to `PROJECT.md.bak`, then UPDATE (never blind overwrite)
- [HARD] PROJECT.md must be under 200 lines
- [HARD] CLAUDE.md first hard rule must be: `[HARD] Read PROJECT.md at session start before any work`
- [HARD] Explore agents must complete BEFORE asking any user questions (Phase 3)

## Pre-execution Context

!`cat ~/.omb/profile.json 2>/dev/null || echo "no profile"`
!`gh auth status 2>&1 || echo "gh_not_available"`
!`git branch --show-current 2>/dev/null || true`
!`ls CLAUDE.md PROJECT.md .claude/CLAUDE.md 2>/dev/null || echo "no existing files"`

Parse pre-execution output to set flags:
- `profile_exists`: true if profile.json content was returned (not "no profile")
- `gh_available`: true if `gh auth status` output contains "Logged in to"
- `existing_files`: list of detected CLAUDE.md / PROJECT.md files

## Reference Material

All templates, schemas, GraphQL mutations, explore prompts, detection tables, and merge strategy are in:
@reference.md

---

## Arguments

$ARGUMENTS

If arguments contain `--force`: ignore existing profile, run full setup from scratch.

---

## Phase 1: User Profile

Collect user identity and preferences. Profile is stored globally at `~/.omb/profile.json`.

### Step 1.1: Profile Detection

If `profile_exists` is true AND `--force` is NOT set:

```
AskUserQuestion:
  question: "Found existing omb profile:\n\n  Username: {{username}}\n  Notes: {{notes_preview}}\n  Community: {{community_status}}\n\nWhat would you like to do?"
  header: "Profile"
  options:
    - label: "Keep current"
      description: "Skip profile setup, keep existing profile as-is"
    - label: "Update"
      description: "Walk through profile setup and update specific fields"
    - label: "Start fresh"
      description: "Delete existing profile and create a new one"
```

- If "Keep current" → skip to Phase 2 (Slack Configuration)
- If "Update" → proceed with pre-filled values
- If "Start fresh" → clear existing data, proceed as new

If `profile_exists` is false OR `--force` is set → proceed directly to Step 1.2.

### Step 1.2: Username

```
AskUserQuestion:
  question: "What's your name or username? (used for commit trailers and community posts)"
  header: "Username"
  options:
    - label: "{{git_user_name}}"
      description: "Detected from git config user.name (Recommended)"
    - label: "{{github_username}}"
      description: "Detected from gh auth status"
```

Detect defaults:
- Run `git config user.name` for git username
- Parse `gh auth status` output for GitHub username (if gh_available)
- Korean usernames are supported

Store as `username`.

### Step 1.3: Important Notes

```
AskUserQuestion:
  question: "What should Claude know about your projects?\n\n(Conventions, preferences, tech stack notes — these will be injected into CLAUDE.md)"
  header: "Notes"
  options:
    - label: "Enter notes"
      description: "Provide project conventions, preferences, or constraints"
    - label: "Skip for now"
      description: "Leave blank, can be added later via /omb setup"
```

If "Enter notes" → user provides free text via "Other" option.
If "Skip for now" → set `notes` to empty string.

Store as `notes`.

### Step 1.4: Write Profile

Write `~/.omb/profile.json` using the schema from @reference.md Section 1.

```json
{
  "username": "{{username}}",
  "notes": "{{notes}}",
  "community_joined": false,
  "repo_starred": false,
  "created_at": "{{iso8601_now}}",
  "updated_at": "{{iso8601_now}}"
}
```

For updates: preserve `created_at`, update `updated_at`, keep existing `community_joined`/`repo_starred` values.

Verify the write by reading back the file.

---

## Phase 2: Slack Configuration

Optional Slack notification setup. Credentials stored at `~/.claude/channels/slack/.env`.

### Step 2.1: Ask to Configure

```
AskUserQuestion:
  question: "Would you like to configure Slack notifications for omb?"
  header: "Slack"
  options:
    - label: "Configure Slack"
      description: "Set up bot token, signing secret, and channel ID for notifications"
    - label: "Skip (Recommended)"
      description: "Skip Slack setup — can be configured later via /omb slack-configure"
```

If "Skip" → proceed to Phase 3.

### Step 2.2: Collect Credentials

If "Configure Slack":

Ask for each credential one at a time:

1. **Bot Token:**
```
AskUserQuestion:
  question: "Enter your Slack Bot Token (starts with xoxb-)"
  header: "Bot Token"
  options:
    - label: "Enter token"
      description: "Paste your Slack bot token (use 'Other' to type)"
    - label: "Skip Slack"
      description: "Cancel Slack setup"
```

2. **Signing Secret:**
```
AskUserQuestion:
  question: "Enter your Slack Signing Secret"
  header: "Secret"
  options:
    - label: "Enter secret"
      description: "Paste your Slack signing secret (use 'Other' to type)"
    - label: "Skip Slack"
      description: "Cancel Slack setup"
```

3. **Channel ID:**
```
AskUserQuestion:
  question: "Enter the Slack Channel ID for notifications"
  header: "Channel"
  options:
    - label: "Enter channel ID"
      description: "Paste your channel ID (e.g., C01234ABCDE)"
    - label: "Skip Slack"
      description: "Cancel Slack setup"
```

If user selects "Skip Slack" at any point → proceed to Phase 3.

### Step 2.3: Write Credentials

Write to **both** locations (primary for notification service, legacy for channel bridge):

**Primary** (`~/.config/omb/slack.env` — read by `notification.py`):
```bash
mkdir -p ~/.config/omb/
```

Write `~/.config/omb/slack.env`:
```
SLACK_BOT_TOKEN={{bot_token}}
SLACK_SIGNING_SECRET={{signing_secret}}
SLACK_CHANNEL_ID={{channel_id}}
```

```bash
chmod 0600 ~/.config/omb/slack.env
```

**Legacy** (`~/.claude/channels/slack/.env` — read by channel bridge):
```bash
mkdir -p ~/.claude/channels/slack/
```

Write `~/.claude/channels/slack/.env`:
```
SLACK_BOT_TOKEN={{bot_token}}
SLACK_SIGNING_SECRET={{signing_secret}}
SLACK_CHANNEL_ID={{channel_id}}
```

```bash
chmod 0600 ~/.claude/channels/slack/.env
```

### Step 2.4: Flip Config Flag

Set `slack.enabled = true` in `.omb/config.json` so the pipeline knows notifications are active.

Read `.omb/config.json`, parse JSON, set `slack.enabled` to `true`, write back.

If `.omb/config.json` does not exist (setup running before project init), skip this step — the flag will be set when `omb init` runs.

Store `slack_configured = true` for summary.

---

## Phase 3: Project Scan (Silent Discovery)

No user interaction in this phase. Scan the codebase to prepare for questions.

### Step 3.1: Pre-flight Check

Detect existing files and set the execution mode.

1. Check for `./CLAUDE.md` (prefer root)
2. Check for `./.claude/CLAUDE.md` (fallback)
3. Check for `./PROJECT.md`
4. If BOTH `./CLAUDE.md` and `./.claude/CLAUDE.md` exist: warn the user, prefer root
5. Set mode:
   - **CREATE**: Neither CLAUDE.md nor PROJECT.md exists (create both from templates)
   - **PROJECT_ONLY**: PROJECT.md exists but no CLAUDE.md (create new CLAUDE.md; skip merge)
   - **UPDATE**: A CLAUDE.md exists (read existing content for merge/backup)
6. Read `~/.omb/profile.json` for `notes` field as `profile_notes` (written in Phase 1)

If mode is UPDATE:
- Read existing CLAUDE.md (and PROJECT.md if present) into memory
- Check for `<!-- omb:init-project` version marker
- Store existing content for merge in Phase 5

### Step 3.1.5: Gitignore Auto-Update (Silent)

Ensure the project's `.gitignore` covers harness and language-specific artifacts.
No user interaction — this is a silent housekeeping step.

1. Read `.gitignore` if it exists (create if missing)
2. Always add **harness entries** and **common entries**: see @reference.md Section 12
3. Skip language-specific entries for now (scan hasn't run yet) — those are added in Step 3.2.5
4. Use idempotent append: check each entry exists before adding (no duplicates)
5. Track additions in `scan_results.gitignore_updates[]` for Phase 7 summary display

### Step 3.2: Concurrent Scan

Invoke the `Agent` tool twice with `subagent_type: "explore"` and `model: "haiku"` — issue both calls in a single parallel batch. Use the prompts from @reference.md Section 5.

```
Agent 1: Tech Stack Scanner
- Output: languages, frameworks, databases, linters, formatters, test frameworks, build commands

Agent 2: Structure Scanner
- Output: repo type, directories, entry points, project identity, workspaces
```

Both agents MUST complete before proceeding to Step 3.2.5.

Collect and merge results into a `scan_results` object.

### Step 3.2.5: Language-Specific Gitignore Entries (Silent)

After scan completes, add language-specific `.gitignore` entries based on detected languages.

1. From `scan_results.languages`, look up language-specific entries in @reference.md Section 12
2. Use idempotent append (check before adding — no duplicates)
3. Append additions to `scan_results.gitignore_updates[]`

---

## Phase 4: Project Questions (Interactive)

### Profile Notes Injection

If `profile_notes` is non-empty (from Phase 3 Step 3.1), prepend to scan results context:
- "User preferences from profile: {{profile_notes}}"

### Step 4.1: Project Description

Generate 2-3 project description suggestions from scan results.

```
AskUserQuestion:
  question: "Based on the scan, here are suggested project descriptions:\n\n1. {{suggestion_1}}\n2. {{suggestion_2}}\n3. {{suggestion_3}}\n\nWhich best describes this project?"
  header: "Description"
  options:
    - label: "Option 1 (Recommended)"
      description: "{{suggestion_1}}"
    - label: "Option 2"
      description: "{{suggestion_2}}"
    - label: "Option 3"
      description: "{{suggestion_3}}"
```

### Step 4.2-4.8: Targeted Questions

Follow the question flow from @reference.md Section 6 (Q1-Q8):

- Q1: Project Identity (ALWAYS) — show detected name + description
- Q2: Repo Structure (IF detection < 90% confidence)
- Q3/Q3': Multi-repo paths or workspace confirmation (conditional)
- Q4: Tech Stack Gaps (ALWAYS)
- Q5: Testing Frameworks (IF not detected)
- Q6: CI/CD Setup (IF not detected)
- Q7: Key Conventions (ALWAYS)
- Q8: Final Check (ALWAYS)

**Fast Path:** When most is auto-detected: 3 questions minimum (Q1 + Q4 + Q8).
**Max Path:** Multi-repo with missing config: all 8 questions.

**Escape Hatch:** If user says "skip", "just generate", or "generate now" at ANY point:
1. Proceed with detected data only
2. Flag unconfirmed sections with `<!-- unconfirmed: auto-detected -->` comments
3. Continue to Phase 5

---

## Phase 5: Generation

### Step 5.1: Merge Strategy (UPDATE mode only)

For UPDATE mode, follow the merge strategy in @reference.md Section 7:
1. Backup existing file
2. Parse existing sections by `##` headers
3. Check for version marker
4. If marker found: replace AUTO-GENERATED sections, preserve user sections
5. If no marker: append under divider

### Step 5.2: Generate Files

Generate files using templates from @reference.md Sections 3 and 4:

1. **CLAUDE.md**: Fill template with scan results + user answers. Apply language convention tables.
2. **PROJECT.md**: Fill template with project identity, architecture, tech stack, entry points.

#### Write Confirmation (MANDATORY)

```
AskUserQuestion:
  # CREATE mode:
  question: "Ready to generate CLAUDE.md ({{N}} lines) + PROJECT.md ({{M}} lines). Write now?"
  options:
    - "Write now (Recommended)": Generate both files
    - "Show preview first": Display generated content before writing

  # UPDATE mode:
  question: "Will update {{N}} sections, preserve {{M}} sections. Backup at {{backupPath}}. Proceed?"
  options:
    - "Proceed (Recommended)": Apply updates with backup
    - "Show diff first": Display section-level changes before writing
```

### Step 5.3: Verify

Run checks on generated files:
1. CLAUDE.md contains `[HARD] Read PROJECT.md at session start`
2. PROJECT.md is under 200 lines
3. No empty `##` sections
4. No `{{` placeholders remaining

---

## Phase 6: Community (Optional)

### Step 6.1: Discussion Comment

**Skip if:**
- `gh_available` is false → show: "Install `gh` CLI and run `gh auth login` to enable community features."
- Profile already has `community_joined: true` AND this is not `--force`

```
AskUserQuestion:
  question: "Would you like to introduce yourself to the omb community?\n\nYour comment will be posted to GitHub Discussions."
  header: "Community"
  options:
    - label: "Yes, post a comment (Recommended)"
      description: "Share what you plan to build and how you feel about omb"
    - label: "Skip"
      description: "Skip community post"
```

If "Yes":
- Ask for intro message (or use default template)
- Post using GraphQL mutation from @reference.md Section 2
- On failure: show browser URL fallback from @reference.md Section 3

### Step 6.2: Star Repo

**Skip if:** `gh_available` is false, or profile already has `repo_starred: true`

```
AskUserQuestion:
  question: "Would you like to star the oh-my-braincrew repo on GitHub?"
  header: "Star"
  options:
    - label: "Yes, star it (Recommended)"
      description: "Stars teddynote-lab/oh-my-braincrew on GitHub"
    - label: "No thanks"
      description: "Skip starring"
```

If "Yes": `gh api -X PUT /user/starred/teddynote-lab/oh-my-braincrew`

### Step 6.3: Update Profile

Write back `community_joined` and `repo_starred` flags to `~/.omb/profile.json`.

---

## Phase 7: Summary

Show combined summary:

```markdown
## omb Setup Complete

| Category | Status |
|----------|--------|
| **Profile** | |
| Username | {{username}} |
| Notes | {{notes_preview_or_empty}} |
| **Slack** | {{configured / skipped}} |
| **Project** | |
| CLAUDE.md | {{created / updated}} ({{line_count}} lines) |
| PROJECT.md | {{created / updated}} ({{line_count}} lines) |
| **.gitignore** | {{Added N entries / Already complete}} |
| **Community** | |
| Discussion | {{posted / skipped}} |
| Star | {{yes / no}} |

Profile saved to `~/.omb/profile.json`.

### Next Steps
- Review the generated CLAUDE.md and PROJECT.md
- Run `/omb plan` to start planning your first task
```

## Completion Signal

When this skill completes, report your result clearly in the final output:

- On success: State "DONE" with a brief summary of what was accomplished
- On completion with concerns: State "DONE_WITH_CONCERNS" listing the concerns
- On failure: State "FAILED" with the reason
- On needing more context: State "NEEDS_CONTEXT" with what is missing

The session handler will read your output and advance the pipeline automatically.

**[HARD] STOP AFTER REPORTING**: After reporting your result, you MUST stop immediately. Do NOT invoke the next skill or output additional commentary. The pipeline system handles step transitions.
