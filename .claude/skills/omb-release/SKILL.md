---
name: omb-release
user-invocable: true
description: >
  Use when releasing a new version — handles version bump (default: patch),
  changelog generation (AI-summarized, public-facing), git tagging, PyPI publish,
  binary builds (via CI), and public release repo update with changelog and README.
argument-hint: "[major|minor|patch] [additional comment]"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

## Release Pipeline

**IMPORTANT**: Do NOT use `scripts/release.sh` as a shortcut. Follow all 12 steps below. The script is a fallback for manual CLI use only — it does not generate AI-summarized changelogs.

### Step 1: Parse Arguments

Parse `$ARGUMENTS`:
- [HARD] Default bump type is `patch`. First word: if it matches `major`, `minor`, `patch`, or semver pattern `X.Y.Z`, use as bump type. Otherwise default to `patch` and treat all of `$ARGUMENTS` as the additional comment.
- Remaining text after bump type: additional comment for the changelog.

### Step 2: Pre-flight Checks

Verify the working tree is clean:

```bash
git diff --quiet && git diff --cached --quiet
```

If not clean, report dirty state and abort.

Also verify the target tag does not already exist (checked after version calculation in Step 3).

### Step 3: Calculate Version

Read current version from `.claude-plugin/plugin.json` (the `"version"` field).

Apply the bump:
- `patch`: increment the third number (0.0.18 → 0.0.19)
- `minor`: increment the second number, reset third (0.0.18 → 0.1.0)
- `major`: increment the first number, reset others (0.0.18 → 1.0.0)
- `X.Y.Z`: use the explicit version directly

Verify the tag `vX.Y.Z` does not already exist: `git tag -l "vX.Y.Z"`. Abort if it does.

### Step 4: Generate Changelog Entry

1. Get all commits since the last release tag:
   ```bash
   git log v<current>..HEAD --pretty=format:"%H %s"
   ```

2. **Summarize** the commits into a human-readable changelog. Do NOT just list raw commit messages. Read the commits, understand what changed, and write a concise summary grouped by category:
   - **Added** — new features, capabilities, skills, agents
   - **Changed** — modifications to existing behavior, refactors
   - **Fixed** — bug fixes
   - **Documentation** — docs-only changes
   - **Maintenance** — chore, CI, deps, tests

   Rules:
   - Each bullet should be a clear, user-facing description (not a raw commit message).
   - Omit empty categories.
   - If user provided an additional comment, include it as a **Notes** section at the top of the entry.

3. Format as Keep a Changelog: `## [X.Y.Z] - YYYY-MM-DD`

4. If `CHANGELOG.md` does not exist, create it with the standard header first:
   ```markdown
   # Changelog

   All notable changes to this project will be documented in this file.

   The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
   and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
   ```

5. Prepend the new entry below the header (after the "Semantic Versioning" line).

### Step 5: Display Changelog

Display the generated changelog entry to the user for reference, then proceed automatically to Step 6. No confirmation required.

### Step 6: Update Version Files

Update the `"version"` field in:
- `pyproject.toml` (the `version = "X.Y.Z"` line under `[project]`)
- `.claude-plugin/plugin.json`

Use `jq` if available for JSON, otherwise use `Edit` tool for precise string replacement.

### Step 7: Build Python Package

```bash
uv build
```

If `uv build` fails, report the error and abort. Do not proceed with a broken package.

### Step 8: Commit and Tag

```bash
git add -A
```

Commit with message: `release: vX.Y.Z`

Create annotated tag:
```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
```

### Step 9: Push

Push the commit and tag to remote:

```bash
git push && git push --tags
```

### Step 10: Publish to PyPI

After pushing, publish the built package to PyPI:

1. Load the token from `.env`:
   ```bash
   source .env
   ```

2. Upload using `uv publish`:
   ```bash
   uv publish --token "$PYPI_API_TOKEN"
   ```

If `uv publish` fails, report the error. The git tag and push are already done — the user can retry the publish manually.

### Step 11: Create GitHub Release

After publishing, create a GitHub Release with the changelog entry as the body:

```bash
gh release create vX.Y.Z --title "vX.Y.Z" --notes "<changelog entry content>"
```

The `--notes` body should contain the full changelog entry generated in Step 4 (the `## [X.Y.Z] - YYYY-MM-DD` section with all categories).

If `gh` CLI is not available, skip this step and note it in the report.

### Step 12: Update Public Release Repo

The public release repo (`teddynote-lab/oh-my-braincrew-release`) serves binary distributions to end users. Update it with the changelog and latest install scripts.

1. Clone (or pull) the release repo:
   ```bash
   RELEASE_REPO_DIR=$(mktemp -d)/oh-my-braincrew-release
   git clone https://github.com/teddynote-lab/oh-my-braincrew-release.git "$RELEASE_REPO_DIR"
   ```

2. **Generate public-facing changelog** — read the internal CHANGELOG.md entry generated in Step 4. Rewrite it for public consumption:
   - Focus on **user-facing features and fixes** only.
   - Remove internal details (harness internals, agent restructuring, skill refactoring).
   - Group into: **Added**, **Fixed**, **Improved** (omit empty categories).
   - Keep each bullet concise and clear.

3. **Prepend to CHANGELOG.md** in the release repo:
   - Insert the new `## [X.Y.Z] - YYYY-MM-DD` entry after the header.

4. **Update README.md** version references in the download table (replace `omb-v*-` with `omb-vX.Y.Z-`).

5. **Copy latest install scripts**:
   ```bash
   cp scripts/install.sh "$RELEASE_REPO_DIR/install.sh"
   cp scripts/install.ps1 "$RELEASE_REPO_DIR/install.ps1"
   ```

6. **Commit and push**:
   ```bash
   cd "$RELEASE_REPO_DIR"
   git add -A
   git commit -m "release: vX.Y.Z — update changelog, README, and install scripts"
   git push
   ```

7. **Note**: Binary builds and GitHub Release creation on the public repo happen automatically via the `release-binary.yml` CI workflow triggered by the tag push in Step 9. The CI also generates checksums and attaches binaries as release assets.

### Step 13: Report

Output a summary:
```
Release complete:
  Old version:    <old>
  New version:    <new>
  Changelog:      CHANGELOG.md updated (internal + public)
  Tag:            vX.Y.Z
  Package:        built via uv build
  Push:           pushed
  PyPI:           published oh-my-braincrew vX.Y.Z
  GitHub:         release created at <URL> (private repo)
  Public repo:    CHANGELOG.md + README.md updated
  Binary builds:  triggered via CI → teddynote-lab/oh-my-braincrew-release
```
