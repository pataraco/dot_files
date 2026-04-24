#!/usr/bin/env bash
#
# migrate.sh — MacBook migration wrapper
#
# Subcommands (see: ./migrate.sh help):
#   refresh-manifest   regenerate Brewfile + migration/*.txt
#   export-apps        archive ~/Library app settings to ~/.$COMPANY.apps.zip
#   import-apps ZIP    extract an app-settings archive into ~/
#   new-laptop         fresh-MacBook bootstrap wrapper around setup.sh
#   reclone            re-clone git repos listed in migration/repos.txt
#   status             show what's been regenerated and when
#   help               this message
#
# Companion docs:
#   MIGRATION_MANIFEST.md
#   .claude/instructions/LAPTOP_MIGRATION.md
#
set -euo pipefail

# ---------- paths ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_REPO="$SCRIPT_DIR"
MIGRATION_DIR="$SRC_REPO/migration"
COMPANY="${COMPANY:-}"   # loaded from .bash_profile normally

# ---------- app settings paths (edit to taste) ----------
# Each entry is a path relative to $HOME. Use shell glob patterns where helpful.
APP_PATHS=(
  "Library/Preferences/com.googlecode.iterm2.plist"
  "Library/Application Support/iTerm2"
  "Library/Application Support/Cursor/User/settings.json"
  "Library/Application Support/Cursor/User/keybindings.json"
  "Library/Application Support/Cursor/User/snippets"
  "Library/Application Support/Code/User/settings.json"
  "Library/Application Support/Code/User/keybindings.json"
  "Library/Application Support/Code/User/snippets"
  "Library/Application Support/dev.warp.Warp-Stable"
  "Library/Application Support/com.raycast.macos"
  "Library/Preferences/com.knollsoft.Rectangle.plist"
  ".tmux/plugins"
)
APP_EXCLUDES=(
  "*.DS_Store"
  "*/Cache/*"
  "*/GPUCache/*"
  "*/Code Cache/*"
  "*/logs/*"
  "*/CachedData/*"
  "*/blob_storage/*"
  "*/IndexedDB/*"
  "*.log"
)

