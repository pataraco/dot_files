#!/bin/bash

# setup the dot files files
#   1. move existing dot files in $HOME to $HOME/.orig
#   2. set up symlinks from $HOME to the files in the $SRC_REPO
#      (excluding this script, the .git directory and the README file)
#
# some other manual steps
# - MAC:
#        install homebrew
#        $ brew install git

# set up global variables
SRC_REPO="$HOME/repos/pataraco/dot_files"
ORIG_DIR="$HOME/.orig"

# create a directory for original files if it doesn't exist
[ ! -d $ORIG_DIR ] && { echo -en "creating dir ($ORIG_DIR)... "; mkdir $ORIG_DIR; echo "done"; }

# change working directory to the repo root
cd $SRC_REPO

# get list of files to process and create symlinks
for file in $(ls -1d .[a-z]* | grep -wv .git); do
   echo -n "processing: $file... "
   if [ -f $file ]; then  # source file is a regular file, create link
      if [ -L $HOME/$file ]; then  # existing symlink
         echo -n "removing existing symlink... "
         rm -f $HOME/$file
      elif [ -f $HOME/$file ]; then  # existing file
         echo -n "saving original file... "
         mv $HOME/$file $ORIG_DIR
         saved="True"
      else  # not found
         echo -n "existing file/symlink not found..."
      fi
      echo -n "creating symlink... "
      ln -s $SRC_REPO/$file $HOME/$file
   else  # source file is not a regular file, don't link
      echo -n "not a regular file, not creating symlink... "
   fi
   echo "done"
done

# notify user of any saved files and their location
[ "$saved" == "True" ] && echo "original files saved to ${ORIG_DIR/$HOME/\$HOME}"

# restore current working directory location
cd -
