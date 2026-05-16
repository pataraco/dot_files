---
name: git
model: sonnet
description: Smart git workflow — assess current repo state and do what's needed (sync main, commit, squash, push, update PR, repo cleanup, or post-merge cleanup). Use this skill whenever the user types /git, /git commit, /git sync, /git squash, /git push, /git pr, /git slack, /git merged, /git cleanup, says "commit my changes", "squash and push", "update my PR", "sync with main", "clean up after merge", "prune stale branches", "git gc", "generate the slack message for review", "request a review", or asks about the current git/PR state.
allowed-tools: [Bash]
---

You are running the /git skill. Assess the current repo state and take the appropriate action(s).

## Commands

| Command | What it does |
|---|---|
| `/git` | Smart assess — runs all checks and acts on whatever needs attention (see Smart Assess below) |
| `/git commit` | Diff staged/unstaged changes, suggest a conventional commit message, confirm, then commit |
| `/git sync` | Check if main/master has new commits — skip if already up to date, otherwise fetch + rebase |
| `/git squash` | Squash all branch commits into one (see Squash Flow below) |
| `/git push` | Commit any uncommitted changes (if any), then push to remote |
| `/git pr` | Check if PR title/description is stale vs. recent commits; suggest updates; report CI + review status |
| `/git slack` | Generate Slack PR review message — prompts to squash first if >1 commit (see PR Review Flow below) |
| `/git merged` | Detect merged PR → switch to main, pull, delete remote + local branch, add journal entry |
| `/git cleanup` | Query merged PRs + prune refs: delete stale feature branches, checkout and fast-forward the repo default branch (`main` / `master` / `develop`, etc.), `git gc` (see Cleanup Flow below) |

## Step 1 — Gather state (run all in parallel)

- `git status`
- `git log --oneline origin/HEAD..HEAD` (commits ahead of main)
- `git fetch origin --dry-run` (check if remote has updates)
- `git branch -vv` (current branch + tracking info)
- `gh pr list --state open --limit 5`
- `gh pr list --state merged --limit 3`

## Step 2 — Smart Assess (`/git` alone)

Work through these checks in order:

### A. Main branch out of date
Run `git fetch origin --dry-run` to check if origin/main has new commits.
- If **no new commits**: skip — report "Already up to date with main."
- If **new commits exist**:
  - If on main/master: pull latest
  - If on a feature branch: rebase onto latest main/master

### B. Uncommitted changes
If there are staged or unstaged changes:
- Show a diff summary of what changed
- Suggest a commit message based on the diff (conventional commits format)
- Ask the user to confirm or provide their own message
- Stage all relevant changes and commit

### C. Multiple commits
If `git log origin/HEAD..HEAD` shows more than 1 commit:
- Ask: "You have X commits on this branch — would you like to squash them into one?"
- If yes: run the Squash Flow below
- If no: continue to next check

### D. Open PR exists
If there's an open PR for the current branch:
- Run `gh pr view <number>` to get current title and description
- Compare against recent commits — does the title/description still accurately reflect all changes?
- If stale: suggest an updated title/description and ask user to confirm before applying
- Report PR status: CI checks (`gh pr checks <number>`), review status, merge readiness

### E. PR has been merged
If a PR for the current branch shows state=MERGED:
- Run the Merged Flow below

### F. Nothing to do
If everything is clean and up to date — report current state:
- Current branch and tracking status
- Commits ahead/behind origin
- Open PR status (if any)

## Squash Flow (`/git squash` or when triggered)
1. `git fetch origin` then `git rebase origin/main` (or origin/master) — ensure main is up to date first
2. `git rebase -i origin/main` — squash all branch commits into one
3. Use conventional commit format: `feat/fix/chore/refactor/docs/style/test`
4. Ask the user to confirm the commit message before proceeding
5. `git push --force-with-lease`

## PR Review Flow (`/git slack`)
1. Check commit count: `git log --oneline origin/HEAD..HEAD`
2. If more than 1 commit, prompt: "You have X commits — squash before requesting review? (recommended)"
3. If yes: run the full Squash Flow above
4. Generate the Slack review message for the PR

