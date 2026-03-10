#!/bin/bash
# PostToolUse hook: After a successful PR merge, instruct Claude to update PR title and body
# to accurately reflect the actual merged changes.
#
# Trigger: Bash commands matching `gh api repos/.../pulls/.../merge`
# Input:   JSON with .tool_input.command and .tool_result.stdout

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<< "$INPUT")

# Only trigger on merge API calls
if ! grep -qE 'gh api repos/[^/]+/[^/]+/pulls/[0-9]+/merge' <<< "$COMMAND"; then
  exit 0
fi

# Check if merge succeeded (successful merge response contains "sha")
STDOUT=$(jq -r '.tool_result.stdout // empty' <<< "$INPUT")
if ! jq -e '.sha' <<< "$STDOUT" >/dev/null 2>&1; then
  exit 0
fi

# Extract repo and PR number from command
REPO=$(grep -oE 'repos/[^/]+/[^/]+' <<< "$COMMAND" | head -1 | sed 's/^repos\///')
PR_NUMBER=$(grep -oE 'pulls/[0-9]+' <<< "$COMMAND" | head -1 | sed 's/^pulls\///')

if [[ -z "$REPO" || -z "$PR_NUMBER" ]]; then
  exit 0
fi

# Gather context for Claude: commits and files changed
COMMITS=$(gh api "repos/$REPO/pulls/$PR_NUMBER/commits" \
  --jq '.[] | "- " + (.commit.message | split("\n")[0])' 2>/dev/null)
FILES=$(gh api "repos/$REPO/pulls/$PR_NUMBER/files" \
  --jq '.[] | "- " + .filename + " (" + .status + ", +" + (.additions|tostring) + " -" + (.changes - .additions | tostring) + ")"' 2>/dev/null)
CURRENT=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json title,body \
  --jq '"Current title: " + .title + "\nCurrent body:\n" + .body' 2>/dev/null)

cat <<EOF
PR #$PR_NUMBER ($REPO) was successfully merged.

Please update the PR title and body to accurately reflect what was actually merged.

$CURRENT

Commits merged:
$COMMITS

Files changed:
$FILES

Instructions:
1. Review the commits and files above
2. Update the PR title to concisely describe the actual changes (keep under 70 chars)
3. Update the PR body with a clear summary of what was merged
4. Use: gh pr edit $PR_NUMBER --repo $REPO --title "..." --body "..."
EOF
