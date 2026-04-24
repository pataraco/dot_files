# Laptop Migration Manifest

> **Version:** 1.0.0
> **Last updated:** 22-04-2026
> **Purpose:** Single source of truth for what gets captured, transferred, and restored when moving to a new MacBook. Edited by hand; machine-readable sections are auto-refreshed by `migrate.sh refresh-manifest`.

This file is **safe to commit**. It contains inventory metadata only — no secrets, no key material, no credentials. The `SENSITIVE — NEVER COMMIT` section below is a deny-list used by `migrate.sh` and by Claude (via `.claude/instructions/LAPTOP_MIGRATION.md`) to prevent accidental commits.

---

## Transfer methods at a glance

| Category                          | Method                                   | Where it goes |
|-----------------------------------|------------------------------------------|---------------|
| Dotfiles + Brewfile + setup.sh    | `git clone` this repo                    | `~/repos/pataraco/dot_files` |
| Home-dir archive (bash history, ansible, chef, docker, kube, tmux, notes, projects, scripts, Documents, etc.) | `zipstuff` → encrypted `.zip` on **USB flash drive** | USB → `~/` |
| App settings archive (iTerm2, Cursor, VS Code, Warp, Raycast, etc. under `~/Library/...`) | `migrate.sh export-apps` → encrypted `.zip` on **USB flash drive** | USB → `~/Library/...` |
| SSH / GPG / AWS creds / .netrc    | Included in the home-dir archive (zipstuff). Encrypted. **USB only.** | USB → `~/` |
| Repo re-clones                    | `migrate.sh reclone` reads `migration/repos.txt` from this repo | `~/repos/...` |
| Mac App Store apps                | `mas install` reads `migration/mas.txt`  | `/Applications` |
| Browser profiles / logged-in sessions | Manual (sync via browser account)     | — |
| Secrets in password managers      | Manual (1Password / LastPass login)      | — |

---

## Phase 0 — Before you migrate

Run on the **old laptop** to refresh auto-generated inventories:

```bash
cd ~/repos/pataraco/dot_files
./migrate.sh refresh-manifest
```

That regenerates:
- `Brewfile`               — via `brew bundle dump --force`
- `migration/repos.txt`    — list of git remotes in `~/repos/**`
- `migration/mas.txt`      — Mac App Store installed app IDs
- `migration/vscode.txt`   — VS Code extensions (also in Brewfile today, but here as backup)
- `migration/cursor.txt`   — Cursor extensions

Review the diff, commit, push.

---

## Home-dir paths captured by `zipstuff`

Source of truth is the `_FILES` array inside the `zipstuff` function in `.bash_aliases` (~line 1548). Keep this list in sync:

```
.*rc               # .bashrc, .zshrc, .vimrc, .inputrc, .serverlessrc, .s3cfg, etc.
.ansible
.aws
.aws-sam
.bash_history
.chef
.config
.docker
.git-credentials
.groovy
.kube
.rancher
.serverlessrc
.ssh
.tmux
Documents
automation
notes
projects
scripts
```

Excluded:
```
*.DS_Store, *.git*, *.hg*, *.terraform*, *.zip, scripts/*.zip
```

**Output:** `$HOME/.${COMPANY}.stuff.zip` — AES (legacy ZIP) encrypted, prompts for password on create.

---

## App settings archived by `migrate.sh export-apps`

Not in dotfiles, not in zipstuff — these live under `~/Library/`:

| App          | Paths |
|--------------|-------|
| iTerm2       | `~/Library/Preferences/com.googlecode.iterm2.plist`, `~/Library/Application Support/iTerm2/` |
| Cursor       | `~/Library/Application Support/Cursor/User/settings.json`, `keybindings.json`, `snippets/`, `globalStorage/state.vscdb` (optional) |
| VS Code      | `~/Library/Application Support/Code/User/settings.json`, `keybindings.json`, `snippets/` |
| Warp         | `~/Library/Application Support/dev.warp.Warp-Stable/` |
| Raycast      | `~/Library/Application Support/com.raycast.macos/` (if installed) |
| Rectangle    | `~/Library/Preferences/com.knollsoft.Rectangle.plist` (if installed) |
| Slack        | `~/Library/Application Support/Slack/storage/` (workspaces; sign-in happens fresh) |
| Docker       | `~/Library/Group Containers/group.com.docker/` (usually regenerated — optional) |
| tmux plugins | `~/.tmux/plugins/` (if used) |
| Neovim (Lazy)| `~/.local/share/nvim/lazy/` (lockfile is in repo; plugins auto-install) |

Edit the APP_PATHS array in `migrate.sh` to add/remove apps.

**Output:** `$HOME/.${COMPANY}.apps.zip` — AES encrypted.

---

## SENSITIVE — NEVER COMMIT

These paths are **blocked** by `.gitignore` in this repo and must never be staged, even accidentally. If you see Claude or a script trying to `git add` any of these, stop and investigate.

```
.ssh/id_*
.ssh/*.pem
.ssh/*.key
.ssh/authorized_keys
.ssh/config            # may contain internal hostnames
.aws/credentials
.aws/sso/cache
.aws/cli/cache
.gnupg/
.netrc
.pgpass
.adsk-accounts.json
.git-credentials
.1password/
.config/gh/hosts.yml
.kube/config
.vault-token
*.stuff.zip            # zipstuff output
*.apps.zip             # migrate.sh export-apps output
migration-exports/
.env
.env.*
*.pem
*.p12
*.pfx
*.jks
*.keychain-db
```

Never store the USB encryption password anywhere inside this repo (or in any file under `~/repos`). Use 1Password.

---

## Things that do NOT migrate automatically

You'll redo these by hand on the new laptop:

- **Apple ID / iCloud sign-in** (Settings → Apple ID)
- **Browser sign-ins** (Chrome, Safari, Firefox — sync via account)
- **VPN clients** (Cisco AnyConnect / GlobalProtect / whatever Autodesk uses — fresh install + auth)
- **1Password / LastPass desktop app sign-in** (then everything else unlocks)
- **Slack workspace sign-ins** (reuse 1Password)
- **GitHub CLI auth** (`gh auth login`) — don't copy `.config/gh/hosts.yml`, re-auth is safer
- **AWS SSO sessions** (`aws sso login`) — don't copy `.aws/sso/cache`
- **Saml2aws sessions** (re-auth)
- **Xcode / CLT** (`xcode-select --install`) — `migrate.sh new-laptop` prompts this first
- **Printer setup**, **Wi-Fi passwords** (iCloud Keychain handles most if signed in)

---

## Machine-readable sections

These are regenerated by `migrate.sh refresh-manifest`. Hand-editing is fine; next refresh will overwrite. The files live under `migration/` (see `.gitignore` — these are whitelisted).

- `migration/repos.txt` — `<path>\t<remote-url>` for every `.git` dir under `~/repos`
- `migration/mas.txt`   — `<app-id>\t<app-name>` from `mas list`
- `migration/vscode.txt`— `code --list-extensions` output
- `migration/cursor.txt`— `cursor --list-extensions` output

---

## Version history

- **1.0.0** (22-04-2026) — initial version
