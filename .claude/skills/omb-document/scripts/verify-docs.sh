#!/usr/bin/env bash
# Verifies documentation files associated with a tracking code.
# Usage: bash verify-docs.sh <tracking-code>
# Output: JSON {pass: [...], fail: [...], warnings: [...]}
set -euo pipefail

TRACKING_CODE="${1:-}"

if [[ -z "$TRACKING_CODE" ]]; then
  echo "ERROR: Tracking code required" >&2
  exit 1
fi

PASS=()
FAIL=()
WARNINGS=()

# Find all files containing the tracking code comment
# Collect README files (including i18n variants like README.ko.md)
README_FILES="README.md"
for rf in README.*.md; do
  [[ -f "$rf" ]] && README_FILES="$README_FILES $rf"
done
DOC_FILES=$(grep -rl "$TRACKING_CODE" docs/ .omb/documents/ $README_FILES 2>/dev/null || true)

if [[ -z "$DOC_FILES" ]]; then
  cat <<EOF
{"pass": [], "fail": [], "warnings": ["No documentation files found containing tracking code: $TRACKING_CODE"]}
EOF
  exit 0
fi

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # Check 1: File exists (should always be true since grep found it)
  if [[ ! -f "$file" ]]; then
    FAIL+=("\"$file: file not found\"")
    continue
  fi

  # Check 2: File is non-empty
  if [[ ! -s "$file" ]]; then
    FAIL+=("\"$file: file is empty\"")
    continue
  fi

  # Check 3: Valid markdown structure (has at least one header)
  if [[ "$file" == *.md ]]; then
    if ! grep -qE '^#{1,6} ' "$file"; then
      WARNINGS+=("\"$file: no markdown headers found\"")
    fi
  fi

  # Check 4: Check for broken relative links
  # Extract markdown links: [text](relative/path)
  LINKS=$(grep -oE '\[([^]]*)\]\(([^)]*)\)' "$file" 2>/dev/null | grep -oE '\(([^)]*)\)' | tr -d '()' || true)

  if [[ -n "$LINKS" ]]; then
    FILE_DIR=$(dirname "$file")
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      # Skip external URLs, anchors, and absolute paths
      if [[ "$link" == http* || "$link" == \#* || "$link" == /* || "$link" == mailto:* ]]; then
        continue
      fi
      # Remove anchor from link
      link_path="${link%%#*}"
      [[ -z "$link_path" ]] && continue
      # Resolve relative to file directory
      if [[ ! -e "$FILE_DIR/$link_path" ]]; then
        WARNINGS+=("\"$file: broken link to $link_path\"")
      fi
    done <<< "$LINKS"
  fi

  PASS+=("\"$file\"")

done <<< "$DOC_FILES"

# Format arrays as JSON
format_array() {
  local arr=("$@")
  if [[ ${#arr[@]} -eq 0 ]]; then
    echo "[]"
    return
  fi
  local result="["
  local first=true
  for item in "${arr[@]}"; do
    if [[ "$first" == "true" ]]; then
      first=false
    else
      result+=", "
    fi
    result+="$item"
  done
  result+="]"
  echo "$result"
}

PASS_JSON=$(format_array "${PASS[@]+"${PASS[@]}"}")
FAIL_JSON=$(format_array "${FAIL[@]+"${FAIL[@]}"}")
WARN_JSON=$(format_array "${WARNINGS[@]+"${WARNINGS[@]}"}")

cat <<EOF
{"pass": $PASS_JSON, "fail": $FAIL_JSON, "warnings": $WARN_JSON}
EOF
