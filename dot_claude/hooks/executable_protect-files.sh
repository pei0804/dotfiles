#!/bin/bash
# Block writes to sensitive/generated files
# stdin: JSON with tool_input.file_path

FILE=$(jq -r .tool_input.file_path)

PROTECTED=(
  ".env"
  ".env.local"
  ".env.production"
  ".git/"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  "Gemfile.lock"
  "poetry.lock"
)

for p in "${PROTECTED[@]}"; do
  if echo "$FILE" | grep -qF "$p"; then
    echo "Blocked: protected file \"$p\" detected" >&2
    exit 2
  fi
done
