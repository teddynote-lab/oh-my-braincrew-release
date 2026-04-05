#!/usr/bin/env bash
# Verify tracking code comments exist in deliverable files.
# Usage: check-spec-comments.sh <tracking-code> [file1 file2 ...] or stdin
# Output: JSON {"pass":["file1"],"fail":["file2"]}, exit 0 if all pass, 1 if any fail
set -euo pipefail

TRACKING_CODE="${1:?Usage: check-spec-comments.sh <tracking-code> [file1 file2 ...]}"
shift

# Collect file paths from args or stdin
files=()
if [[ $# -gt 0 ]]; then
  files=("$@")
else
  while IFS= read -r f; do
    [[ -n "$f" ]] && files+=("$f")
  done
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo '{"pass":[],"fail":[]}'
  exit 0
fi

pass=()
fail=()

for f in "${files[@]}"; do
  if [[ ! -f "$f" ]]; then
    fail+=("$f")
    continue
  fi
  if grep -q "$TRACKING_CODE" "$f" 2>/dev/null; then
    pass+=("$f")
  else
    fail+=("$f")
  fi
done

# Build JSON output
printf '{"pass":['
first=1
for p in "${pass[@]}"; do
  [[ $first -eq 0 ]] && printf ','
  printf '"%s"' "$p"
  first=0
done
printf '],"fail":['
first=1
for f in "${fail[@]}"; do
  [[ $first -eq 0 ]] && printf ','
  printf '"%s"' "$f"
  first=0
done
printf ']}\n'

# Exit 1 if any failures
[[ ${#fail[@]} -gt 0 ]] && exit 1
exit 0
