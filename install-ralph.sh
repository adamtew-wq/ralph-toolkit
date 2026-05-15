#!/usr/bin/env bash
# install-ralph.sh — drop Ralph files into a target git repo.
#
# Usage:
#   /path/to/ralph-toolkit/install-ralph.sh                  # install into $PWD
#   /path/to/ralph-toolkit/install-ralph.sh /path/to/repo    # install into target
#
# Copies ralph-prompt.md, ralph-once.sh, afk-ralph.sh into the target
# repo, and creates an empty progress.txt if one does not already exist.
# Does not overwrite existing Ralph files — back them up first if you
# want to refresh.

set -e

TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-$PWD}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "error: target directory does not exist: $TARGET_DIR" >&2
  exit 1
fi

if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: target is not a git repository: $TARGET_DIR" >&2
  echo "       Ralph needs a git repo so it can commit and push each iteration." >&2
  exit 1
fi

if ! git -C "$TARGET_DIR" remote get-url origin >/dev/null 2>&1; then
  echo "warning: no 'origin' remote configured in $TARGET_DIR" >&2
  echo "         Ralph reads the GitHub repo from origin — set one before running:" >&2
  echo "         git -C \"$TARGET_DIR\" remote add origin <url>" >&2
fi

copy_if_missing() {
  local src="$1"
  local dst="$2"
  if [[ -e "$dst" ]]; then
    echo "skip (exists): $(basename "$dst")"
  else
    cp "$src" "$dst"
    echo "wrote:         $(basename "$dst")"
  fi
}

copy_if_missing "$TOOLKIT_DIR/ralph-prompt.md" "$TARGET_DIR/ralph-prompt.md"
copy_if_missing "$TOOLKIT_DIR/ralph-once.sh"   "$TARGET_DIR/ralph-once.sh"
copy_if_missing "$TOOLKIT_DIR/afk-ralph.sh"    "$TARGET_DIR/afk-ralph.sh"

if [[ ! -e "$TARGET_DIR/progress.txt" ]]; then
  cat > "$TARGET_DIR/progress.txt" <<'EOF'
# Ralph Progress Log

This file is appended to by each Ralph iteration. The agent reads it at the
start of each loop to understand prior state and avoid repeating work.

Format per entry:
  [YYYY-MM-DD HH:MM] Issue #N — <short outcome>

---

(no iterations yet)
EOF
  echo "wrote:         progress.txt"
else
  echo "skip (exists): progress.txt"
fi

chmod +x "$TARGET_DIR/ralph-once.sh" "$TARGET_DIR/afk-ralph.sh"

echo ""
echo "Ralph installed into: $TARGET_DIR"
echo ""
echo "Next steps:"
echo "  1. Confirm GitHub issues are labelled 'ready-for-agent' with 'Blocked by' sections in their bodies."
echo "  2. Run a single HITL iteration to validate behaviour:"
echo "       cd \"$TARGET_DIR\" && ./ralph-once.sh"
echo "  3. Once confident, run an AFK loop:"
echo "       ./afk-ralph.sh 3   # cautious cap"
