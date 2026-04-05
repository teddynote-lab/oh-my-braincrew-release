#!/usr/bin/env bash
# Parse a plan's markdown task table into a JSON array.
# Usage: parse-plan-tasks.sh <plan-file-path>
# Output: JSON array of task objects to stdout
set -euo pipefail

PLAN_FILE="${1:?Usage: parse-plan-tasks.sh <plan-file-path>}"

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

# Extract lines between ### Tasks header and next ### header (or EOF)
in_table=0
header_parsed=0
separator_skipped=0

echo "["
first=1

while IFS= read -r line; do
  # Detect start of Tasks section
  if [[ "$line" =~ ^###[[:space:]]+Tasks ]]; then
    in_table=1
    continue
  fi

  # Stop at next section header
  if [[ $in_table -eq 1 && "$line" =~ ^### && ! "$line" =~ ^###[[:space:]]+Tasks ]]; then
    break
  fi

  [[ $in_table -eq 0 ]] && continue

  # Skip empty lines
  [[ -z "${line// /}" ]] && continue

  # Skip table header row (contains "Task" and "Agent")
  if [[ $header_parsed -eq 0 && "$line" =~ \|.*Task.*\|.*Agent ]]; then
    header_parsed=1
    continue
  fi

  # Skip separator row (contains |---|)
  if [[ $separator_skipped -eq 0 && "$line" =~ \|[[:space:]]*-+ ]]; then
    separator_skipped=1
    continue
  fi

  # Must be a data row — parse pipe-delimited columns
  # Expected: | # | Task | Agent | Model | Depends On | Deliverable |
  # Strip leading/trailing pipes and whitespace
  cleaned=$(echo "$line" | sed 's/^[[:space:]]*|//;s/|[[:space:]]*$//')

  # Split by pipe into array
  IFS='|' read -ra cols <<< "$cleaned"

  # Need at least 6 columns
  [[ ${#cols[@]} -lt 6 ]] && continue

  id=$(echo "${cols[0]}" | xargs)
  task=$(echo "${cols[1]}" | xargs | sed 's/"/\\"/g')
  agent=$(echo "${cols[2]}" | xargs | tr '[:upper:]' '[:lower:]')
  model=$(echo "${cols[3]}" | xargs | tr '[:upper:]' '[:lower:]')
  depends_raw=$(echo "${cols[4]}" | xargs)
  deliverable=$(echo "${cols[5]}" | xargs | sed 's/"/\\"/g')

  # Skip non-numeric IDs (garbage rows)
  [[ ! "$id" =~ ^[0-9]+$ ]] && continue

  # Parse depends_on: handle "—", "---", "-", empty as no dependencies
  depends_on="[]"
  if [[ -n "$depends_raw" && ! "$depends_raw" =~ ^[-—]+$ ]]; then
    # Split comma-separated dependency IDs, trim whitespace
    deps=""
    IFS=',' read -ra dep_parts <<< "$depends_raw"
    for dep in "${dep_parts[@]}"; do
      dep_trimmed=$(echo "$dep" | xargs)
      [[ -z "$dep_trimmed" ]] && continue
      [[ ! "$dep_trimmed" =~ ^[0-9]+$ ]] && continue
      if [[ -z "$deps" ]]; then
        deps="$dep_trimmed"
      else
        deps="$deps,$dep_trimmed"
      fi
    done
    if [[ -n "$deps" ]]; then
      depends_on="[$deps]"
    fi
  fi

  # Output JSON object
  if [[ $first -eq 1 ]]; then
    first=0
  else
    echo ","
  fi
  printf '  {"id":%s,"task":"%s","agent":"%s","model":"%s","depends_on":%s,"deliverable":"%s"}' \
    "$id" "$task" "$agent" "$model" "$depends_on" "$deliverable"

done < "$PLAN_FILE"

echo ""
echo "]"
