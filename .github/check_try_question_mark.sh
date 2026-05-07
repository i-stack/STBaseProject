#!/usr/bin/env bash
set -euo pipefail

matches="$(rg -n 'try\?' Sources --glob '!STMarkdown/Resources/**' || true)"
allowed='container\.decode|decoder\.decode|JSONSerialization\.jsonObject|NSRegularExpression|Task\.sleep'
violations=""

while IFS= read -r line; do
  [ -z "$line" ] && continue
  if ! printf '%s\n' "$line" | rg -q "$allowed"; then
    violations="${violations}${line}"$'\n'
  fi
done <<< "$matches"

if [ -n "$violations" ]; then
  cat <<'EOF'
Disallowed try? usage found.

Policy:
- Boundary IO and security-sensitive operations must use do/catch or Result<T, Error>.
- try? is allowed only for explicit best-effort decode/probe cases, such as JSON decoding,
  Codable decode attempts, regex compilation probes, and cancellable Task.sleep.

Violations:
EOF
  printf '%s' "$violations"
  exit 1
fi

echo "try? policy check passed."
