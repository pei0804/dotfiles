#!/bin/bash
# Block file edits on main/master branch
# Skip for personal (pei0804) repositories

REMOTE=$(git remote get-url origin 2>/dev/null)
if echo "$REMOTE" | grep -q "pei0804/"; then
  exit 0
fi

BRANCH=$(git branch --show-current 2>/dev/null)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo "Blocked: cannot edit files directly on $BRANCH branch" >&2
  exit 2
fi
