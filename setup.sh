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
DESIRED_SHELL="/bin/bash"

# make sure running on MacBook
if [ "$(uname)" != "Darwin" ]; then
  echo "Kindof only supported on MacBooks"
  exit
fi

# set date/time format in menu bar
# EEE - day of the week, MMM - month, d - date
# other fomats: "EEE MMM d h:mm:ss a" e.g.: "Sat Jun 3 5:03:23 pm"
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d HH:mm" &&
  killall SystemUIServer

# set login shell to /bin/bash
[ "$SHELL" != "$DESIRED_SHELL" ] && chsh -s "$DESIRED_SHELL"

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

# install packages specified in Brewfile
# created with `brew bundle dump`
if brew bundle check; then
  echo "Homebrew: Don't need to install any additonal packages"
else
  echo "Homebrew: Installing packages specified in Brewfile"
  brew bundle
fi

# get list of files to process and create symlinks
# shellcheck disable=SC2010
for file_or_dir in $(ls -1d .[a-z]* | grep -wv ".git/"); do
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

# set up & configure 'neovim' (with Lua and LazyVim)
NEOVIM_CONFIG="$HOME/.config/nvim"
LAZYVIM_URL="https://github.com/LazyVim/starter"
LUA_SRC="$SRC_REPO/config/nvim/lua"
echo "Setting up Neovim"
if [[ -d "$NEOVIM_CONFIG" ]]; then
  echo "Neovim config already exists at '$NEOVIM_CONFIG' - saving original as '$NEOVIM_CONFIG.orig'"
  mv "$NEOVIM_CONFIG" "$NEOVIM_CONFIG.orig"
fi
echo "Cloning LazyVim (Starter) [$LAZYVIM_URL] into Neovim config directory [$NEOVIM_CONFIG]"
git clone "$LAZYVIM_URL" "$NEOVIM_CONFIG"
rm -rf "$NEOVIM_CONFIG/.git"
echo "Copying Lua configs from '$LUA_SRC' into '$NEOVIM_CONFIG'"
cp -Rv "$LUA_SRC" "$NEOVIM_CONFIG"

# restore current working directory location
cd "$OWD" || exit
