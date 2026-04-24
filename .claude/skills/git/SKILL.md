---
name: git
model: sonnet
description: Smart git workflow — assess current repo state and do what's needed (sync main, commit, squash, push, update PR, or post-merge cleanup). Use this skill whenever the user types /git, /git commit, /git sync, /git squash, /git push, /git pr, /git slack, /git merged, says "commit my changes", "squash and push", "update my PR", "sync with main", "clean up after merge", "generate the slack message for review", "request a review", or asks about the current git/PR state.
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

## Rules (always apply)
- Never work directly on main/master
- Squash only when explicitly requested, prompted during `/git`, or before a PR review (`/git slack`) — never automatically
- Sanitize before pushing to `pataraco` repos: no internal URLs, Jira keys, tokens, or secrets
- Ask before creating or updating a PR
- Ask before force-pushing to remote
