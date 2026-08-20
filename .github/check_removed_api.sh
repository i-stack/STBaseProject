#!/usr/bin/env bash
set -euo pipefail

readonly SEARCH_ROOTS=(Sources Example)
readonly REMOVED_API_PATTERN='\bst_request[[:space:]]*\(|\bst_detectJailbreak[[:space:]]*\(|\bst_detectSimulator[[:space:]]*\(|\blegacyDictionary\b'

if rg --line-number --glob '*.swift' "$REMOVED_API_PATTERN" "${SEARCH_ROOTS[@]}"; then
  echo "::error::Removed API usage detected. Use the current public API directly."
  exit 1
fi

echo "Removed API check passed."
