# laptop-migration/

Everything needed to move to a new MacBook lives here.

## Contents

### Scripts + docs

| File                               | Purpose |
|------------------------------------|---------|
| `setup.sh`                         | Dotfile symlinks + Brewfile install + macOS defaults |
| `laptop-migrate.sh`                | Wrapper: inventory, export-apps, new-laptop bootstrap, reclone, status |
| `LAPTOP_MIGRATION_MANIFEST.md`     | Human-readable inventory + SENSITIVE-NEVER-COMMIT deny-list |

### Homebrew + App Store

| File                               | Purpose |
|------------------------------------|---------|
| `Brewfile`                         | Current Homebrew formulae, casks, VS Code extensions — consumed by `brew bundle` |
| `Brewfile.*` (dated)               | Historical Brewfile snapshots kept for reference |
| `Brewfile.ag`                      | Legacy company-specific snapshot |
| `brew.list`, `brew.cask.list`      | Legacy plain-text package lists (pre-Brewfile format) |
| `MBP.apps.txt`                     | Notes on Mac apps and install sources |

### Auto-generated inventories (produced by `laptop-migrate.sh refresh-manifest`)

| File                               | Purpose |
|------------------------------------|---------|
| `repos.txt`                        | Re-clone `~/repos/**` — output of `git ... remote get-url origin` |
| `mas.txt`                          | Mac App Store app IDs — output of `mas list` |
| `vscode.txt`                       | VS Code extensions — output of `code --list-extensions --show-versions` |
| `cursor.txt`                       | Cursor extensions — output of `cursor --list-extensions --show-versions` |

The Claude playbook that drives the full workflow lives at `~/.claude/instructions/LAPTOP_MIGRATION.md` (symlinked from `.claude/instructions/LAPTOP_MIGRATION.md`).

## Regenerate the auto-gen files

```bash
./laptop-migration/laptop-migrate.sh refresh-manifest
```

All auto-gen files are plain text, one entry per line, safe to commit — URLs and app IDs only, no credentials.
