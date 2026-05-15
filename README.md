# ralph-toolkit

Reusable scripts for running Ralph-style AFK loops with Claude Code against any GitHub repo.

Each iteration:
1. Picks the next unblocked GitHub issue labelled `ready-for-agent`
2. Implements one vertical slice end-to-end
3. Commits with `Closes #N` and pushes
4. Appends to `progress.txt`
5. Signals `<promise>COMPLETE</promise>` when no unblocked issues remain

## Prerequisites

- Claude Code CLI (`claude --version`)
- Docker Desktop 4.50+ with `docker sandbox` subcommand (`docker sandbox --help`)
- `gh` CLI authenticated (`gh auth status`)
- The target repo is a git repo with a GitHub `origin` remote

## Install into a project

```bash
/path/to/ralph-toolkit/install-ralph.sh /path/to/your/project
```

This copies `ralph-prompt.md`, `ralph-once.sh`, `afk-ralph.sh` and (if absent) `progress.txt` into the target. It skips any file that already exists — back up first if you want to refresh.

## Prepare your issues

For Ralph to pick up work, issues need:
- Label `ready-for-agent`
- A `## Blocked by` section in the body listing blocker issue references (or "None - can start immediately")
- Optional label `lower-priority` to defer until non-lower-priority work is done

The `/to-issues` skill in Claude Code produces issues in this exact shape.

## Run

```bash
cd /path/to/your/project

./ralph-once.sh        # one iteration on the host, with edit prompts auto-accepted
./afk-ralph.sh 3       # cautious AFK run in a Docker sandbox (3 iterations max)
./afk-ralph.sh 20      # longer AFK run
```

Start with `ralph-once.sh` to validate the agent's behaviour on your repo before going autonomous. Inspect the commit, the closed issue, and the updated `progress.txt` after each run.

## Cost control

Each iteration consumes Anthropic credits — typically more than a single Claude Code message, since the agent has to read the repo, implement, test, and commit. Start with `./afk-ralph.sh 3` and review commits before widening.

## Files dropped into the target repo

| File | Purpose |
|---|---|
| `ralph-prompt.md` | Iteration prompt. Edit per-project if you want extra constraints. |
| `ralph-once.sh` | One HITL iteration on the host machine. |
| `afk-ralph.sh` | Autonomous loop in `docker sandbox`. |
| `progress.txt` | Append-only log of completed iterations. |
