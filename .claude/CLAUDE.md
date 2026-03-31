# Terminology Note

When the user refers to "global instructions" they mean this file (~/.claude/CLAUDE.md).
When they refer to "project instructions" they mean a project-specific .claude/CLAUDE.md file.

---

# Git Workflow Instructions

Only load these instructions if the current working directory is a git repository.
If so, use the Read tool to load and follow: ~/.claude/instructions/GIT.md

---

# Git Non-Negotiables

These rules apply every time git operations are performed — even in long sessions where full instructions may have been compressed:

- **Never commit to main/master** — always use a feature branch
- **Squash to a single commit before every PR push** — `git rebase -i origin/main` → squash → `git push --force-with-lease`
- **Sanitize before pushing to `pataraco` repos** — block internal URLs, Jira keys, tokens, secrets
- **After PR merge** — delete remote + local branch, add journal entry to `~/notes/Daily_Journal.txt`
- **Ask before**: creating/updating PRs, force-pushing to remote

---

# Jira Workflow Instructions

At the start of each session, ask the user: "Are you working on a Jira ticket for this session?"
- If yes (even a vague answer): find the ticket using `jirapi` or context clues, then use the Read tool to load and follow ~/.claude/instructions/JIRA.md
- If no: skip loading Jira instructions

---

# Confluence Workflow Instructions

Only load these instructions when the user explicitly mentions updating or creating wiki/Confluence pages.
If so, use the Read tool to load and follow: ~/.claude/instructions/CONFLUENCE.md

---

# Command Execution Policy

**Never ask for confirmation before running non-destructive (read-only) commands.** These include but are not limited to:

- AWS read-only calls: `aws sts get-caller-identity`, `aws s3 ls`, `aws cloudfront list-*`, `aws dynamodb get-item`, etc.
- Health/connectivity checks: `curl` to API endpoints, VPN checks
- Tool/version checks: `terraform version`, `tfenv`, `command -v`, `which`
- `terraform plan` (never modifies state)
- `terraform state list` / `terraform state show`
- `git status`, `git log`, `git diff`, `git fetch`, `git ls-remote`
- `jirapi view`, `jirapi list` (read-only Jira operations)
- `gh pr view`, `gh pr list`, `gh pr checks` (read-only GitHub operations)
- Any `ls`, `cat`, `echo`, `grep`, `jq` pipeline

Only ask for confirmation before **destructive or irreversible** actions (deleting resources, force-pushing, writing to external systems, etc.).

---

# Account & Credential Reference

`~/.adsk-accounts.json` contains account metadata — consult it when you need:
- AWS account IDs
- AWS credential/profile names
- HashiCorp Vault addresses

---

# Instruction File Map

Quick reference for all instruction files — no need to search:
- Git workflow: `~/.claude/instructions/GIT.md`
- Jira workflow: `~/.claude/instructions/JIRA.md`
- Confluence workflow: `~/.claude/instructions/CONFLUENCE.md`
- Git repo sync: `~/.claude/instructions/GIT_REPOS_SYNC.md`

Skills (slash commands):
- `/git` — smart git workflow (sync, commit/squash, PR update, post-merge cleanup)
- `/sup` — session status update
- `/standup` — standup summary from daily journal
- `/ciao` — end of session wrap-up

---

# Instruction File Maintenance

Whenever any instruction file (`~/.claude/instructions/*.md` or `~/.claude/CLAUDE.md`) is updated:
- Bump the version number: patch (x.x.**1**) for minor edits, minor (x.**1**.0) for new behavior
- Update the `Last updated` date using **DD-MM-YYYY** format

---

# Date Format

Always use `DD-MM-YYYY` format for dates in:
- Journal entries
- Version history in instruction files
- Any other date references unless the user specifies otherwise

---

# Session Start Checklist

At the start of each session:
1. Check if the current working directory is a git repo → if so, load `~/.claude/instructions/GIT.md`
2. Display todos — run these checks and always show results:
   - **If in a git repo**: check for `.claude/TODO.txt` at the repo root (`git rev-parse --show-toplevel`). If it exists and has active items (⬜️ 🚧 ⏳ 🚫), display them under **"Local Todos"**
   - **Always**: check `~/notes/TODO.txt` for active items. If any exist, display them under **"Global Todos"**
   - Active items use emojis: ⬜️ pending, 🚧 in progress, ⏳ waiting, 🚫 blocked
   - If no todos anywhere, say "No open todos."
3. Ask: "Are you working on a Jira ticket for this session?"

---

# Tmux Orchestration

When running parallel or long-running tasks, use tmux panes so the user can see everything live.

## Rules
- Always work within the **current tmux session and current window** — never create a new session
- **Always capture the current window reference FIRST** before any splits:
  ```bash
  CURRENT_PANE=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')
  CURRENT_WINDOW=$(tmux display-message -p '#{session_name}:#{window_index}')
  ```
- Split panes using the captured `$CURRENT_PANE` as the target — never use just the session name, as that resolves to whichever window happens to be active:
  - Vertical split (side-by-side): `tmux split-window -h -t "$CURRENT_PANE"`
  - Horizontal split (top/bottom): `tmux split-window -v -t "$CURRENT_PANE"`
- Send commands to a new pane using `tmux send-keys -t <pane> "<command>" Enter`
- After creating a pane, always set its title: `tmux select-pane -t <pane> -T "<short task description>"`
  - Format: descriptive and concise, e.g. `"agent: auth analysis"`, `"build: api service"`, `"test: unit suite"`
- Use tmux panes for: shell commands, builds, tests, scripts, and anything with meaningful visible output

## When to split panes
- When running 2+ independent tasks in parallel (shell or agent)
- When a task will produce output the user should watch live
- When explicitly asked to parallelize work

## Agent tasks in panes (claude -p)
For tasks that require AI reasoning (analyzing code, making decisions, writing code), run `claude` in a tmux pane instead of using the internal Task tool:

```
claude -p "<prompt>" > /tmp/claude-task-<name>.txt 2>&1
```

- Write output to `/tmp/claude-task-<name>.txt` so results can be read back for coordination
- Use a descriptive `<name>` (e.g., `claude-task-auth-analysis.txt`)
- Multiple agent tasks can run in parallel across multiple panes
- After all panes complete, read the output files to synthesize and summarize results
- Only fall back to the internal `Task` tool when spawning a tmux pane is not practical

## After parallel work completes
- Read output files from agent panes and synthesize results
- Report a summary in the main pane: what ran, what succeeded/failed, key outputs
- Leave panes open so the user can inspect them; do not close them automatically