# ---------- helpers ----------
log()  { printf '[migrate] %s\n' "$*"; }
warn() { printf '[migrate] WARN: %s\n' "$*" >&2; }
die()  { printf '[migrate] ERROR: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

confirm() {
  # confirm "prompt text"  -> returns 0 if user says y
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ---------- subcommands ----------

cmd_help() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
}

cmd_refresh_manifest() {
  need_cmd brew
  mkdir -p "$MIGRATION_DIR"

  log "refreshing Brewfile..."
  ( cd "$SRC_REPO" && brew bundle dump --force --file=Brewfile )

  log "refreshing migration/repos.txt..."
  local repos_file="$MIGRATION_DIR/repos.txt"
  : > "$repos_file"
  # find git dirs under ~/repos (cap depth to avoid pathological trees)
  while IFS= read -r gitdir; do
    local repodir url
    repodir="$(dirname "$gitdir")"
    url="$(git -C "$repodir" remote get-url origin 2>/dev/null || true)"
    [[ -z "$url" ]] && continue
    # relative path under $HOME for readability
    printf '%s\t%s\n' "${repodir/#$HOME/\~}" "$url" >> "$repos_file"
  done < <(find "$HOME/repos" -maxdepth 4 -type d -name .git 2>/dev/null | sort)
  log "  $(wc -l < "$repos_file" | tr -d ' ') repos tracked"

  log "refreshing migration/mas.txt..."
  if command -v mas >/dev/null 2>&1; then
    mas list 2>/dev/null | sort > "$MIGRATION_DIR/mas.txt" || true
    log "  $(wc -l < "$MIGRATION_DIR/mas.txt" | tr -d ' ') App Store apps"
  else
    warn "  mas not installed — skipping (install with 'brew install mas')"
  fi

  log "refreshing migration/vscode.txt..."
  if command -v code >/dev/null 2>&1; then
    code --list-extensions --show-versions 2>/dev/null | sort > "$MIGRATION_DIR/vscode.txt" || true
    log "  $(wc -l < "$MIGRATION_DIR/vscode.txt" | tr -d ' ') VS Code extensions"
  else
    warn "  code CLI not on PATH — skipping"
  fi

  log "refreshing migration/cursor.txt..."
  if command -v cursor >/dev/null 2>&1; then
    cursor --list-extensions --show-versions 2>/dev/null | sort > "$MIGRATION_DIR/cursor.txt" || true
    log "  $(wc -l < "$MIGRATION_DIR/cursor.txt" | tr -d ' ') Cursor extensions"
  else
    warn "  cursor CLI not on PATH — skipping"
  fi

  log "done. Review with: git -C '$SRC_REPO' diff --stat"
}

cmd_export_apps() {
  need_cmd zip
  [[ -n "$COMPANY" ]] || die "\$COMPANY is not set (needed for output filename)"

  local out="$HOME/.${COMPANY}.apps.zip"
  log "creating $out"
  log "will include:"
  local p
  for p in "${APP_PATHS[@]}"; do printf '  - %s\n' "$p"; done

  if ! confirm "proceed?"; then
    log "aborted"
    return 1
  fi

  local existing=()
  local missing=()
  ( cd "$HOME" && for p in "${APP_PATHS[@]}"; do
      # use shell glob expansion
      # shellcheck disable=SC2086
      if compgen -G "$p" > /dev/null; then
        existing+=("$p")
      else
        missing+=("$p")
      fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
      printf '[migrate] skipping (not found): %s\n' "${missing[@]}"
    fi
    # shellcheck disable=SC2086
    zip --recurse-paths --encrypt "$out" "${existing[@]}" \
      --exclude "${APP_EXCLUDES[@]}"
  )
  log "done: $out"
  log "copy to USB, then verify with:  unzip -t '$out'"
}

cmd_import_apps() {
  local zipfile="${1:-}"
  [[ -n "$zipfile" ]] || die "usage: migrate.sh import-apps <path/to/.apps.zip>"
  [[ -f "$zipfile" ]] || die "not found: $zipfile"
  need_cmd unzip

  log "contents of $zipfile:"
  unzip -l "$zipfile" | head -40
  echo "..."
  if ! confirm "extract into \$HOME ($HOME)?"; then
    log "aborted"
    return 1
  fi
  ( cd "$HOME" && unzip -n "$zipfile" )
  log "done. Some apps (iTerm2, Rectangle) need to be closed+reopened to re-read prefs."
  log "You may also need:  defaults read com.googlecode.iterm2  (to force reload)"
}

cmd_new_laptop() {
  log "=== New laptop bootstrap ==="

  # 1. Xcode Command Line Tools
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode CLT: already installed"
  else
    warn "Xcode CLT not installed. Launching installer..."
    xcode-select --install || true
    die "Wait for the Xcode CLT GUI installer to finish, then re-run."
  fi

  # 2. Homebrew
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew: already installed"
  else
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # 3. Ensure brew is on PATH for this shell
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # 4. Register Homebrew bash in /etc/shells (needed for chsh later)
  local brew_bash
  brew_bash="$(brew --prefix)/bin/bash"
  if [[ -x "$brew_bash" ]] && ! grep -qxF "$brew_bash" /etc/shells; then
    warn "Homebrew bash ($brew_bash) is not in /etc/shells"
    if confirm "add it now (requires sudo)?"; then
      echo "$brew_bash" | sudo tee -a /etc/shells >/dev/null
      log "added"
    else
      warn "skipped — chsh to $brew_bash will fail until added"
    fi
  fi

  # 5. Run setup.sh
  log "running setup.sh..."
  ( cd "$SRC_REPO" && bash setup.sh )

  # 6. Mac App Store apps
  if [[ -f "$MIGRATION_DIR/mas.txt" ]] && command -v mas >/dev/null 2>&1; then
    log "App Store apps found in migration/mas.txt"
    if confirm "install them now? (requires App Store sign-in)"; then
      while read -r app_id _rest; do
        [[ -z "$app_id" || "$app_id" =~ ^# ]] && continue
        mas install "$app_id" || warn "mas install $app_id failed"
      done < "$MIGRATION_DIR/mas.txt"
    fi
  fi

  # 7. VS Code / Cursor extensions
  if command -v code >/dev/null 2>&1 && [[ -f "$MIGRATION_DIR/vscode.txt" ]]; then
    if confirm "install VS Code extensions from migration/vscode.txt?"; then
      cut -d@ -f1 "$MIGRATION_DIR/vscode.txt" | while read -r ext; do
        [[ -z "$ext" ]] && continue
        code --install-extension "$ext" --force || warn "vscode ext $ext failed"
      done
    fi
  fi
  if command -v cursor >/dev/null 2>&1 && [[ -f "$MIGRATION_DIR/cursor.txt" ]]; then
    if confirm "install Cursor extensions from migration/cursor.txt?"; then
      cut -d@ -f1 "$MIGRATION_DIR/cursor.txt" | while read -r ext; do
        [[ -z "$ext" ]] && continue
        cursor --install-extension "$ext" --force || warn "cursor ext $ext failed"
      done
    fi
  fi

  log "=== bootstrap complete ==="
  log "Next steps:"
  log "  1. exec \$SHELL   (pick up symlinked .bash_profile/.bashrc)"
  log "  2. Insert USB and run:  ./migrate.sh import-apps <path-to-.apps.zip>"
  log "  3. Extract home-dir archive (see LAPTOP_MIGRATION.md Phase 5)"
  log "  4. ./migrate.sh reclone   (optional, for ~/repos)"
}

cmd_reclone() {
  local repos_file="$MIGRATION_DIR/repos.txt"
  [[ -f "$repos_file" ]] || die "no $repos_file — run './migrate.sh refresh-manifest' on the old laptop first"

  log "$(wc -l < "$repos_file" | tr -d ' ') repos available in $repos_file"
  log "modes:"
  log "  all        — clone every repo to its original path"
  log "  pataraco   — only repos under ~/repos/pataraco/"
  log "  pick       — interactive (confirm each)"
  log "  list       — print them and exit"
  local mode
  read -r -p "mode [pick]: " mode
  mode="${mode:-pick}"

  case "$mode" in
    list)
      cat "$repos_file"
      return 0
      ;;
    all|pataraco|pick) ;;
    *) die "unknown mode: $mode" ;;
  esac

  while IFS=$'\t' read -r path url; do
    [[ -z "$path" || "$path" =~ ^# ]] && continue
    local abs="${path/#\~/$HOME}"
    if [[ -d "$abs/.git" ]]; then
      continue  # already cloned
    fi

    if [[ "$mode" == "pataraco" && "$path" != *"/pataraco/"* ]]; then
      continue
    fi
    if [[ "$mode" == "pick" ]] && ! confirm "clone $url -> $abs?"; then
      continue
    fi

    mkdir -p "$(dirname "$abs")"
    if git clone "$url" "$abs"; then
      log "  cloned: $path"
    else
      warn "  failed: $url"
    fi
  done < "$repos_file"

  log "done"
}

cmd_status() {
  log "Manifest freshness:"
  local f
  for f in Brewfile migration/repos.txt migration/mas.txt migration/vscode.txt migration/cursor.txt; do
    if [[ -f "$SRC_REPO/$f" ]]; then
      local mtime
      mtime="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$SRC_REPO/$f")"
      printf '  %-26s %s\n' "$f" "$mtime"
    else
      printf '  %-26s (missing)\n' "$f"
    fi
  done
  echo
  log "Home-dir archives in \$HOME:"
  ls -lh "$HOME"/.*.stuff.zip "$HOME"/.*.apps.zip 2>/dev/null || echo "  none"
}

# ---------- dispatch ----------
main() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    help|-h|--help)    cmd_help ;;
    refresh-manifest)  cmd_refresh_manifest "$@" ;;
    export-apps)       cmd_export_apps "$@" ;;
    import-apps)       cmd_import_apps "$@" ;;
    new-laptop)        cmd_new_laptop "$@" ;;
    reclone)           cmd_reclone "$@" ;;
    status)            cmd_status "$@" ;;
    *) die "unknown subcommand: $cmd (try: help)" ;;
  esac
}

main "$@"
