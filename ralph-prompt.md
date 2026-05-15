# Ralph Iteration Prompt

You are working on this repo. One iteration = one task. Do not start work on more than one issue per iteration.

## Step 1 — Identify the repo

Run `git remote get-url origin` and parse the GitHub `owner/repo` from the URL. Use this as `<REPO>` in subsequent `gh` commands. If there is no origin, stop and report the error.

## Step 2 — Read prior state

Read `@progress.txt` to understand what has already been completed in previous iterations.

## Step 3 — Pick the next issue

Run:

```
gh issue list -R <REPO> --label ready-for-agent --state open --json number,title,body,labels
```

From the open `ready-for-agent` issues:

1. Skip any issue tagged `lower-priority` if non-`lower-priority` issues are still open.
2. Parse each issue body's "Blocked by" section. An issue is **unblocked** if every blocker is closed (use `gh issue view <N> -R <REPO> --json state` to check).
3. Pick the lowest-numbered unblocked issue.

If no unblocked issue exists, append a line to `progress.txt` noting "no unblocked issues — loop terminated", commit the progress.txt update, and exit. Output `<promise>COMPLETE</promise>` so the loop terminates.

## Step 4 — Implement the issue

- Read the full issue body via `gh issue view <N> -R <REPO>`
- Implement the vertical slice end-to-end per the acceptance criteria
- Write tests as specified
- Run the test suite and confirm it passes before committing
- Keep the change focused on this one issue — do not start adjacent work

## Step 5 — Commit

- Stage only the files you changed for this issue (not `progress.txt` — that comes after)
- Create a single commit. Commit message format:

```
<short summary referencing issue #N>

Closes #N

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Step 6 — Push and close

- `git push` to the default branch (or the branch the harness has checked out)
- The `Closes #N` trailer will auto-close the issue on push if pushed to default; otherwise close it manually with `gh issue close <N> -R <REPO> --comment "Implemented in <commit-sha>"`

## Step 7 — Update progress.txt

Append a single line to `progress.txt` in the format:

```
[YYYY-MM-DD HH:MM] Issue #N — <one-line outcome>
```

Commit that update separately with message `chore: update progress log for #N`, then push.

## Step 8 — Signal completion

End your response with exactly:

```
<promise>COMPLETE</promise>
```

## Hard rules

- **ONE TASK PER ITERATION.** Do not chain into the next issue, even if it looks small.
- **Do not modify or close issues that are not the one you are working on.**
- **Do not modify a PRD issue** if one exists (typically labelled `prd` or with a title starting "PRD:").
- **Stop immediately and surface the problem** if: tests fail repeatedly, an issue's acceptance criteria are unreachable from the current code, you would need to make an architectural decision that the issue does not cover.
- **Never `git push --force` or `git reset --hard`.**
- **Never `git add -A` or `git add .`** — stage files explicitly to avoid committing secrets, build artefacts, or unrelated work.
