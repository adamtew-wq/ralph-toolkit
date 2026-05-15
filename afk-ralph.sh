#!/usr/bin/env bash
# afk-ralph.sh — autonomous Ralph loop inside Docker sandbox
#
# Each iteration runs in an isolated container (`docker sandbox run claude`).
# The loop terminates when the agent emits <promise>COMPLETE</promise> or
# the iteration cap is reached.
#
# Usage:
#   ./afk-ralph.sh            # default 10 iterations
#   ./afk-ralph.sh 20         # cap at 20 iterations
#
# Cost control: each iteration consumes Anthropic credits. Start small
# (e.g. ./afk-ralph.sh 3) and inspect commits before going wider.

set -e

cd "$(dirname "$0")"

MAX_ITERATIONS="${1:-10}"
PROMPT_FILE="ralph-prompt.md"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "error: $PROMPT_FILE not found in $(pwd)" >&2
  exit 1
fi

PROMPT_BODY="$(cat "$PROMPT_FILE")"

for ((i=1; i<=MAX_ITERATIONS; i++)); do
  echo ""
  echo "=========================================="
  echo "Ralph iteration $i / $MAX_ITERATIONS"
  echo "=========================================="
  echo ""

  OUTPUT=$(docker sandbox run claude . -- \
    --permission-mode acceptEdits \
    -p \
    "$PROMPT_BODY

---

Reference files for this iteration:
@ralph-prompt.md
@progress.txt" 2>&1)

  echo "$OUTPUT"

  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "=========================================="
    echo "Ralph signalled COMPLETE on iteration $i."
    echo "=========================================="
    exit 0
  fi
done

echo ""
echo "=========================================="
echo "Iteration cap ($MAX_ITERATIONS) reached without COMPLETE."
echo "Inspect progress.txt and the open issues before re-running."
echo "=========================================="
