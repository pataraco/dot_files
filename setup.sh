#!env bash

# setup the bash_aliases files
#   1. move existing . files to ~/.orig
#   2. set up symlinks from ~ to the files in this repo
#      (excluding this script, .git directory and the README)

SRC_REPO="$HOME/repos/bash_aliases"
ORIG_DIR="$HOME/.orig"
EXCLUDE_FILES=(
   .
   ..
   .git
   README.md
   setup.sh
)
EGREP_PAT=$(echo "${EXCLUDE_FILES[*]}" | tr ' ' '|')
[ ! -d $ORIG_DIR ] && { echo -en "creating dir ($ORIG_DIR)... "; mkdir $ORIG_DIR; echo "done"; }
#debug#echo "egrep pattern: '$EGREP_PAT'"
cd $SRC_REPO
for file in $(ls -a1 | egrep -wv "$EGREP_PAT"); do
   echo "processing file: $file"
   if [ -e $HOME/$file ]; then
      echo -en "   moving original file ($HOME/$file) to $ORIG_DIR... "
      mv $HOME/$file $ORIG_DIR
      echo "done"
   fi
   echo -en "   creating symlink: $HOME/$file -> $SRC_REPO/$file... "
   ln -s $SRC_REPO/$file $HOME/$file
   echo "done"
done
cd -
