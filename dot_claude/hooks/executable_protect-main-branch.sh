#!/bin/bash
# Block file edits on main/master branch
# Skip for personal (pei0804) repositories
#
# Uses the file_path from tool input to resolve the correct git repo,
# which is critical for worktrees where CWD may differ from the repo.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

# Determine the git directory from the file being edited
if [ -n "$FILE_PATH" ]; then
  FILE_DIR=$(dirname "$FILE_PATH")
  GIT_ARGS=(-C "$FILE_DIR")
else
  GIT_ARGS=()
fi

REMOTE=$(git "${GIT_ARGS[@]}" remote get-url origin 2>/dev/null)
if echo "$REMOTE" | grep -q "pei0804/"; then
  exit 0
fi

BRANCH=$(git "${GIT_ARGS[@]}" branch --show-current 2>/dev/null)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "Blocked: cannot edit files directly on $BRANCH branch" >&2
  exit 2
fi
