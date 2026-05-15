#!/usr/bin/env bash
# install-ralph.sh — drop Ralph files into a target git repo.
#
# Usage:
#   /path/to/ralph-toolkit/install-ralph.sh                  # install into $PWD
#   /path/to/ralph-toolkit/install-ralph.sh /path/to/repo    # install into target
#
# Copies ralph-once.sh, afk-ralph.sh into the target repo, and creates
# an empty progress.txt if one does not already exist.
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

# Ensure the target repo's .claude/settings.local.json grants Bash(*) so
# Ralph runs do not stall on permission prompts. ralph-once.sh passes
# --dangerously-skip-permissions when launching a fresh Claude, but a
# user who triggers the workflow inline from an existing Claude session
# inherits that session's project permissions instead — so we widen the
# project settings here at install time. The wildcard is scoped to this
# project only; user/global settings are not touched.
ensure_bash_allowed() {
  local settings_dir="$TARGET_DIR/.claude"
  local settings_file="$settings_dir/settings.local.json"
  mkdir -p "$settings_dir"

  if [[ ! -e "$settings_file" ]]; then
    cat > "$settings_file" <<'EOF'
{
  "permissions": {
    "allow": [
      "Bash(*)"
    ]
  }
}
EOF
    echo "wrote:         .claude/settings.local.json (Bash(*) for AFK Ralph runs)"
    return
  fi

  local py=""
  if command -v python >/dev/null 2>&1; then
    py="python"
  elif command -v python3 >/dev/null 2>&1; then
    py="python3"
  fi

  if [[ -z "$py" ]]; then
    echo "warning: python not found — add \"Bash(*)\" to $settings_file manually for AFK runs" >&2
    return
  fi

  local status
  status=$("$py" - "$settings_file" 2>&1 <<'PY'
import json, sys, pathlib
path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except Exception as e:
    print(f"ERROR:could not parse JSON ({e})")
    sys.exit(0)
if not isinstance(data, dict):
    print("ERROR:settings.local.json is not a JSON object")
    sys.exit(0)
perms = data.setdefault("permissions", {})
if not isinstance(perms, dict):
    print("ERROR:permissions is not an object")
    sys.exit(0)
allow = perms.setdefault("allow", [])
if not isinstance(allow, list):
    print("ERROR:permissions.allow is not an array")
    sys.exit(0)
if "Bash(*)" in allow:
    print("ALREADY")
else:
    allow.append("Bash(*)")
    path.write_text(json.dumps(data, indent=2) + "\n")
    print("ADDED")
PY
)

  case "$status" in
    ALREADY) echo "skip (exists): Bash(*) already in .claude/settings.local.json" ;;
    ADDED)   echo "wrote:         .claude/settings.local.json (added Bash(*) for AFK Ralph runs)" ;;
    ERROR:*) echo "warning: ${status#ERROR:} — add \"Bash(*)\" to $settings_file manually" >&2 ;;
    *)       echo "warning: unexpected response updating $settings_file: $status — add \"Bash(*)\" manually" >&2 ;;
  esac
}

copy_if_missing "$TOOLKIT_DIR/ralph-once.sh" "$TARGET_DIR/ralph-once.sh"
copy_if_missing "$TOOLKIT_DIR/afk-ralph.sh" "$TARGET_DIR/afk-ralph.sh"
ensure_bash_allowed

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
