#!/bin/bash
#
# Setup/Configure a MacBook
#  - Install Homebrew and Packages
#  - Links up the dot_files (bash and others) found herein
#    (zsh not supported yet)
#
# NOTE: Make sure value for "SRC_REPO" is correct before running this script
#       (the location where you've cloned/forked this repo)
SRC_REPO="$HOME/repos/pataraco/dot_files"
#
#   1. Installs Homebrew
#   2. Installs the Homebrew packages in the Brewfile
#   3. Moves existing dot files in $HOME to $HOME/.orig
#   4. Set up symlinks from $HOME to the files/dirs in the $SRC_REPO
#      (excluding this script, the .git directory and the README file, etc.)
#
# some other manual steps
#
# - set COMPANY environment variable in .bash_profile
# - create .bash_aliases_${COMPANY} with complany specific functions/aliases

# set up global variables
ORIG_DIR="$HOME/.orig"
files_saved=false
# DESIRED_SHELL is computed later (after Homebrew is installed) since it points
# to Homebrew's bash, which lives at $(brew --prefix)/bin/bash.

# make sure running on MacBook
if [ "$(uname)" != "Darwin" ]; then
  echo "Kindof only supported on MacBooks"
  exit
fi

# make sure the repo actually exists before we cd into it
if [ ! -d "$SRC_REPO" ]; then
  echo "ERROR: SRC_REPO '$SRC_REPO' does not exist. Edit this script or clone the repo first."
  exit 1
fi

# ----------------------------------------------------------------------
# Tee all output to ~/.laptop-setup.log (appends across runs; terminal unchanged)
# ----------------------------------------------------------------------
SETUP_LOG="$HOME/.laptop-setup.log"
exec > >(tee -a "$SETUP_LOG") 2>&1
echo ""
echo "=== setup.sh run: $(date '+%Y-%m-%d %H:%M:%S') ==="

# ----------------------------------------------------------------------
# macOS defaults
# ----------------------------------------------------------------------
echo "Applying macOS defaults..."

# -- Finder --
defaults write com.apple.finder AppleShowAllFiles -bool true          # show hidden files
defaults write com.apple.finder ShowPathbar -bool true                # path bar at bottom
defaults write com.apple.finder ShowStatusBar -bool true              # status bar at bottom
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true    # POSIX path in window title
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false  # no extension-change warning
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder by default

# -- Dock --
# (autohide itself left as-is — user has it off; these just make it snappy if toggled on)
defaults write com.apple.dock autohide-delay -float 0                 # no delay before Dock autohides
defaults write com.apple.dock autohide-time-modifier -float 0.5       # faster show/hide animation
defaults write com.apple.dock show-recents -bool false                # hide "Recent applications"

# -- Trackpad (tap to click, three-finger drag) --
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# -- Screenshots (save to ~/Screenshots, no window-shadow) --
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

# -- Menu bar clock --
# EEE - day of week, MMM - month, d - date. Other formats:
# "EEE MMM d h:mm:ss a" e.g. "Sat Jun 3 5:03:23 pm"
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d HH:mm"

# -- Misc --
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true   # expand Save dialog
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true       # expand Print dialog
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true       # show full URL
defaults write com.apple.TextEdit RichText -int 0                              # TextEdit plain-text default

# apply by restarting affected services (ignore failures if app isn't running)
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

# create a directory for original files if it doesn't exist
[ ! -d "$ORIG_DIR" ] &&
  {
    echo -en "creating dir ($ORIG_DIR)... "
    mkdir "$ORIG_DIR"
    echo "done"
  }

# change working directory to the repo root
OWD=$(pwd)
cd "$SRC_REPO" || exit

# install Homebrew
if brew --version; then
  echo "Homebrew already installed"
else
  echo "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" || exit
fi

# install packages specified in laptop-migration/Brewfile
# (file created with: brew bundle dump --force --file=laptop-migration/Brewfile)
BREWFILE="$SRC_REPO/laptop-migration/Brewfile"
if brew bundle check --file="$BREWFILE"; then
  echo "Homebrew: Don't need to install any additional packages"
else
  echo "Homebrew: Installing packages from $BREWFILE"
  brew bundle --file="$BREWFILE"
fi

# set login shell to Homebrew bash (bash 5.x, not Apple's built-in 3.2)
# - Computed path handles Apple Silicon (/opt/homebrew) + Intel (/usr/local)
# - Registers it in /etc/shells if missing (chsh refuses non-standard shells)
DESIRED_SHELL="$(brew --prefix)/bin/bash"
if [ ! -x "$DESIRED_SHELL" ]; then
  echo "shell: Homebrew bash not found at $DESIRED_SHELL — skipping chsh"