## Merged Flow (`/git merged`)
- Confirm with `gh pr view <number> --json state,mergedAt`
- Switch to main/master and pull latest
- Delete remote branch: `git push origin --delete <branch>`
- Delete local branch: `git branch -D <branch>`
- Add a journal entry to `~/notes/Daily_Journal_{YYYY}.txt` in format: `DD-MM-YYYY: <repo> - <description>`, inserted in chronological order

## Cleanup Flow (`/git cleanup`)
Repo housekeeping: align with GitHub merged PRs, drop stale feature branches, sync the default branch, then tidy. Broader than `/git merged` (which handles one merged PR, journal, etc.).

### 0. Preconditions
- Repo should be a Git checkout with `origin`. If `gh` is available, use it for default branch and merged PRs; if not, fall back to git-only steps and say what `gh` would add.
- If there are uncommitted changes, do not delete branches or checkout until the user commits, stashes, or discards — summarize `git status` and pause.

### 1. Resolve the default branch (`<default>`)
Use the first that works:
1. `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` (authoritative for GitHub)
2. `git symbolic-ref --short refs/remotes/origin/HEAD` → strip `origin/` if present
3. Try `main`, then `master`, then `develop` if `refs/remotes/origin/<name>` exists

Never assume the integration branch is named `main`.

### 2. Fetch and prune
Run `git fetch origin --prune` so remote-tracking refs match the server.

### 3. Merged PRs → stale head branches (GitHub)
Use `gh` when available:

1. List recent merged PRs and collect unique head branch names, e.g.  
   `gh pr list --state merged --limit 100 --json headRefName,number,mergedAt`  
   (raise limit if the user wants a deeper sweep.)

2. Build a candidate list: each `headRefName` that is **not** `<default>` and not empty. Skip odd cases (e.g. fork refs) per `gh` output — if `headRefName` looks like `user:branch`, resolve only what applies to this clone.

3. For each candidate, check whether it still exists:
   - **Remote:** `refs/remotes/origin/<branch>` (branch names may contain `/`)
   - **Local:** local branch with that name

4. Present a compact table to the user: PR-linked branch name, still on remote?, still local?. Ask for confirmation before any delete.

5. After confirmation, for each agreed branch:
   - If it exists on **origin**: `git push origin --delete <branch>`
   - If it exists **locally**: `git branch -d <branch>` first; if Git refuses because it is not fully merged locally, explain and offer `git branch -D <branch>` only if the user explicitly accepts force-delete for that branch.

Re-fetch or rely on prior `--prune` so deleted remotes disappear from the list.

### 4. Update `<default>` locally
1. Ask to confirm checkout of `<default>` (required so the local default branch fast-forwards cleanly).
2. `git checkout <default>` then `git pull origin <default>` (prefer fast-forward; if diverged, stop and report — do not merge or rebase without explicit user instruction).

### 5. Other safe merged locals (git-only sweep)
After `<default>` is current and up to date:

1. List locals merged into `origin/<default>`: `git branch --merged origin/<default>`
2. Exclude `<default>` and the current branch from deletion candidates.
3. Show the list; delete only with confirmation (`git branch -d` per branch).

### 6. Garbage collect
Run `git gc`.

**Rules for cleanup:** never delete branches without the user confirming the merged-PR list and/or the `--merged` list; never `git branch -D` unless the user explicitly opts in for a named branch; do not merge/rebase away divergence on `<default>` without explicit instructions.

**Note:** Checking out and pulling `<default>` is allowed here even though general workflow avoids feature work on the default branch — this step only syncs it during cleanup.

## Rules (always apply)
- Never do feature work or commits directly on the repo default branch (`main` / `master` / `develop`, etc.) — exception: `/git cleanup` may checkout and pull that branch only to sync it after the user confirms
- Squash only when explicitly requested, prompted during `/git`, or before a PR review (`/git slack`) — never automatically
- Sanitize before pushing to `pataraco` repos: no internal URLs, Jira keys, tokens, or secrets
- Ask before creating or updating a PR
- Ask before force-pushing to remote
