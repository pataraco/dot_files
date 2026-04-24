---
name: todo
model: haiku
description: Manage personal todo action items. Supports global todos in ~/notes/TODO.txt and local/project todos in .claude/TODO.txt at the git repo root. Use this skill whenever the user types /todo, says "add to my todo", "add this to my todos", "add local todo", "add project todo", "mark X as done", "what's on my todo list", "show my todos", "remove from my todo", "complete this task", or asks about their personal action items. Trigger on any mention of todo, todos, action items, task list management, local todo, or project todo.
allowed-tools: [Bash]
---

Manage personal todo lists — global (`~/notes/TODO.txt`) and local (`.claude/TODO.txt` at the git repo root).

## File Format

Each line is either:
- `⬜️ <action item>` — pending
- `🚧 <action item>` — in progress
- `⏳ <action item>` — waiting
- `🚫 <action item>` — blocked / can't do
- `❌ <action item>` — won't do / decided not to / nevermind
- `✅ <action item>` — done / completed
- Lines starting with `#` are comments — preserve them

**Active** items = ⬜️ 🚧 ⏳ 🚫
**Inactive** items = ❌ ✅

## Scopes

- **Global** (default): `~/notes/TODO.txt`
- **Local**: `.claude/TODO.txt` at the git repo root
  - Find the repo root with: `git rev-parse --show-toplevel`
  - If not in a git repo, use `.claude/TODO.txt` in CWD
  - If `.claude/` doesn't exist, create it before writing

Use **local** scope when the user includes "local" or "project" in their command (e.g. "add local todo", "local todo: X", "add project todo").

## Commands

Determine intent from the user's prompt:

| Intent | Triggers |
|---|---|
| **list active** | `/todo`, `/todo list`, "what's on my todo", "show my todos" |
| **list all** | `/todo all`, "show all todos including done" |
| **add** | `/todo add <item>`, "add to my todo: <item>", "add this to my todos" |
| **add local** | `/todo add local <item>`, "add local todo: <item>", "add project todo: <item>" |
| **status** | `/todo <status> <item or number>`, "mark X as in progress", "X is blocked", "X is done", "won't do X" |
| **remove** | `/todo remove <item or number>`, "remove X from my todo" |

Scope keywords ("local", "project") can appear anywhere in the command.

## Steps

Use **only Bash** for all operations — do not use Read or Edit tools. Single Bash calls are faster.

1. Determine scope (global or local) from the user's phrasing
2. Set `FILE=~/notes/TODO.txt` (global) or `FILE=$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/TODO.txt` (local)
3. Run the appropriate shell command below
4. Display the result clearly

## Operations

### List active
```bash
grep -n $'^[⬜️🚧⏳🚫]' "$FILE"
```
Number items for reference. If both global and local files exist, show both with `## Global` / `## Local (repo-name)` headers. "No active todos." if empty.

### List all
```bash
grep -v '^#' "$FILE"
```
Group output: active lines first, then inactive (❌ ✅).

### Add (global)
```bash
echo "⬜️ <item>" >> ~/notes/TODO.txt
```
Confirm: "Added: `<item>`"

### Add (local)
```bash
mkdir -p "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude"
echo "⬜️ <item>" >> "$FILE"
```
Confirm: "Added (local): `<item>`"

### Status change
Match by number or fuzzy text. Use `sed -i` to swap the emoji in place:
```bash
sed -i '' 's/^<old_emoji> \(.*matched text.*\)/<new_emoji> \1/' "$FILE"
```
Emoji map:
| User says | Emoji |
|---|---|
| pending | ⬜️ |
| in progress, working on, starting | 🚧 |
| waiting, on hold | ⏳ |
| blocked, can't do | 🚫 |
| won't do, skip, nevermind, cancel | ❌ |
| done, complete, finished | ✅ |

Confirm: "Status updated: `<emoji> <item>`"

### Remove
Match by number or fuzzy text. Use `sed -i` to delete the line:
```bash
sed -i '' '/matched text/d' "$FILE"
```
Confirm: "Removed: `<item>`"

## Notes

- Prefer a single Bash call per operation — no chained Read+Edit
- When matching by text, fuzzy/partial match is fine
- When ambiguous (multiple matches), list candidates and ask to clarify
- For multiple adds (e.g. "add: foo, bar, baz"), use one `echo` per item or a loop
- When both scopes shown, number items per-section (both start at 1)
