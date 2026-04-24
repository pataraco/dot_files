# Laptop Migration Instructions

> **Version:** 1.0.0
> **Last updated:** 22-04-2026
> **Load when:** the user mentions "new laptop", "migrate laptop", "laptop migration", "new MacBook", "old laptop", or invokes `/migrate-laptop`.
> **Companion files:**
> - `MIGRATION_MANIFEST.md` (repo root) — inventory + deny-list
> - `migrate.sh` (repo root) — the wrapper script
> - `setup.sh` (repo root) — symlinks dotfiles + runs `brew bundle`
> - `zipstuff` function in `.bash_aliases` — produces encrypted home-dir archive

---

## Golden rules — read before doing anything

1. **USB flash drive is the ONLY transfer medium for sensitive data.** Never upload secrets to cloud storage, email, Slack, iMessage, or any network location. Never paste key material into chat.
2. **Never `git add`** any path in the `SENSITIVE — NEVER COMMIT` section of `MIGRATION_MANIFEST.md`. Check that section before every `git add` during this flow. If the user asks you to commit something that matches the deny-list, stop and flag it.
3. **Ask before**: `git push`, deleting files/directories, running `chsh`, modifying `/etc/shells`, sending anything to a shared system, or running any destructive `zip -m` / `tar --remove-files` variant.
4. **Never store the USB encryption password** in any file under `~/repos` or in memory. Tell the user to keep it in 1Password.
5. **Dry-run first.** `migrate.sh` supports `--dry-run` for every phase. Prefer dry-run when the user hasn't already confirmed.

---

## Phases

The full migration has six phases. The user may ask to run them individually via `/migrate-laptop <phase>` or all at once. Track progress with `TaskCreate`/`TaskUpdate`.

```
Phase 1: Inventory        [old laptop]  →  refresh manifest, confirm state
Phase 2: Export           [old laptop]  →  zipstuff + export-apps → USB
Phase 3: Verify USB       [old laptop]  →  confirm archives decrypt
Phase 4: Bootstrap        [new laptop]  →  Xcode CLT, Homebrew, clone repo, setup.sh
Phase 5: Import           [new laptop]  →  unpack USB archives
Phase 6: Reconnect        [new laptop]  →  logins, re-clone repos, verify
```

---

## Phase 1 — Inventory (old laptop)

**Goal:** refresh what's captured so nothing is forgotten on migration day.

Steps:
1. Confirm CWD is `~/repos/pataraco/dot_files`. If not, `cd` there.
2. Check branch state with `git status`. If there are uncommitted dotfile changes (e.g. `.bash_aliases`), flag them — they won't reach the new laptop unless committed + pushed.
3. Run `./migrate.sh refresh-manifest`. This regenerates:
   - `Brewfile` (via `brew bundle dump --force`)
   - `migration/repos.txt`, `migration/mas.txt`, `migration/vscode.txt`, `migration/cursor.txt`
4. Show `git diff` of the changes. Summarize: how many new brew packages, how many new repos, how many new extensions.
5. Confirm with the user, then help them commit + push (via the `/git` skill).

**Also confirm** in this phase:
- Is `~/notes` a git repo that's pushed? Check `git -C ~/notes status && git -C ~/notes log origin/main..HEAD`. If there are unpushed commits in `~/notes`, `~/repos/pataraco/notes`, `~/scripts`, etc., warn the user before export.
- Is `~/.bash_history` something they want to carry over? (zipstuff includes it.) Ask if unsure.
- Are there any **unstashed/uncommitted** branches across `~/repos/**`? Run: `find ~/repos -maxdepth 3 -name ".git" -type d -exec git -C {}/.. status --porcelain \; 2>/dev/null | head -50` and surface anything non-empty.

---

## Phase 2 — Export (old laptop)

**Goal:** produce two encrypted zips on the USB drive.

### 2a — Home-dir archive (zipstuff)

