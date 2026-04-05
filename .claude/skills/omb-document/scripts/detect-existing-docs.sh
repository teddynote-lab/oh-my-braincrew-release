#!/usr/bin/env bash
# Scans docs/ directories for existing documentation files matching detected doc types.
# Usage: bash detect-doc-types.sh <plan> | bash detect-existing-docs.sh
# Input: JSON from stdin (output of detect-doc-types.sh)
# Output: JSON mapping doc types (with needed: true) to arrays of existing file objects
set -euo pipefail

# Read JSON from stdin and process entirely in python3 for robustness
# (avoids bash 3.x associative array limitation on macOS)
python3 -c "
import json, os, sys

data = json.loads(sys.stdin.read())

# Doc type to directory mapping
# Skip readme and document_record (not docs/ directories)
# Explicitly skip docs/claude-code-docs/ (READ ONLY) and docs/plugin-dev-docs/ (non-standard)
TYPE_TO_DIR = {
    'adr': 'docs/adr',
    'api': 'docs/api',
    'db': 'docs/db',
    'architecture': 'docs/architecture',
    'guides': 'docs/guides',
    'langchain': 'docs/langchain',
    'frontend': 'docs/frontend',
    'electron': 'docs/electron',
    'infra': 'docs/infra',
    'testing': 'docs/testing',
    'security': 'docs/security',
    'prompts': 'docs/prompts',
}

MAX_FILES_PER_TYPE = 5

result = {}

for doc_type, info in data.items():
    # Only include doc types with needed: true
    if not isinstance(info, dict) or not info.get('needed', False):
        continue

    # Skip types that have no docs/ directory mapping
    if doc_type not in TYPE_TO_DIR:
        continue

    dir_path = TYPE_TO_DIR[doc_type]
    files = []

    if os.path.isdir(dir_path):
        entries = sorted(
            f for f in os.listdir(dir_path)
            if f.endswith('.md') and os.path.isfile(os.path.join(dir_path, f))
        )
        for entry in entries[:MAX_FILES_PER_TYPE]:
            files.append({
                'path': os.path.join(dir_path, entry),
                'reason': 'existing ' + doc_type.upper() + ' docs'
            })

    result[doc_type] = files

print(json.dumps(result, indent=2))
"
