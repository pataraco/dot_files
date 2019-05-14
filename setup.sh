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

SRC_REPO="$HOME/repos/dot_files"
ORIG_DIR="$HOME/.orig"
[ ! -d $ORIG_DIR ] && { echo -en "creating dir ($ORIG_DIR)... "; mkdir $ORIG_DIR; echo "done"; }
cd $SRC_REPO
for file in $(ls -1d .[a-z]* | grep -wv .git); do
   echo "processing file: $file"
   if [ -f $HOME/$file ]; then
      echo -en "   moving original file ($HOME/$file) to $ORIG_DIR... "
      mv $HOME/$file $ORIG_DIR
      echo "done"
   fi
   if [ -h $HOME/$file ]; then
      echo -en "   removing old symlink ($HOME/$file)... "
      rm -f $HOME/$file
      echo "done"
   fi
   echo -en "   creating symlink: $HOME/$file -> $SRC_REPO/$file... "
   ln -s $SRC_REPO/$file $HOME/$file
   echo "done"
done
cd -
