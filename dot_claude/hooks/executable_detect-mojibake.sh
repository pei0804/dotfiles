#!/bin/bash
# Detect mojibake (garbled characters) in Edit/Write content
# PreToolUse hook - blocks writes containing UTF-8 replacement characters
# stdin: JSON with tool_input

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [ "$TOOL_NAME" = "Edit" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
elif [ "$TOOL_NAME" = "Write" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
else
  exit 0
fi

# Skip empty content
[ -z "$CONTENT" ] && exit 0

# Check for U+FFFD replacement character (raw bytes: \xef\xbf\xbd)
if printf '%s' "$CONTENT" | LC_ALL=C grep -qc $'\xef\xbf\xbd'; then
  echo "BLOCKED: 文字化け検出 - U+FFFD (replacement character) が含まれています。内容を確認して正しい文字で書き直してください。" >&2
  exit 2
fi

# Check for common double-encoding mojibake patterns
# These appear when UTF-8 bytes are misinterpreted as Latin-1 then re-encoded
MOJIBAKE_PATTERNS=(
  'Ã©'   # é double-encoded
  'Ã¨'   # è
  'Ã¯'   # ï
  'Ã¼'   # ü
  'Ã¶'   # ö
  'Ã¤'   # ä
  'Ã¡'   # á
  'Ã±'   # ñ
  'ÃŸ'   # ß
  'â€™'  # ' (right single quote) double-encoded
  'â€œ'  # " double-encoded
  'â€'  # " double-encoded
  'â€"'  # — double-encoded
  'â€"'  # – double-encoded
  'ï¿½'  # U+FFFD as mojibake
)

for p in "${MOJIBAKE_PATTERNS[@]}"; do
  if printf '%s' "$CONTENT" | grep -qF "$p"; then
    echo "BLOCKED: 文字化け検出 - 二重エンコードパターン \"$p\" が含まれています。内容を確認して正しい文字で書き直してください。" >&2
    exit 2
  fi
done

exit 0
