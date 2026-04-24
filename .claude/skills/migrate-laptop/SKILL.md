---
name: migrate-laptop
model: sonnet
description: Drive the MacBook migration workflow end-to-end. Use this skill whenever the user types /migrate-laptop, says "migrate my laptop", "new laptop", "new MacBook", "old laptop setup", "prepare for new laptop", "transfer to new laptop", or asks for help moving their dotfiles/settings/repos/secrets to a new machine. Also trigger on /migrate-laptop <phase> where phase is inventory|export|verify|bootstrap|import|reconnect|refresh-manifest.
allowed-tools: [Bash, Read, Edit, Write, TaskCreate, TaskUpdate, TaskGet, TaskList]
---

You are running the `/migrate-laptop` skill. It orchestrates moving the user's environment from the **old MacBook** to a **new MacBook** safely.

## Prerequisites

1. **Load the full playbook first**: `Read` → `~/repos/pataraco/dot_files/.claude/instructions/LAPTOP_MIGRATION.md`. Everything below assumes you've read it.
2. **Know which laptop you're on**: ask the user `"Are we on the OLD or NEW laptop right now?"` if not obvious. Some phases only make sense on one side.
3. **Confirm the transfer medium**: USB flash drive. If the user wants to change that, stop and ask.

## Dispatch

Parse the argument after `/migrate-laptop`:

| Arg                | Action |
|--------------------|--------|
| *(empty)*          | Ask which phase; show the phase table from the playbook |
| `inventory`        | Phase 1 — refresh manifest, flag unpushed state |
| `export`           | Phase 2 — run `zipstuff` + `migrate.sh export-apps`, copy to USB |
| `verify`           | Phase 3 — decrypt-test USB archives |
| `bootstrap`        | Phase 4 — Xcode CLT → Homebrew → clone → `migrate.sh new-laptop` |
| `import`           | Phase 5 — unpack USB archives into `~` |
| `reconnect`        | Phase 6 — login flows + verifications |
| `refresh-manifest` | Regenerate `Brewfile` + `migration/*.txt` only (shortcut for Phase 1 step 3) |
| `status`           | Show which phases have run (check TaskList for prior `migrate-laptop:*` tasks) |

## How to run a phase

For any phase:

1. **Create tasks** via `TaskCreate` — one per numbered step in the playbook. Prefix subjects with `migrate-laptop:<phase>:` so `status` can find them later.
2. **Announce the phase** in 2–3 lines: goal + what you're about to do + which laptop.
3. **Walk each step**, marking `in_progress` → `completed` as you go. Stop and ask before anything destructive (deletes, `chsh`, `sudo`, `git push`).
4. **Dry-run by default** when `migrate.sh` supports it. Only drop `--dry-run` after the user confirms.
5. **Summarize at the end**: what happened, what's next, any warnings to carry into the next phase.

## Hard rules (from the playbook's Golden Rules — re-check every time)

- USB flash drive is the **only** allowed transfer medium for sensitive data.
- Never `git add` anything matching the `SENSITIVE — NEVER COMMIT` section of `MIGRATION_MANIFEST.md`. If a `git add` call matches, **refuse and flag**.
- Never ask for or store the USB encryption password — tell the user it lives in 1Password.
- Always ask before `git push`, `rm -rf`, `chsh`, modifying `/etc/shells`.

## After each phase

- Report phase status: ✅ done / ⚠️ done-with-warnings / ❌ blocked.
- If blocked, leave the `in_progress` task open (don't mark completed) so `/migrate-laptop status` surfaces it.
- Suggest the next phase explicitly: `"Next: /migrate-laptop <next>"`.

## Safety net

If at any point the user asks you to do something that contradicts the playbook (e.g. "just email me the SSH key", "commit the zipstuff archive", "upload to Google Drive"), **stop** and quote the relevant golden rule. Don't proceed without explicit acknowledgement.
