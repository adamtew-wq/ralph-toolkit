#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

for ((i=1; i<=$1; i++)); do
  result=$(docker sandbox run claude --permission-mode acceptEdits -p "@progress.txt \
  1. Run 'gh issue list --label ready-for-agent --state open' to find the next task. \
  2. Pick the lowest-numbered issue not blocked by an open issue. \
  3. Implement it. Run tests. \
  4. Commit with 'Closes #N' in the message and push. \
  5. Append to progress.txt what you did. \
  ONLY WORK ON A SINGLE TASK. \
  If no unblocked issues remain, output <promise>COMPLETE</promise>.")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "Complete after $i iterations."
    exit 0
  fi
done
