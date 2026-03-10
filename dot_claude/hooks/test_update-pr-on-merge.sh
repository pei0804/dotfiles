#!/bin/bash
# Test script for update-pr-on-merge.sh hook
# Tests pattern matching and exit behavior without actual GitHub API calls

HOOK="$(dirname "$0")/executable_update-pr-on-merge.sh"
PASS=0
FAIL=0

assert_exit() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" -eq "$expected" ]]; then
    echo "PASS: $desc (exit=$actual)"
    ((PASS++))
  else
    echo "FAIL: $desc (expected exit=$expected, got exit=$actual)"
    ((FAIL++))
  fi
}

assert_output_contains() {
  local desc="$1" pattern="$2" output="$3"
  if grep -q "$pattern" <<< "$output"; then
    echo "PASS: $desc (output contains '$pattern')"
    ((PASS++))
  else
    echo "FAIL: $desc (output missing '$pattern')"
    ((FAIL++))
  fi
}

# --- Test 1: Non-merge command should exit 0 silently ---
OUTPUT=$(echo '{"tool_input":{"command":"gh pr view 123"},"tool_result":{"stdout":""}}' | bash "$HOOK" 2>&1)
assert_exit "Non-merge command exits silently" 0 $?
if [[ -z "$OUTPUT" ]]; then
  echo "PASS: Non-merge command produces no output"
  ((PASS++))
else
  echo "FAIL: Non-merge command should produce no output, got: $OUTPUT"
  ((FAIL++))
fi

# --- Test 2: Merge command with failed response (no sha) should exit 0 silently ---
OUTPUT=$(echo '{"tool_input":{"command":"gh api repos/owner/repo/pulls/42/merge -X PUT -f merge_method=merge"},"tool_result":{"stdout":"{\"message\":\"Pull Request is not mergeable\"}"}}' | bash "$HOOK" 2>&1)
assert_exit "Failed merge exits silently" 0 $?
if [[ -z "$OUTPUT" ]]; then
  echo "PASS: Failed merge produces no output"
  ((PASS++))
else
  echo "FAIL: Failed merge should produce no output, got: $OUTPUT"
  ((FAIL++))
fi

# --- Test 3: Merge command pattern detection variants ---
for CMD in \
  "gh api repos/owner/repo/pulls/123/merge -X PUT -f merge_method=merge" \
  "gh api repos/my-org/my-repo/pulls/9999/merge -X PUT" \
  "gh api repos/foo/bar/pulls/1/merge"; do

  # These should match the pattern but fail on sha check (no sha in response)
  OUTPUT=$(echo "{\"tool_input\":{\"command\":\"$CMD\"},\"tool_result\":{\"stdout\":\"{}\"}}" | bash "$HOOK" 2>&1)
  assert_exit "Pattern matches: $CMD" 0 $?
  if [[ -z "$OUTPUT" ]]; then
    echo "PASS: No sha → no output for: $CMD"
    ((PASS++))
  else
    echo "FAIL: Should produce no output without sha: $CMD"
    ((FAIL++))
  fi
done

# --- Test 4: Non-matching patterns should be ignored ---
for CMD in \
  "gh api repos/owner/repo/pulls/123" \
  "gh pr merge 123" \
  "echo hello" \
  "gh api repos/owner/repo/issues/123/merge"; do

  OUTPUT=$(echo "{\"tool_input\":{\"command\":\"$CMD\"},\"tool_result\":{\"stdout\":\"\"}}" | bash "$HOOK" 2>&1)
  assert_exit "Non-matching: $CMD" 0 $?
  if [[ -z "$OUTPUT" ]]; then
    echo "PASS: Correctly ignored: $CMD"
    ((PASS++))
  else
    echo "FAIL: Should be ignored: $CMD, got: $OUTPUT"
    ((FAIL++))
  fi
done

# --- Test 5: Successful merge triggers output (will fail on gh api calls, but tests the flow) ---
# We test that the pattern + sha detection works, even though gh api calls will fail
MERGE_RESPONSE='{"sha":"abc123def456","merged":true,"message":"Pull Request successfully merged"}'
OUTPUT=$(echo "{\"tool_input\":{\"command\":\"gh api repos/test-owner/test-repo/pulls/42/merge -X PUT -f merge_method=merge\"},\"tool_result\":{\"stdout\":$MERGE_RESPONSE}}" | bash "$HOOK" 2>&1)
assert_exit "Successful merge triggers hook" 0 $?
assert_output_contains "Output mentions PR number" "#42" "$OUTPUT"
assert_output_contains "Output mentions repo" "test-owner/test-repo" "$OUTPUT"
assert_output_contains "Output has update instructions" "gh pr edit" "$OUTPUT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
