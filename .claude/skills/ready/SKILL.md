---
name: ready
model: haiku
description: Run the session start checklist — load global instructions, display todos, and ask about Jira. Use this skill whenever the user types /ready, says "ready", "let's go", "get started", "initialize", or signals they want to kick off a new session.
allowed-tools: [Read, Bash]
---

Run the full session start checklist:

## 1. Load global instructions

Read and follow `~/.claude/CLAUDE.md`.

If the current directory is a git repo (`git rev-parse --show-toplevel 2>/dev/null`), also read and follow `~/.claude/instructions/GIT.md`.

## 2. Display todos

```bash
# Check for local todos (if in a git repo)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -n "$REPO_ROOT" ] && grep -E '^[⬜️🚧⏳🚫]' "$REPO_ROOT/.claude/TODO.txt" 2>/dev/null

# Always check global todos
grep -E '^[⬜️🚧⏳🚫]' ~/notes/TODO.txt 2>/dev/null
```

Display results:
- If in a git repo and local `.claude/TODO.txt` has active items → show under **Local Todos (`<repo-name>`)**
- If `~/notes/TODO.txt` has active items → show under **Global Todos**
- If nothing active → "No open todos."

## 3. Ask about Jira

Ask: "Are you working on a Jira ticket for this session?"
- If yes: find the ticket with `jirapi` or context clues, then read and follow `~/.claude/instructions/JIRA.md`
- If no: skip
