#!/usr/bin/env bash
# ralph-once.sh — run a single Ralph iteration on the host machine (HITL)
#
# Use this to validate the prompt and the agent's behaviour before running
# afk-ralph.sh autonomously. After each run, inspect the diff, the commit,
# and the updated progress.txt before running again.
#
# Usage:
#   ./ralph-once.sh

set -e

cd "$(dirname "$0")"

if [[ ! -f ralph-prompt.md ]]; then
  echo "error: ralph-prompt.md not found in $(pwd)" >&2
  exit 1
fi

claude \
  --permission-mode acceptEdits \
  "$(cat ralph-prompt.md)

---

Reference files for this iteration:
@ralph-prompt.md
@progress.txt"