1. Make sure `$COMPANY` is set (`echo $COMPANY`). If blank, ask the user — it's the filename prefix (`.$COMPANY.stuff.zip`).
2. Run `zipstuff` (it's a bash function, sourced from `.bash_aliases`). It will:
   - Show what will be included/excluded
   - Dry-run check for nested zip files
   - Prompt for an encryption password
3. When the password prompt appears, tell the user: **"Use a strong password and save it in 1Password now — you'll need it on the new laptop."**
4. Output lands at `~/.${COMPANY}.stuff.zip`.

### 2b — App settings archive

1. Run `./migrate.sh export-apps` — produces `~/.${COMPANY}.apps.zip`.
2. Uses the same encryption approach as zipstuff (same password by default, or different — ask the user).

### 2c — Copy to USB

1. Ask the user to insert the USB drive.
2. `df -h` to list mounts. Identify the USB (usually `/Volumes/<something>`).
3. Copy both archives: `cp -v ~/.${COMPANY}.stuff.zip ~/.${COMPANY}.apps.zip /Volumes/<usb>/`
4. Verify with `ls -lh /Volumes/<usb>/*.zip`.
5. **Do NOT delete the originals in `~/` yet** — only after Phase 3 verifies the USB copies decrypt.

---

## Phase 3 — Verify USB (old laptop)

**Goal:** catch corruption / bad password before the old laptop is gone.

1. `unzip -l /Volumes/<usb>/.${COMPANY}.stuff.zip` — lists contents without extracting. Should succeed without asking for a password (ZIP list is unencrypted metadata).
2. Test decrypt: `unzip -P "$PASSWORD" -t /Volumes/<usb>/.${COMPANY}.stuff.zip > /dev/null` — this verifies every file can be decrypted. Use `-P` with care (password ends up in shell history); prefer having the user run `unzip -t` and type the password interactively.
3. Repeat for `.${COMPANY}.apps.zip`.
4. If both pass: tell the user "Phase 3 green — safe to proceed." If either fails: re-export in Phase 2.
5. Optionally, copy the archives a second time to a different USB for redundancy.

---

## Phase 4 — Bootstrap (new laptop)

**Goal:** fresh macOS → repo cloned + `setup.sh` complete.

Assume literally nothing is installed. Sequence:

1. **Xcode CLT**: `xcode-select -p` — if it errors, run `xcode-select --install` and wait for the GUI installer. Don't continue until it's done.
2. **Homebrew**: `command -v brew` — if missing, run the install one-liner from brew.sh. On Apple Silicon, remind the user to add `eval "$(/opt/homebrew/bin/brew shellenv)"` to their shell profile (setup.sh's symlinked `.bash_profile` handles this if it's there — check).
3. **SSH key**: if they want to clone via SSH, they need a key. Options:
   - Use an existing key from the USB archive (wait for Phase 5) — but that means cloning with HTTPS first.
   - Generate a fresh key and add it to GitHub now: `ssh-keygen -t ed25519 -C "patrick.raco@autodesk.com"` → add to GitHub via `gh auth login`.
   - Ask the user which they prefer.
4. **Clone the repo**:
   ```bash
   mkdir -p ~/repos/pataraco
   git clone https://github.com/pataraco/dot_files.git ~/repos/pataraco/dot_files
   cd ~/repos/pataraco/dot_files
   ```
5. **Run setup.sh**:
   ```bash
   ./migrate.sh new-laptop
   ```
   This wraps `setup.sh` with extra safety:
   - Precheck Xcode CLT + Homebrew
   - Register Homebrew bash in `/etc/shells` before `chsh` (if user consents)
   - Run `setup.sh`
   - Run `mas install < migration/mas.txt` (if user is signed into App Store)
   - Offer to re-clone repos from `migration/repos.txt`
6. After setup.sh completes, **open a new shell** (or `exec bash`) so the symlinked `.bash_profile`/`.bashrc` load.

---

## Phase 5 — Import (new laptop)

**Goal:** restore home-dir and app-settings archives.

1. Insert USB, identify with `df -h`.
2. Copy archives off USB first: `cp /Volumes/<usb>/.${COMPANY}.stuff.zip /Volumes/<usb>/.${COMPANY}.apps.zip ~/`
3. **Inspect before extracting** — zipstuff-created archives contain dotfiles and dot-directories that setup.sh has already symlinked. Extracting over them will replace symlinks with real files.
   ```bash
   unzip -l ~/.${COMPANY}.stuff.zip | head -40
   ```
4. Decide with the user which paths are safe to restore vs. skip. Defaults to restore:
   - ✅ `.ssh/`, `.aws/`, `.gnupg/`, `.docker/`, `.kube/`, `.chef/`, `.netrc`, `.git-credentials`, `.adsk-accounts.json`
   - ✅ `notes/`, `projects/`, `automation/`, `scripts/`, `Documents/`
   - ✅ `.bash_history`
   - ⚠️ SKIP dotfiles managed by `setup.sh` (`.bashrc`, `.bash_profile`, `.bash_aliases*`, `.gitconfig`, `.tmux.conf`, `.vimrc`, `.inputrc`, `.zshrc`) — these are already symlinked to the repo.
   - ⚠️ SKIP `.config/` if it contains per-host state (review contents).
5. Extract selectively:
   ```bash
   cd ~
   unzip ~/.${COMPANY}.stuff.zip ".ssh/*" ".aws/*" ".gnupg/*" ".netrc" ".adsk-accounts.json" "notes/*" "projects/*" "scripts/*"
   ```
   Use `-n` (never overwrite) for first pass, then `-o` (overwrite) for intentional ones.
6. Extract app settings:
   ```bash
   ./migrate.sh import-apps ~/.${COMPANY}.apps.zip
   ```
7. Fix permissions on sensitive dirs:
   ```bash
   chmod 700 ~/.ssh ~/.gnupg ~/.aws
   chmod 600 ~/.ssh/id_* ~/.ssh/config ~/.netrc ~/.aws/credentials 2>/dev/null
   ```
8. After verification, **securely erase** the archives from `~/` and from the USB. For the USB, reformat it once both laptops are confirmed working.

---

## Phase 6 — Reconnect (new laptop)

**Goal:** logins and verifications.

Walk through interactively (don't run all at once):

1. **Shell sanity**: `echo $SHELL`, `which bash`, `bash --version` (should be Homebrew's ≥5, not Apple's 3.2).
2. **Git identity**: `git config --global user.email` should match `patrick.raco@autodesk.com`.
3. **SSH**: `ssh -T git@github.com` (should say "successfully authenticated").
4. **AWS**: `aws sts get-caller-identity --profile <default-profile>` — may need `aws sso login` first.
5. **GitHub CLI**: `gh auth status` — re-auth if needed (`gh auth login`).
6. **Vault**: `vault status` (address from `~/.adsk-accounts.json`).
7. **Jira**: `jirapi view <any-ticket>` — prompts for token if missing.
8. **Re-clone repos**: `./migrate.sh reclone` reads `migration/repos.txt` and offers to re-clone each. Ask the user before recloning all 180+; default to "on demand".
9. **App settings spot-check**:
    - iTerm2: launch → verify profile/colors
    - Cursor: launch → verify settings.json applied
    - VS Code: `code --list-extensions | wc -l` matches `migration/vscode.txt` line count
10. **macOS system prefs to configure manually** (not automated):
    - Keyboard → Key Repeat + Delay (fast / short)
    - Trackpad → Tap to click, 3-finger drag (Accessibility)
    - Finder → Show hidden files (`Cmd+Shift+.`)
    - Dock → autohide, small size
    - Desktop & Screensaver → Hot Corners
    - Mission Control → "Displays have separate Spaces"
11. **Journal entry**: add a line to `~/notes/Daily_Journal_{YYYY}.txt` (DD-MM-YYYY format) noting migration completion.

---

## Interactive etiquette

- **Always** summarize what's about to happen before each phase, and wait for a ✅ from the user.
- **Never** run `zipstuff` automatically without confirming `$COMPANY`.
- **Never** attempt to read the USB password from the user's password manager — just tell them to grab it from 1Password.
- **Use tmux panes** (per global `CLAUDE.md`) when running long operations (the zipstuff step can take minutes on `Documents/`).
- If the user needs to run an interactive command you can't drive (login flows, `sudo` prompts), suggest they type `! <command>` so the output lands in your context.

---

## If something goes wrong

- **Wrong USB password**: archives are unrecoverable without it. No retry limit but no recovery either. This is why Phase 3 exists.
- **`brew bundle` fails on a cask**: check if the cask was renamed (e.g. `adoptopenjdk8` → `temurin`). Update Brewfile, re-run `./migrate.sh new-laptop`.
- **`chsh` fails with "non-standard shell"**: `/opt/homebrew/bin/bash` needs to be added to `/etc/shells` first — `migrate.sh new-laptop` handles this if you approve the sudo prompt.
- **Neovim config clobbered by a repeat `setup.sh` run**: the new setup.sh (post-audit) skips the LazyVim clone if `~/.config/nvim` already exists. If you hit the old behavior, your previous config is at `~/.config/nvim.orig`.
- **Symlinks not created**: `setup.sh` assumes `$SRC_REPO=$HOME/repos/pataraco/dot_files`. If you cloned elsewhere, edit the script or symlink the location.

---

## Version history

- **1.0.0** (22-04-2026) — initial version
