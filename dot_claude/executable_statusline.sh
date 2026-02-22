#!/bin/bash
# Claude Code statusline - 3-column display

# Read stdin JSON
INPUT=$(cat)
json() { echo "$INPUT" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print($1)" 2>/dev/null; }

CWD=$(json "d.get('workspace',{}).get('current_dir','')")
[ -z "$CWD" ] && CWD=$(pwd)

# --- Column 1: Directory ---
DIR=$(echo "$CWD" | sed "s|^$HOME|~|")
COL1="📂 $DIR"

# --- Column 2: Model / Tokens / Context / Latency ---
MODEL=$(json "d.get('model',{}).get('display_name','Claude')")
INPUT_TOKENS=$(json "d.get('context_window',{}).get('total_input_tokens',0)")
OUTPUT_TOKENS=$(json "d.get('context_window',{}).get('total_output_tokens',0)")
USED=$(json "d.get('context_window',{}).get('used_percentage',0)")
DURATION_MS=$(json "d.get('cost',{}).get('total_api_duration_ms',0)")
LATENCY=$(echo "scale=1; ${DURATION_MS:-0} / 1000" | bc 2>/dev/null || echo "0")

USED_INT=${USED%.*}
if [ "${USED_INT:-0}" -ge 90 ]; then
  CTX_LABEL="Context: ${USED}% [!!!CRITICAL - /compact NOW]"
elif [ "${USED_INT:-0}" -ge 80 ]; then
  CTX_LABEL="Context: ${USED}% [!! /compact recommended]"
else
  CTX_LABEL="Context: ${USED}%"
fi

COL2="${MODEL} | ${INPUT_TOKENS}/${OUTPUT_TOKENS} tokens | ${CTX_LABEL} | ${LATENCY}s"

# --- Column 3: Git / GitHub ---
COL3=""
cd "$CWD" 2>/dev/null && git rev-parse --git-dir &>/dev/null && {
  BRANCH=$(git branch --show-current 2>/dev/null)
  [ -z "$BRANCH" ] && BRANCH=$(git rev-parse --short HEAD 2>/dev/null)

  TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null)
  GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null)
  WORKTREE=""
  if [ "$GIT_COMMON" != ".git" ] && [ "$GIT_COMMON" != "$(git rev-parse --git-dir 2>/dev/null)" ]; then
    WORKTREE=$(basename "$TOPLEVEL")
  fi

  # PR info with cache (60s TTL)
  CACHE_DIR="/tmp/claude-statusline-cache"
  mkdir -p "$CACHE_DIR"
  CACHE_KEY=$(echo "$TOPLEVEL:$BRANCH" | md5 2>/dev/null || echo "$TOPLEVEL:$BRANCH" | md5sum 2>/dev/null | cut -d' ' -f1)
  CACHE_FILE="$CACHE_DIR/$CACHE_KEY"

  if [ -f "$CACHE_FILE" ] && [ -n "$(find "$CACHE_FILE" -newermt '60 seconds ago' 2>/dev/null || find "$CACHE_FILE" -mmin -1 2>/dev/null)" ]; then
    PR_DATA=$(cat "$CACHE_FILE")
  else
    PR_DATA=$(gh pr view --json number,title,url -q '"\(.url)\t#\(.number) \(.title)"' 2>/dev/null || echo "")
    echo "$PR_DATA" > "$CACHE_FILE"
  fi

  PR_URL=$(echo "$PR_DATA" | cut -f1)
  PR_TEXT=$(echo "$PR_DATA" | cut -f2-)

  COL3="🌿 $BRANCH"
  [ -n "$WORKTREE" ] && COL3="$COL3 | 🌳 $WORKTREE"
  ESC=$'\e'
  if [ -n "$PR_TEXT" ] && [ -n "$PR_URL" ]; then
    COL3="$COL3 | 🔀 ${ESC}]8;;${PR_URL}${ESC}\\${PR_TEXT}${ESC}]8;;${ESC}\\"
  fi
}

# Output: 1=Dir, 2=Git/GitHub, 3=Claude
echo "$COL1"
[ -n "$COL3" ] && echo "$COL3"
echo "$COL2"
