#!/bin/bash
# Parse command-audit.log and output structured JSON
# Usage: parse-audit.sh [--after YYYY-MM-DD] [--before YYYY-MM-DD]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIT_LOG="$HOME/.claude/command-audit.log"

if [ ! -f "$AUDIT_LOG" ]; then
  echo '{"error": "audit log not found", "path": "'"$AUDIT_LOG"'"}'
  exit 1
fi

python3 "$SCRIPT_DIR/parse_audit.py" "$AUDIT_LOG" "$@"