else
  if ! grep -qxF "$DESIRED_SHELL" /etc/shells; then
    echo "shell: adding $DESIRED_SHELL to /etc/shells (requires sudo)"
    echo "$DESIRED_SHELL" | sudo tee -a /etc/shells >/dev/null ||
      echo "  [warn] failed to update /etc/shells — chsh will fail"
  fi
  if [ "$SHELL" != "$DESIRED_SHELL" ]; then
    echo "shell: changing login shell to $DESIRED_SHELL"
    chsh -s "$DESIRED_SHELL" || echo "  [warn] chsh failed — run manually later"
  else
    echo "shell: already using $DESIRED_SHELL"
  fi
fi

# get list of files to process and create symlinks
# (exclude .git — the grep had a trailing slash bug that made it a no-op)
# shellcheck disable=SC2010
for file_or_dir in $(ls -1d .[a-z]* | grep -v '^\.git$'); do
  echo -n "processing: $file_or_dir... "
  if [[ -f "$file_or_dir" ]] || [[ -d $file_or_dir ]]; then # source is a regular file or directory
    if [ -L "$HOME/$file_or_dir" ]; then                    # existing symlink
      echo -n "removing existing symlink... "
      rm -f "$HOME/$file_or_dir"
    elif [[ -f "$HOME/$file_or_dir" ]] || [[ -d "$HOME/$file_or_dir" ]]; then # existing file/dir
      echo -n "saving original file/directory... "
      mv "$HOME/$file_or_dir" "$ORIG_DIR"
      files_saved=true
    else # not found
      echo -n "existing file/directory/symlink not found..."
    fi
    echo -n "creating symlink... "
    ln -s "$SRC_REPO/$file_or_dir" "$HOME/$file_or_dir"
  else # source file/dir is not a regular file or directory, don't link
    echo -n "not a regular file or directory, not creating symlink... "
  fi
  echo "done"
done

# notify user of any saved files and their location
$files_saved && echo "original dot files saved to ${ORIG_DIR/$HOME/\$HOME}"

# install Mac App Store apps listed in laptop-migration/mas.txt
# (requires `mas` CLI from Brewfile + being signed into the App Store GUI)
MAS_FILE="$SRC_REPO/laptop-migration/mas.txt"
if ! command -v mas >/dev/null 2>&1; then
  echo "mas: CLI not installed — skipping App Store restore"
elif [ ! -s "$MAS_FILE" ]; then
  echo "mas: no $MAS_FILE (or empty) — skipping App Store restore"
elif ! mas account >/dev/null 2>&1; then
  echo "mas: not signed into App Store — skipping App Store restore"
  echo "  (sign in via the App Store app, then re-run: mas install \$(awk '{print \$1}' '$MAS_FILE'))"
else
  echo "mas: installing App Store apps from $MAS_FILE"
  while read -r app_id _rest; do
    [ -z "$app_id" ] && continue
    case "$app_id" in \#*) continue ;; esac
    echo "  mas install $app_id ($_rest)"
    mas install "$app_id" || echo "  [warn] failed: $app_id"
  done < "$MAS_FILE"
fi

# set up & configure 'neovim' (with Lua and LazyVim)
# (idempotent: skip if the LazyVim starter is already present — re-running this
#  script previously clobbered customized configs to $NEOVIM_CONFIG.orig)
NEOVIM_CONFIG="$HOME/.config/nvim"
LAZYVIM_URL="https://github.com/LazyVim/starter"
LUA_SRC="$SRC_REPO/config/nvim/lua"
echo "Setting up Neovim"
if [[ -d "$NEOVIM_CONFIG" ]]; then
  echo "Neovim config already exists at '$NEOVIM_CONFIG' - leaving it alone"
  echo "  (to re-bootstrap: rm -rf '$NEOVIM_CONFIG' and re-run setup.sh)"
else
  echo "Cloning LazyVim (Starter) [$LAZYVIM_URL] into '$NEOVIM_CONFIG'"
  git clone "$LAZYVIM_URL" "$NEOVIM_CONFIG"
  rm -rf "$NEOVIM_CONFIG/.git"
  echo "Copying Lua configs from '$LUA_SRC' into '$NEOVIM_CONFIG'"
  cp -Rv "$LUA_SRC" "$NEOVIM_CONFIG"
fi

# restore current working directory location
cd "$OWD" || exit
