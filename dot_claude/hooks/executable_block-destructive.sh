#!/bin/bash
# Block destructive commands in Bash tool
# stdin: JSON with tool_input.command

CMD=$(jq -r .tool_input.command)

# Strip heredoc bodies and quoted strings to avoid matching commit messages etc.
CLEAN_CMD=$(echo "$CMD" | sed '/<<.*EOF/,/^EOF$/d' | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "DROP TABLE"
  "drop table"
  "TRUNCATE"
  "truncate"
  "push .* --force( |$)"
  "push .* -f( |$)"
  "reset --hard"
)

for p in "${PATTERNS[@]}"; do
  if echo "$CLEAN_CMD" | grep -qiE "$p"; then
    echo "Blocked: destructive pattern \"$p\" detected" >&2
    exit 2
  fi
done
