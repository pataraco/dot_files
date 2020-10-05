#!/usr/bin/env bash

# file: ~/.bash_aliases - sourced by ~/.bashrc

# shellcheck disable=SC1090,SC2034,SC2139,SC2142,SC1117

# -------------------- initial directives --------------------

# update change the title bar of the terminal
echo -ne "\033]0;$(whoami)@$(hostname)\007"

# show Ansible, Chef or Python versions in prompt
PS_SHOW_AV=0
PS_SHOW_CV=0
PS_SHOW_PV=0

# -------------------- global variables --------------------

MAIN_BA_FILE=".bash_aliases"

# if interactive shell - display message
[ -n "$PS1" ] && echo -n "$MAIN_BA_FILE (begin)... "

# some ansi colorization escape sequences
[ "$(uname)" == "Darwin" ] && ESC="\033" || ESC="\e"
export BLK="${ESC}[30m"   # black FG
export BLU="${ESC}[34m"   # blue FG
export CYN="${ESC}[36m"   # cyan FG
export GRN="${ESC}[32m"   # green FG
export MAG="${ESC}[35m"   # magenta FG
export RED="${ESC}[31m"   # red FG
export WHT="${ESC}[37m"   # white FG (same as 38 & 39)
export YLW="${ESC}[33m"   # yellow FG
export BBB="${ESC}[40m"   # black BG
export BBG="${ESC}[44m"   # blue BG
export CBG="${ESC}[46m"   # cyan BG
export GBG="${ESC}[42m"   # green BG
export MBG="${ESC}[45m"   # magenta BG
export RBG="${ESC}[41m"   # red BG
export WBG="${ESC}[47m"   # white BG
export YBG="${ESC}[43m"   # yellow BG
export BLD="${ESC}[1m"    # bold
export BNK="${ESC}[5m"    # slow blink
export D2B="${ESC}[1K"    # delete to BOL
export D2E="${ESC}[K"     # delete to EOL
export DAL="${ESC}[2K"    # delete all of line
export HDC="${ESC}[?25l"  # hide cursor
export NRM="${ESC}[m"     # to make text normal
export SHC="${ESC}[?25h"  # show cursor
export ULN="${ESC}[4m"    # underlined

# for changing prompt colors
PBLK='\[\e[1;30m\]'  # black (bold)
PBLU='\[\e[1;34m\]'  # blue (bold)
PCYN='\[\e[1;36m\]'  # cyan (bold)
PGRN='\[\e[1;32m\]'  # green (bold)
PGRY='\[\e[1;30m\]'  # grey (bold black)
PMAG='\[\e[1;35m\]'  # magenta (bold)
PRED='\[\e[1;31m\]'  # red (bold)
PWHT='\[\e[1;37m\]'  # white (bold)
PYLW='\[\e[1;33m\]'  # yellow (bold)
PBBG='\[\e[1;44m\]'  # blue BG (bold)
PCBG='\[\e[1;46m\]'  # cyan BG (bold)
PGBG='\[\e[1;42m\]'  # green BG (bold)
PMBG='\[\e[1;45m\]'  # magenta BG (bold)
PRBG='\[\e[1;41m\]'  # red BG (bold)
PWBG='\[\e[1;47m\]'  # white BG (bold)
PYBG='\[\e[1;43m\]'  # yellow BG (bold)
PNRM='\[\e[m\]'      # to make text normal

# set xterm defaults
XTERM='xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000'

# set/save original bash prompt
ORIG_PS1=$PS1

# directory where all (most) repos are
REPO_DIR=$HOME/repos

# -------------------- shell settings --------------------

# turn on `vi` command line editing - oh yeah!
set -o vi

# show 3 directories of CWD in prompt
export PROMPT_DIRTRIM=3
# some bind settings
bind Space:magic-space

# # change grep color to light yelow highlighting with black fg
# export GREP_COLOR="5;43;30"
# change grep color to light green fg on black bg
export GREP_COLOR="1;40;32"

# -------------------- define functions --------------------

function _tmux_send_keys_all_panes {
   # send keys to all tmux panes
   for _pane in $(tmux list-panes -F '#P'); do
      tmux send-keys -t "${_pane}" "$@" Enter
   done
}

function bash_prompt {
   # customize Bash Prompt
   local _last_cmd_exit_status=$?
   local _versions_len=0
   if [ $PS_SHOW_CV -eq 1 ]; then  # get Chef version
      if [ -z "$CHEF_VERSION" ]; then
         export CHEF_VERSION
         CHEF_VERSION=$(knife --version 2>/dev/null | head -1 | awk '{print $NF}')
      fi
      PS_CHF="${PYLW}C$CHEF_VERSION$PNRM|"
      (( _versions_len += ${#CHEF_VERSION} + 2 ))
   fi
   if [ $PS_SHOW_AV -eq 1 ]; then  # get Ansible version
      if [ -z "$ANSIBLE_VERSION" ]; then
         export ANSIBLE_VERSION
         ANSIBLE_VERSION=$(ansible --version 2>/dev/null | head -1 | awk '{print $NF}')
      fi
      PS_ANS="${PCYN}A$ANSIBLE_VERSION$PNRM|"
      (( _versions_len += ${#ANSIBLE_VERSION} + 2 ))
   fi
   if [ $PS_SHOW_PV -eq 1 ]; then  # get Python version
      export PYTHON_VERSION
      PYTHON_VERSION=$(python --version 2>&1 | awk '{print $NF}')
      PS_PY="${PMAG}P$PYTHON_VERSION$PNRM|"
      (( _versions_len += ${#PYTHON_VERSION} + 2 ))
   fi
   local _git_branch _git_branch_len _git_status
   local _git_has_mods=false        _git_has_mods_cached=false
   local _git_has_adds=false        _git_has_renames=false
   local _git_has_dels=false        _git_has_dels_cached=false
   local _git_ready_to_commit=false _git_has_untracked_files=false
   # get git info
   if git branch &> /dev/null; then   # in a git repo
      _git_branch=$(git rev-parse --quiet --abbrev-ref HEAD 2>/dev/null)
      _git_branch_len=$(( ${#_git_branch} + 1 ))
      _git_status=$(git status --porcelain 2> /dev/null)
      [[ "$_git_status" =~ ($'\n'|^).M ]] && _git_has_mods=true
      [[ "$_git_status" =~ ($'\n'|^)M ]] && _git_has_mods_cached=true
      [[ "$_git_status" =~ ($'\n'|^)A ]] && _git_has_adds=true
      [[ "$_git_status" =~ ($'\n'|^)R ]] && _git_has_renames=true
      [[ "$_git_status" =~ ($'\n'|^).D ]] && _git_has_dels=true
      [[ "$_git_status" =~ ($'\n'|^)D ]] && _git_has_dels_cached=true
      [[ "$_git_status" =~ ($'\n'|^)\?\? ]] && _git_has_untracked_files=true
      [[ "$_git_status" =~ ($'\n'|^)[ADMR] && ! "$_git_status" =~ ($'\n'|^).[ADMR\?] ]] && _git_ready_to_commit=true
      if $_git_ready_to_commit; then
         [ -n "$PS_DEBUG" ] && echo "debug: status='$_git_status' git ready to commit"
         PS_GIT="$PNRM${PGRN}✅ ${_git_branch}✔$PNRM"
         (( _git_branch_len++ ))
      elif $_git_has_mods_cached || $_git_has_dels_cached; then
         [ -n "$PS_DEBUG" ] && echo "debug: status='$_git_status' git has mods cached or has dels cached"
         PS_GIT="$PNRM${PCYN}⚠️ ${_git_branch}+$PNRM"
         (( _git_branch_len++ ))
      elif $_git_has_mods || $_git_has_renames || $_git_has_adds || $_git_has_dels; then
         [ -n "$PS_DEBUG" ] && echo "debug: status='$_git_status' git has mods or adds or dels"
         PS_GIT="$PNRM${PRED}⛔️ ${_git_branch}*$PNRM"
         (( _git_branch_len++ ))
      elif $_git_has_untracked_files; then
         [ -n "$PS_DEBUG" ] && echo "debug: status='$_git_status' git has untracked files"
         PS_GIT="$PNRM${PYLW}⁉️ ${_git_branch}$PNRM"
      else
         [ -n "$PS_DEBUG" ] && echo "debug: status='$_git_status' git is ???"
         _git_status=$(git status -bs 2> /dev/null | grep -F "ahead")
         if [[ "$_git_status" =~ \[ahead.*\] ]]; then
            [ -n "$PS_DEBUG" ] && echo "debug: status='$_git_status' git is ahead"
            local _gitahead
            _gitahead=$({ awk '{print $NF}' | cut -d']' -f1; } <<< "$_git_status")
            PS_GIT="$PNRM${PMAG}🤙 ${_git_branch}>$_gitahead$PNRM"
            (( _git_branch_len += 1 + ${#_gitahead} ))
         else
            PS_GIT="$PNRM${PNRM}${_git_branch}$PNRM"
         fi
      fi
      if $_git_has_untracked_files; then
         PS_GIT="$PNRM$PS_GIT$PYLW?$PNRM"
         (( _git_branch_len++ ))
      fi
      PS_GIT="$PS_GIT|"
   else   # NOT in a git repo
      [ -n "$PS_DEBUG" ] && echo "debug: not a git repo"
      PS_GIT=""
      _git_branch_len=0
   fi
   # customize path depending on width/space available
   local _space_for_path=$((COLUMNS - _versions_len - _git_branch_len))
   local _pwd=${PWD/$HOME/'~'}
   if [  ${#_pwd} -lt $_space_for_path ]; then
      PS_PATH="$PGRN\w$PNRM"
   else
      (( _space_for_path -= 2 ))
      local _ps_path_start_pos=$((${#_pwd} - _space_for_path))
      local _ps_path_chopped="..${_pwd:$_ps_path_start_pos:$_space_for_path}"
      PS_PATH="$PGRN${_ps_path_chopped}$PNRM"
   fi
   # PS_WHO="$PBLU\u@\h$PNRM"
   CMD_PASS_EMOJIS=(😀 😃 😄 😁 😆 😊 🙃 😋 😛 😝 😍 😜 🤗 😬 😎)
   CMD_FAIL_EMOJIS=(😡 👿 🤔 😵 😥 😰 👎 😱 😭 😢 🖕 🤢 😤 💩 💀)
   PS_DELIM="-"
   if [ $_last_cmd_exit_status -eq 0 ]; then
      PS_EMOJI=${CMD_PASS_EMOJIS[$((RANDOM % ${#CMD_PASS_EMOJIS[*]}))]}
      PS_WHO="${PS_EMOJI}${PS_DELIM}${PBLK}$(basename "$SHELL")${PNRM}${PS_DELIM}"
      PS_COL=$PGRN
   else
      PS_EMOJI=${CMD_FAIL_EMOJIS[$((RANDOM % ${#CMD_FAIL_EMOJIS[*]}))]}
      PS_WHO="${PS_EMOJI}${PS_DELIM}${PBLK}$(basename "$SHELL")${PNRM}${PS_DELIM}"
      PS_COL=$PRED
   fi
   if [ "$COMPANY" == "onica" ] && [ -n "$ONICA_SSO_ACCOUNT_KEY" ] && [ -n "$ONICA_SSO_EXPIRES_TS" ]; then
      local _now_ts
      _now_ts=$(date +%s)
      if [ "$ONICA_SSO_EXPIRES_TS" -gt "$_now_ts" ]; then
         # set the window title
         echo -ne "\033]0;$(whoami)@$(hostname)-[$ONICA_SSO_ACCOUNT_KEY]\007"
         if [ $((ONICA_SSO_EXPIRES_TS - _now_ts)) -lt 900 ]; then
            PS_AWS="[$PYLW$ONICA_SSO_ACCOUNT_KEY$PNRM]"
            PS_COL=$PYLW
         else
            PS_AWS="[$PRED$ONICA_SSO_ACCOUNT_KEY$PNRM]"
            PS_COL=$PRED
         fi
      else
         # set the window title
         echo -ne "\033]0;$(whoami)@$(hostname)-[$ONICA_SSO_ACCOUNT_KEY](EXPIRED)\007"
         PS_AWS="[$PGRY$ONICA_SSO_ACCOUNT_KEY$PNRM]"
         PS_COL=$PGRY
      fi
   elif [ "$COMPANY" == "ag" ] && [ -n "$AWS_SESSION_TOKEN" ] && [ -n "$AWS_DEFAULT_PROFILE" ] && [ -n "$AWS_STS_EXPIRES_TS" ]; then
      local _now_ts
      _now_ts=$(date +%s)
      # local _exp_time=$(jq -r .Credentials.Expiration ~/.aws/${AWS_DEFAULT_PROFILE}_mfa_credentials)
      # local _exp_ts=$(date -jf "%Y-%m-%dT%H:%M:%SZ" $_exp_time +"%s")
      local _exp_ts=$AWS_STS_EXPIRES_TS
      if [ "$_exp_ts" -gt "$_now_ts" ]; then
         # TODO: disabling sts lookup until i can come up with a faster solution
         if echo aws sts get-caller-identity &> /dev/null; then
            # set the window title
            local _tminus
            _tminus=$(date -jf "%s" $((_exp_ts - _now_ts)) +"(T-%H:%M:%S)")
            echo -ne "\033]0;$(whoami)@$(hostname)-[$AWS_DEFAULT_PROFILE]$_tminus\007"
            if [ $((_exp_ts - _now_ts)) -lt 900 ]; then
               PS_AWS="[${PYLW}${AWS_DEFAULT_PROFILE}${PNRM}]"
               PS_COL=$PYLW
            fi
         else
            export AWS_STS_EXPIRES_TS=$_now_ts
            rm -f "$HOME/.aws/${AWS_DEFAULT_PROFILE}_mfa_credentials"
            # set the window title
            echo -ne "\033]0;$(whoami)@$(hostname)-[$AWS_DEFAULT_PROFILE](EXPIRED)\007"
            PS_AWS="[$PGRY$AWS_DEFAULT_PROFILE$PNRM]"
            PS_COL=$PGRY
         fi
      else
         # set the window title
         echo -ne "\033]0;$(whoami)@$(hostname)-[$AWS_DEFAULT_PROFILE](EXPIRED)\007"
         PS_AWS="[$PGRY$AWS_DEFAULT_PROFILE$PNRM]"
         PS_COL=$PGRY
      fi
   else
      # set the window title
      echo -ne "\033]0;$(whoami)@$(hostname)\007"
   fi
   # check for pyenv virtual environment
   [ -n "$VIRTUAL_ENV" ] && PS_PROJ="($PCYN$(basename "$VIRTUAL_ENV")$PNRM)" || PS_PROJ=""
   # check for jobs running in the background
   if [ "$(jobs | wc -l | tr -d ' ')" -gt 1 ]; then
      # using "1" because the `git branch` above runs in the background
      PS1="\n$PS_GIT$PS_CHF$PS_ANS$PS_PY$PS_PATH\n$PS_PROJ$PS_AWS$PS_WHO(\j)${PS_COL}⌲$PNRM "
   else
      PS1="\n$PS_GIT$PS_CHF$PS_ANS$PS_PY$PS_PATH\n$PS_PROJ$PS_AWS$PS_WHO${PS_COL}⌲$PNRM "
   fi
}

function ccc {
   # Synchronize tmux windows
   for I in "$@"; do
      tmux splitw "ssh $I"
      tmux select-layout tiled
   done
   tmux set-window-option synchronize-panes on
   exit
}

function cgcai {
   # Fixes git commiter and author info for all commits in repo
   # taken from: https://help.github.com/articles/changing-author-info/
   # how to use
   # 1. git clone --bare REPO.git
   # 2. cd REPO.git
   # 3. cgcai OLD_EMAIL CORRECT_NAME CORRECT_EMAIL
   # 4. review git history for errors
   # 5. git push --force --tags origin 'refs/heads/*'
   # 6. cd ..
   # 7. rm -rf REPO.git
   OLD_EMAIL=$1     # OLD_EMAIL="your-old-email@example.com"
   CORRECT_NAME=$2  # CORRECT_NAME="Your Correct Name"
   CORRECT_EMAIL=$3 # CORRECT_EMAIL="your-correct-email@example.com"
   git filter-branch --env-filter '
      if [ "$GIT_COMMITTER_EMAIL" = "'"$OLD_EMAIL"'" ]; then
         export GIT_COMMITTER_NAME="'"$CORRECT_NAME"'"
         export GIT_COMMITTER_EMAIL="'"$CORRECT_EMAIL"'"
      fi
      if [ "$GIT_AUTHOR_EMAIL" = "'"$OLD_EMAIL"'" ]; then
         export GIT_AUTHOR_NAME="'"$CORRECT_NAME"'"
         export GIT_AUTHOR_EMAIL="'"$CORRECT_EMAIL"'"
      fi
   ' --tag-name-filter cat -- --branches --tags
   echo "now run: git push --force --tags origin 'refs/heads/*'"
}

function chkrepodiffs {
   # usage: chkrepodiffs [-v] [file]
   # checks files in current dir against file in home dir for diffs
   # only works on https://github.com/pataraco/dot_files repo now
   # comparing those files against those in home directory
   cd ~/repos/pataraco/dot_files || return
   local _verbose="$1"
   if [ "$_verbose" == "-v" ]; then
      shift
   fi
   local _files="$*"
   local _file
   # shellcheck disable=SC2010
   [ -z "$_files" ] && _files=$(ls -1A | grep -v .git)
   for _file in $_files; do
      if [ -e "$_file" ] && [ -e "$HOME/$_file" ]; then
         diff -q "$_file" "$HOME/$_file"
         if [ $? -eq 1 ]; then
            if [ "$_verbose" == "-v" ]; then
              read -rp "Hit [Enter] to continue" junk
              diff "$_file" "$HOME/$_file" | \less -rX
              echo
            fi
         else
            echo "Files $_file and ~/$_file are the same"
         fi
      else
         [ ! -e "$_file" ] && ls "$_file"
         [ ! -e "$HOME/$_file" ] && ls "$HOME/$_file"
      fi
   done
   cd - > /dev/null || return
}

function checksums {
   # Generate multiple kinds of different checksums for a file
   local _file
   local _check_sum_cmd_names="cksum md5sum shasum sum"
   local _check_sum_cmd_name
   local _check_sum_cmd
   local _max_cmd_name_len=0
   for _check_sum_cmd_name in $_check_sum_cmd_names; do
      [ $_max_cmd_name_len -lt ${#_check_sum_cmd_name} ] \
         && _max_cmd_name_len=${#_check_sum_cmd_name}
   done
   if [ $# -eq 1 ]; then
      _file=$1
      echo "File: $_file"
      echo "----------------"
      for _check_sum_cmd_name in $_check_sum_cmd_names; do
         _check_sum_cmd=$(command -v "$_check_sum_cmd_name")
         if [ -n "$_check_sum_cmd" ]; then
            # echo -n "$_check_sum_cmd_name : "
            printf "%-${_max_cmd_name_len}s : " "$_check_sum_cmd_name"
            $_check_sum_cmd "$_file" | awk '{print $1}'
         else
            echo "$_check_sum_cmd_name : command not found"
         fi
      done
   else
      echo "you didn't specify a file to calculate the checksums for"
   fi
}

function cktj {
   # convert a key file so that it can be used in a 
   # json entry (i.e. change \n -> "\n")
   if [ -n "$1" ]; then
      tr '\n' '_' < "$1" | sed 's/_/\\n/g'
      echo
   else
      echo "error: you did not specify a key file to convert"
   fi
}

function compare_lines {
   # compare two lines and colorize the diffs
   local _line1="$1 "
   local _line2="$2 "
   local _line1diffs
   local _line2diffs
   local _newword
   local _word
   for _word in $_line1; do
      if grep -F -q -- "$_word " <<< "$_line2"; then
         _newword=$_word
      else
         _newword="${RED}$_word${NRM}"
      fi
      _line1diffs="$_line1diffs $_newword"
   done
   # shellcheck disable=SC2001
   _line1diffs=$(sed 's/^ //' <<< "$_line1diffs")
   for _word in $_line2; do
      if grep -F -q -- "$_word " <<< "$_line1"; then
         _newword=$_word
      else
         _newword="${GRN}$_word${NRM}"
      fi
      _line2diffs="$_line2diffs $_newword"
   done
   # shellcheck disable=SC2001
   _line2diffs=$(sed 's/^ //' <<< "$_line2diffs")
   echo -e "\t--------------------- missing in red ---------------------"
   echo -e "$_line1diffs"
   echo -e "\t--------------------- added in green ---------------------"
   echo -e "$_line2diffs"
}

# This is commented out because it was for a previous place of 
# employment using Informix
# TODO: update for mysql and uncomment
##function dbgrep {
##   # search/grep informix DB for patterns in tables/column names
##   # OPTIONS
##   # -w search for whole words only
##   # -t search table  names for a pattern:
##   #     display "matching table names"
##   # -c search column names for a pattern:
##   #     display "matching column names"
##   # -i search table  names for a pattern and get info:
##   #     display "table name: column1, column2, etc."
##   # -a search for tables containing patterns in column name:
##   #     display "table name1, table name2, etc."
##   NOT_VALID_HOSTS="jump1 jump2 stcgxyjmp01"
##   USAGE="dbgrep [-w] -t|c|i|a PATTERN"
##
##   echo "$NOT_VALID_HOSTS" | grep -w $HOSTNAME >/dev/null 2>&1
##   if [ $? -eq 0 ]; then
##      echo "can't run this on any of these hosts: '$NOT_VALID_HOSTS'"
##      return
##   fi
##   grepopt="-i"
##   searchtype="containing"
##   if [ $# -eq 3 ]; then
##      if [ $1 = "-w" ]; then
##         grepopt="-iw"
##         searchtype="matching"
##         shift
##      else
##         echo "usage: $USAGE"
##         return
##      fi
##   fi
##   if [ $# -eq 2 ]; then
##      option=$1
##      pattern=$2
##      case $option in
##         -t)
##            echo "table name(s) $searchtype '$pattern':"
##            for table in `echo "info tables"|dbaccess dev 2>/dev/null|grep $grepopt "$pattern"`; do
##               echo $table | grep $grepopt "$pattern"
##            done
##            echo "======"
##            if [ "$searchtype" = "matching" ]; then
##               echo "select tabname from systables where tabname='$pattern'"|dbaccess dev
##            else
##               echo "select tabname from systables where tabname like '%$pattern%'"|dbaccess dev
##            fi
##            ;;
##         -c)
##            echo "column name(s) $searchtype '$pattern' (be patient):"
##            for table in `echo "info tables"|dbaccess dev 2>/dev/null`; do
##               echo "info columns for $table"|dbaccess dev 2>/dev/null|awk '{print $1}'|grep $grepopt "$pattern"
##            done|sort -u
##            ;;
##         -i)
##            echo "info about table name(s) $searchtype '$pattern':"
##            for table in `echo "info tables"|dbaccess dev 2>/dev/null|grep $grepopt "$pattern"`; do
##               echo $table | grep $grepopt "$pattern" >/dev/null 2>&1
##               if [ $? -eq 0 ]; then
##                  echo "table: $table"
##                  echo "info columns for $table"|dbaccess dev 2>/dev/null
##                  echo "	-------"
##               fi
##            done
##            ;;
##         -a)
##            echo "table name(s) with column(s) $searchtype '$pattern':"
##            for table in `echo "info tables"|dbaccess dev 2>/dev/null`; do
##               columns=`echo "info columns for $table"|dbaccess dev 2>/dev/null|awk '{print $1}'|grep $grepopt "$pattern"`
##               if [ $? = 0 ]; then
##                  for column in $columns; do
##                     printf "%-20s: %s\n" $table $column
##                  done
##               fi
##            done
##            ;;
##         * )
##            echo "usage: $USAGE"
##            ;;
##      esac
##   else
##      echo "usage: $USAGE"
##   fi
##}

function decimal_to_base32 {
   # convert a decimal number to base 32
   local _BASE32
   IFS=" " read -r -a _BASE32 <<< "$(echo {0..9} {a..v})"
   local _arg1="$*"
   for i in $(bc <<< "obase=32; $_arg1"); do
      echo -n "${_BASE32[$((10#$i))]}"
   done && echo
}

function decimal_to_base36 {
   # convert a decimal number to base 36
   local _BASE36
   IFS=" " read -r -a _BASE36 <<< "$(echo {0..9} {a..z})"
   local _arg1="$*"
   for i in $(bc <<< "obase=36; $_arg1"); do
      echo -n "${_BASE36[$((10#$i))]}"
   done && echo
}

function decimal_to_baseN {
   # convert a decimal number to any base
   local _DIGITS
   IFS=" " read -r -a _DIGITS <<< "$(echo {0..9} {a..z})"
   if [ $# -eq 2 ]; then
      local _base="$1"
      if [ "$_base" -lt 2 ] || [ "$_base" -gt 36 ]; then
         echo "base must be between 2 and 36"
         return 2
      fi
      shift
      local _decimal="$*"
      if [ "$_base" -le 16 ]; then
         echo "obase=$_base; $_decimal" | bc | tr '[:upper:]' '[:lower:]'
      else
         for i in $(bc <<< "obase=$_base; $_decimal"); do
            echo -n "${_DIGITS[$((10#$i))]}"
         done && echo
      fi
      else
      echo "usage: decimal_to_base BASE_DESIRED DECIAML_NUMBER"
   fi
   return 0
}

function dj {
   # either add a daily journal entry provided on the command line or edit it
   DAILY_JOURNAL_DIR="$HOME/notes"
   DAILY_JOURNAL_FILE="$DAILY_JOURNAL_DIR/Daily_Journal.txt"
   [ ! -d "$DAILY_JOURNAL_DIR" ] && mkdir "$DAILY_JOURNAL_DIR"
   if [ $# -ne 0 ]; then
      case $1 in
         cat) cat "$DAILY_JOURNAL_FILE" ;;
         help) echo "usage: dj [cat|help|last|tail|LOG_ENTRY]" ;;
         last) tail -n 1 "$DAILY_JOURNAL_FILE" ;;
         tail) tail "$DAILY_JOURNAL_FILE" ;;
         *) echo "$(date +'%d-%m-%Y'): $*" >> "$DAILY_JOURNAL_FILE" ;;
      esac
   else
      $VIM_CMD "$DAILY_JOURNAL_FILE"
   fi
}

# shellcheck disable=SC2155
function fdgr {
   # find dirty git repos
   local _REPOS_TO_CHECK
   local _DEFAULT_FIND_DIR="$HOME/repos"
   local _FIND_DIR
   if [ -n "$1" ]; then
      _FIND_DIR=$(sed 's:/$::' <<< $1)
   else
      _FIND_DIR=$_DEFAULT_FIND_DIR
   fi
   local _EXCLUDE_DIRS="
      .aws-sam
      .cookiecutters
      .git
      .jenkins
      .kube
      .local/share/nvim
      .pyenv-repository
      .serverless
      .terraform
      .tmux/plugins
      Applications
      Desktop
      Documents
      Downloads
      Library
      Movies
      Music
      Pictures
      Postman
      Public
      awacs
      awslabs
      formica
      go/src
      others
      sceptre
      terraform-aws-modules
      tmux
      tmux.wiki
      troposphere
   "
   local _dir
   local _excludes=()
   local _git_status
   local _last_status
   local _orig_wd=$(pwd)
   local _repo
   for _dir in ${_EXCLUDE_DIRS}; do
      # all find results start with './'
      # look for beginning "./" for specific dir to exclude, otherwise match all
      [[ ${_dir%%[^./]*} != "./" ]] && _dir="*/${_dir}"
      _excludes+=(! -path "$_dir/*" -a)
   done
   # echo "debug: _excludes='${_excludes[*]}'"

   echo -ne "finding ALL 'git' repos (dirs)... ${BNK}"
   _REPOS_TO_CHECK="$(\
      find "$_FIND_DIR" \
         "${_excludes[@]}" \
         -type d \
         -name .git \
         -exec dirname {} \; 2> /dev/null | \
      tr ' ' '%')"
   echo -ne "${NRM}done${HDC}\r"
   # echo "debug: _REPOS_TO_CHECK='$_REPOS_TO_CHECK'"
   for _dir in $_REPOS_TO_CHECK; do
      _repo=${_dir//\%/ }
      cd "$_repo" || return
      _gitstatus=$(git status --porcelain 2> /dev/null)
      if [ -n "$_gitstatus" ]; then
         echo -e "${_repo/$HOME/~} [${RED}DIRTY${NRM}]${D2E}"
         _last_status="DIRTY"
      else
         echo -ne "${_repo/$HOME/~} [${GRN}CLEAN${NRM}]${D2E}\r"
         _last_status="CLEAN"
      fi
      cd - > /dev/null || return
   done
   cd "$_orig_wd" || return
   [ "$_last_status" == "CLEAN" ] && echo -ne "${D2E}"
   echo -ne "${SHC}"
}

function gdate {
   # convert hex date value to date
   # see the 'guid' alias to create a hex date value
   if [ "$(uname)" == "Darwin" ]; then
      date -jf "%s" "$(printf "%d\n" 0x"$1")"
   else
      date --date=@"$(printf "%d\n" 0x"$1")"
   fi
}

##function getramsz {
### get the amount of RAM on a server
## JUMP_SERVERS="jump1 jump2 stcgxyjmp01"
## USAGE="usage: getramsz [server] [server2] [server3]..."
##   echo "$JUMP_SERVERS" | grep -w $HOSTNAME >/dev/null 2>&1
##   if [ $? -eq 0 -a $# -gt 0 ]; then
##      servers="$*"
##      remote=true
##   elif [ $# -eq 0 ]; then
##      servers=$HOSTNAME
##      remote=false
##   else
##      echo "$USAGE"
##      return
##   fi
##   for server in $servers; do
##      host $server > /dev/null
##      if [ $? -eq 0 ]; then
##         total_mem=0
##         echo -n "$server: RAM installed: 'hpasmcli' calculating... "
##         if [ "$remote" = "true" ]; then
##            #for dimm_size in `ssh ecisupp@$server 'hpasmcli -s "show dimm" | grep Size' 2>/dev/null | awk '{print $2}'`; do
##            for dimm_size in `ssh -q ecisupp@$server 'hpasmcli -s "show dimm" | grep Size' 2>/dev/null | awk '{print $2}'`; do
##               total_mem=`expr $total_mem + $dimm_size`
##            done
##         else
##            for dimm_size in `hpasmcli -s "show dimm" | grep Size 2>/dev/null | awk '{print $2}'`; do
##               total_mem=`expr $total_mem + $dimm_size`
##            done
##         fi
##         if [ $total_mem -eq 0 ]; then
##            hpasmcli_val="( ERROR )"
##         else
##            total_mem_gb=`expr $total_mem / 1024`
##            hpasmcli_val=`printf "[ %2d GB ]" $total_mem_gb`
##         fi
##         echo -ne "\r$server: RAM installed: 'hpasmcli' $hpasmcli_val... 'free' calculating... "
##         if [ "$remote" = "true" ]; then
##            #free_size=`ssh ecisupp@$server 'free | grep Mem' 2>/dev/null | awk '{print $2}'`
##            free_size=`ssh -q ecisupp@$server 'free | grep Mem' 2>/dev/null | awk '{print $2}'`
##         else
##            free_size=`free | grep Mem 2>/dev/null | awk '{print $2}'`
##         fi
##         [ -z "$free_size" ] && free_size=0
##         if [ $free_size -eq 0 ]; then
##            free_val="( ERROR )"
##         else
##            free_mem_gb=`expr $free_size / 1024 / 1024 + 1`
##            free_val=`printf "[ %2d GB ]" $free_mem_gb`
##         fi
##         echo -e "\r$server: RAM installed: 'hpasmcli' $hpasmcli_val... 'free' $free_val\e[K"
##      else
##         echo -n "$server: unknown host"
##      fi
##   done
##}

function gh {
   # grep bash history for a PATTERN
   # shellcheck disable=SC1001
   if [[ $* =~ ^\^.* ]]; then
      pattern=$(echo "$*" | tr -d '^')
      #echo "debug: looking for: ^[0-9]*  $pattern"
      history | grep "^[ 0-9]*  $pattern" | grep --color=always "$pattern"
   else
      #echo "debug: looking for: $*"
      history | grep --color=always "$*"
   fi
}

function gl {
   # grep and pipe to less
   eval grep --color=always "$@" | less
}

function gpw {
   # generate a password and copy to the clipboard
   DEFAULT_LENGTH=25
   REQ_CMDS="pwgen pbcopy"
   local _cmd
   for _cmd in $REQ_CMDS; do
      [ ! "$(command -v "$_cmd")" ] && { echo "error: missing command '$_cmd'"; return 1; } 
   done
   local _pws=${1:-$DEFAULT_LENGTH}
   pwgen -y "$_pws" 1 | tr -d '\n' | pbcopy
}

function j2y {
   # convert JSON to YAML (from either STDIN or by specifying a file
   if [ -n "$1" ]; then
      python -c 'import json, sys, yaml; yaml.safe_dump(json.load(sys.stdin), sys.stdout)' < "$1"
   else
      python -c 'import json, sys, yaml; yaml.safe_dump(json.load(sys.stdin), sys.stdout)'
   fi
}

function lgr {
   # list GitHub Repos for a user
   local _DEFAULT_USER="pataraco"
   local _GIT_URL_OPT=$1
   [ "$_GIT_URL_OPT" == "-g" ] && shift
   local _USER=${1:-$_DEFAULT_USER}
   if [ "$_GIT_URL_OPT" == "-g" ]; then
      curl -s "https://api.github.com/users/$_USER/repos" | \
         grep clone_url | \
         awk '{print $2}' | \
         tr -d '",' | \
         sed 's^https://github.com/^git@github.com:^'
   else
      curl -s "https://api.github.com/users/$_USER/repos" | \
         grep clone_url | \
         awk '{print $2}' | \
         tr -d '",'
   fi
}

function listcrts {
   # list all info in a crt bundle
   # usage:
   #    listcrts [cert_file] [openssl_options]
   #       cert_file       (arg 1) - name of cert file
   #         (optional - otherwise all *.crt files)
   #       openssl_options (arg 2) - openssl options
   #         (e.g. -subject|dates|text|serial|pubkey|modulus
   #               -purpose|fingerprint|alias|hash|issuer_hash)
   #    (default options: -subject -dates -issuer and always: -noout)
   #    (add options with a "+", e.g.: +serial)
   local _DEFAULT_OPENSSL_OPTS="-subject -dates -issuer"
   local _cbs _cb
   local _cert_bundle=$1
   if [ "${_cert_bundle: -3}" == "crt" ]; then
      shift
   else
      unset _cert_bundle
   fi
   local _openssl_opts="$*"
   if grep -q '+[a-z].*' <<< "$_openssl_opts"; then
      _openssl_opts="$_DEFAULT_OPENSSL_OPTS ${_openssl_opts//+/-}"
   fi
   _openssl_opts=${_openssl_opts:=$_DEFAULT_OPENSSL_OPTS}
   _openssl_opts="$_openssl_opts -noout"
   # echo "debug: opts: '$_openssl_opts'"
   if [ -z "$_cert_bundle" ]; then
      if ls ./*.crt > /dev/null 2>&1; then
         echo "certificate(s) found"
         _cbs=$(ls ./*.crt)
      else
         echo "no certificate files found"
         return
      fi
   else
      _cbs=$_cert_bundle
   fi
   # shellcheck disable=SC2030,SC2086
   for _cb in $_cbs; do
      echo "---------------- ( $_cb ) ---------------------"
      awk '{
         if ($0 == "-----BEGIN CERTIFICATE-----") cert="";
         else if ($0 == "-----END CERTIFICATE-----") print cert;
         else cert=cert$0
      }' "$_cb" | \
         while read -r cert; do
            $_more && echo "---"
            echo "$cert" | \
               base64 --decode | \
                  openssl x509 -inform DER $_openssl_opts | \
                     awk '{
                        if ($1~/subject=/)
                           { gsub("subject=","  sub:",$0); print $0 }
                        else if ($1~/issuer=/)
                           { gsub("issuer=","isuer:",$0); print $0 }
                        else if ($1~/notBefore/)
                           { gsub("notBefore=","dates: ",$0); printf $0" -> " }
                        else if ($1~/notAfter/)
                           { gsub("notAfter=","",$0); print $0 }
                        else if ($1~/[0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z]/)
                           { print " hash: "$0 }
                        else
                           { print $0 }
                     }'
            _more=true
         done
      echo "---------------- ( $_cb ) ---------------------"
   done
}

function listcrts2 {
   # another way to list all info in a crt bundle
   # usage: listcrts2 FILE
   local _n_cert _c
   [ -z "$1" ] && echo "no cert file specified"
   for _c; do
      echo
      echo "Certificate: $_c"
      [ ! -f "$_c" ] && { echo " X - Certificate not found"; continue; }
      _n_cert=$(grep -hc "BEGIN CERTIFICATE" "$_c")
      [ "$_n_cert" -lt 1 ] && { echo " X - Not valid certificate"; continue; }
      for n in $(seq 1 "$_n_cert");do
         awk -v n="$n" '/BEGIN CERT/ { n -= 1;} n == 0 { print }' "$_c" | \
            openssl x509 -noout -text | sed -n \
               -e 's/^/ o - /' \
               -e 's/ *Signature Algorithm: / signature=/p' \
               -e 's/ *Not Before: / notBefore=/p' \
               -e 's/ *Not After *: / notAfter=/p' \
               -e 's/ *Issuer: / issuer=/p' \
               -e 's/ *Subject: / subject=/p' \
               -e '/Subject Public Key Info/q' | sort -r
         echo " -------------"
      done
   done
}

# shellcheck disable=SC2086,SC2139
function mkalias {
   # make an alias and add it to this file
   if [[ $1 && $2 ]]; then
      echo "alias $1=\"$2\"" >> "$HOME/$MAIN_BA_FILE"
      alias $1="$2"
   fi
}

# shellcheck disable=SC2009
function pag {
   # run ps and grep for a pattern
   ps auxfw | grep "$@"
}

function pbc {
   # enhance `pbcopy`
   if [ -n "$1" ]; then
      pbcopy < "$1"
   else
      eval "$(history -p \!\!)" | pbcopy
   fi
}

# shellcheck disable=SC2009
function peg {
   # run ps and grep for a pattern
   ps -ef | grep "$@"
}

function pl {
   # run a command and pipe it through `less`
   eval "$@" | less
}

function rc {
   # remember command - save the given command for later retreval
   local _COMMAND="$*"
   local _COMMANDS_FILE=$HOME/.commands.txt
   echo "$_COMMAND" >> "$_COMMANDS_FILE"
   sort "$_COMMANDS_FILE" > "$_COMMANDS_FILE.sorted"
   cp -f "$_COMMANDS_FILE.sorted" "$_COMMANDS_FILE"
   rm -f "$_COMMANDS_FILE.sorted"
   echo "added: '$_COMMAND'"
   echo "   to: $_COMMANDS_FILE"
}

function rf {
   # remember file - save the given file for later retreval
   _FILE="$*"
   _FILES_FILE=$HOME/.files.txt
   echo "$_FILE" >> "$_FILES_FILE"
   sort "$_FILES_FILE" > "$_FILES_FILE.sorted"
   cp -f "$_FILES_FILE.sorted" "$_FILES_FILE"
   rm -f "$_FILES_FILE.sorted"
   echo "added '$_FILE' to: $_FILES_FILE"
}

function s3e {
   # set s3cfg (s3tools.org) environment
   local _S3CFG_CFG="$HOME/.s3cfg/config"
   [ ! -e "$_S3CFG_CFG" ] && { echo "error: s3cfg config file does not exist: $_S3CFG_CFG"; return 1; }
   local _S3CFG_PROFILES
   _S3CFG_PROFILES=$(grep '^\[profile' "$_S3CFG_CFG" | awk '{print $2}' | tr -s ']\n' ' ')
   local _VALID_ARGS
   _VALID_ARGS=$(tr ' ' ':' <<< "${_S3CFG_PROFILES}unset")
   local _environment
   local _arg="$1"
   if [ -n "$_arg" ]; then
      if [[ ! $_VALID_ARGS =~ ^$_arg:|:$_arg:|:$_arg$ ]]; then
         echo -e "WTF? Try again... Only these profiles exist (or use 'unset'):\n   " "$_S3CFG_PROFILES"
         return 2
      fi
      if [ "$_arg" == "unset" ]; then
         unset S3CFG
         echo "s3cfg environment has been unset"
      else
         export S3CFG
         S3CFG=$(awk '$2~/'"$_arg"']/ {pfound="true"; next}; (pfound=="true" && $1~/config/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' "$_S3CFG_CFG")
         _environment=$(awk '$2~/'"$_arg"']/ {pfound="true"; next}; (pfound=="true" && $1~/environment/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' "$_S3CFG_CFG")
         echo "s3cfg environment has been set to --> $_environment ($S3CFG)"
         [ -z "$S3CFG" ] && unset S3CFG
      fi
   else
      echo -n "--- S3CFG Environment "
      [ -n "$S3CFG" ] && echo "Settings ---" || echo "(NOT set) ---"
      echo "S3CFG   = ${S3CFG:-N/A}"
   fi
}

function showf {
   # show a function defined in in this file
   ALIASES_FILE="$HOME/$MAIN_BA_FILE"
   if [[ $1 ]]; then
      if grep -q "^function $1 " "$ALIASES_FILE"; then
         sed -n '/^function '"$1"' /,/^}/p' "$ALIASES_FILE"
      else
         echo "function: '$1' - not found"
      fi
   else
      echo
      echo "which function do you want to see?"
      grep "^function .* " "$ALIASES_FILE" | awk '{print $2}' | cut -d'(' -f1 |  awk -v c=4 'BEGIN{print "\n\t--- Functions (use \`sf\` to show details) ---"}{if(NR%c){printf "  %-18s",$1}else{printf "  %-18s\n",$1}}END{print CR}'
      echo -ne "\nenter function: "
      read -r func
      echo
      showf "$func"
   fi
}

function soe {
   # set OpenStack (www.openstack.org) environment
   # (sets/sources OSRC to a config e.g. "$HOME/.openstack/os_rc.prod.sh")
   local _OS_CFG=$HOME/.openstack/config
   [ ! -e "$_OS_CFG" ] && { echo "error: openwtack config file does not exist: $_OS_CFG"; return 1; }
   local _OS_PROFILES
   _OS_PROFILES=$(grep '^\[profile' "$_OS_CFG" | awk '{print $2}' | tr -s ']\n' ' ')
   local _VALID_ARGS
   _VALID_ARGS=$(echo "${_OS_PROFILES}unset" | tr ' ' ':')
   local _environment
   local _arg="$1"
   if [ -n "$_arg" ]; then
      if [[ ! $_VALID_ARGS =~ ^$_arg:|:$_arg:|:$_arg$ ]]; then
         echo -e "WTF? Try again... Only these profiles exist (or use 'unset'):\n   " "$_OS_PROFILES"
         return 2
      fi
      if [ "$_arg" == "unset" ]; then
         unset OSRC
         echo "s3cfg environment has been unset"
      else
         export OSRC
         OSRC=$(awk '$2~/'"$_arg"']/ {pfound="true"; next}; (pfound=="true" && $1~/config/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' "$_OS_CFG")
         _environment=$(awk '$2~/'"$_arg"']/ {pfound="true"; next}; (pfound=="true" && $1~/environment/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' "$_OS_CFG")
         echo "s3cfg environment has been set to --> $_environment ($OSRC)"
         if [ -n "$OSRC" ]; then
            source "$OSRC"
         else
            unset OSRC
         fi
      fi
   else
      echo -n "--- OpenStack Environment "
      [ -n "$OSRC" ] && echo "Settings ---" || echo "(NOT set) ---"
      echo "OSRC   = ${OSRC:-N/A}"
   fi
}

function source_ssh_env {
   # source ~/.ssh/environment file for ssh-agent
   local _SSH_ENV="$HOME/.ssh/environment"
   if [ -f "$_SSH_ENV" ]; then
      source "$_SSH_ENV" > /dev/null
      # shellcheck disable=SC2009
      ps -u "$USER" | grep -q "$SSH_AGENT_PID.*ssh-agent$" || start_ssh_agent
   else
      start_ssh_agent
   fi
}

function _ssh {
   # ssh in to a server as user given and run optional command(s)
   # usage: _ssh <calling function> <user> <args>
   local _calling_function=$1
   local _user=$2
   shift 2
   local _USAGE="$_calling_function HOST [OPTIONS] [COMMANDS]"
   if [[ "$1" =~ ^- ]]; then
      echo "usage: $_USAGE"
      return
   fi
   if [ $# -gt 0 ]; then
      local _server=$1
      shift
      eval ssh "$_user@${_server}" "$@"
   else
      echo "usage: $_USAGE"
      return
   fi
}

function sse {
   # ssh in to a server as user "ec2-user" and run optional command(s)
   _ssh sse ec2-user "$@"
}

function ssu {
   # ssh in to a server as user "ubuntu" and run optional command(s)
   _ssh ssu ubuntu "$@"
}

function start_ssh_agent {
   # start ssh-add agent
   local _SSH_ENV="$HOME/.ssh/environment"
   echo -n "Initializing new SSH agent... "
   /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "$_SSH_ENV"
   echo "succeeded"
   chmod 600 "$_SSH_ENV"
   source "$_SSH_ENV" > /dev/null
   /usr/bin/ssh-add
}

function stopwatch {
   # display a "stopwatch"
   trap "return" SIGINT SIGTERM SIGHUP SIGQUIT
   trap 'echo; stty echoctl; trap - SIGINT SIGTERM SIGHUP SIGKILL SIGQUIT RETURN' RETURN
   stty -echoctl # don't echo "^C" when [Ctrl-C] is entered
   local _started _start_secs _current _current_secs _delta
   _started=$(date +'%d-%b-%Y %T')
   [ "$(uname)" != "Darwin" ] && _start_secs=$(date +%s -d "$_started") || _start_secs=$(date -jf '%d-%b-%Y %T' "$_started" +'%s')
   echo
   while true; do
      _current=$(date +'%d-%b-%Y %T')
      [ "$(uname)" != "Darwin" ] && _current_secs=$(date +%s -d "$_current") || _current_secs=$(date -jf '%d-%b-%Y %T' "$_current" +'%s')
      # TODO: almost works for Darwin, need to figure out proper delta
      [ "$(uname)" != "Darwin" ] && _delta=$(date +%T -d "0 $_current_secs secs - $_start_secs secs secs") || _delta=$(date -jf '%s' "0 $((_current_secs - _start_secs))" +'%T')
      echo -ne "  Start: ${GRN}$_started${NRM} - Finish: ${RED}$_current${NRM} Delta: ${YLW}$_delta${NRM}\r"
   done
}

function tb {
   # set xterm title to custom value
   echo -ne "\033]0; $* \007"
}

function tsend {
   # Send same command to all tmux panes
   tmux set-window-option synchronize-panes on
   tmux send-keys "$*" Enter
   tmux set-window-option synchronize-panes off
}

function vin {
   # vim certain files by tag (Notes should have a "tags: " line somewhere)

   local _NOTES_DIR="notes"
   local _NOTES_REPO="$HOME/repos/pataraco/$_NOTES_DIR"
   local _actual_note_file
   local _all_tags_found=()
   local _notes_tag=$1
   if [ -n "$_notes_tag" ]; then
      _actual_note_file=$(
         grep '^tags: ' "$_NOTES_REPO"/* |
         grep -iw "$_notes_tag" |
         cut -d':' -f1
      )
      if [ -n "$_actual_note_file" ]; then
         echo "found notes file to edit: $_actual_note_file"
         eval vim "$_actual_note_file"
      else
         echo "unknown tag ($_notes_tag) - not found - please try again..."
         # shellcheck disable=SC2207
         _all_tags_found=($(grep -i '^tags: ' "$_NOTES_REPO"/* | cut -d':' -f3 | sed 's/,//g' | sort))
         # read -r -a _all_tags_found <<< "$(grep -i '^tags: ' "$_NOTES_REPO"/* | cut -d':' -f3 | sed 's/,//g')"
         if [ -n "${_all_tags_found[0]}" ]; then
            echo
            echo "found these tags:"
            echo -e "\t${_all_tags_found[*]}"
         else
            echo "did not find ANY tags in the notes files in: $_NOTES_REPO"
         fi
         return 2
      fi
   else
      echo "you didn't specify a tag for a file to edit"
   fi
}

function wtc {
   # what's that command - retrieve the given command for use
   COMMAND_PATTERN="$*"
   COMMANDS_FILE=$HOME/.commands.txt
   grep --colour=always "$COMMAND_PATTERN" "$COMMANDS_FILE"
   while read -r _line; do
      history -s "$_line"
   done <<< "$(grep "$COMMAND_PATTERN" "$COMMANDS_FILE" | sed 's:\\:\\\\:g')"
}

function wtf {
   # what's that file - retrieve the given file for use
   # sets var $file to the last one found to use
   local _FILE_PATTERN="$*"
   local _FILES_FILE=$HOME/.files.txt
   grep --colour=always "$_FILE_PATTERN" "$_FILES_FILE"
   file=$(grep "$_FILE_PATTERN" "$_FILES_FILE" | tail -1)
}

function wutch {
   # like `watch` but colorful
   # couldn't get the trap to work
   #   just remove all "out" files - they'll get quickly replaced
   #trap "rm -f $_TMP_WUTCH_OUT; return" SIGINT SIGTERM SIGHUP SIGKILL SIGQUIT
   rm -f /tmp/.wutch.out.*
   local _TMP_WUTCH_OUT
   _TMP_WUTCH_OUT=$(mktemp /tmp/.wutch.out.XXX)
   local _secs
   [ "$1" == "-n" ] && { _secs=$2; shift 2; } || _secs=2
   local _cmd="$*"
   local _hcmd="${_cmd:0:35}..."
   clear
   while true; do
      /bin/bash -c "$_cmd" > "$_TMP_WUTCH_OUT"
      clear
      echo "Every ${_secs}.0s: $_hcmd: $(date)"
      echo "Command: '$_cmd'"
      echo "---"
      cat "$_TMP_WUTCH_OUT"
      tput ed
      sleep $_secs
   done
}

function xsse {
   # ssh in to a server in a seperate xterm window as user: "ec2-user"
   if [ -n "$1" ]; then
      local _server=$1
      $XTERM -e 'eval /usr/bin/ssh -q ec2-user@'"$_server"'' &
   else
      echo "USAGE: xsse HOST"
   fi
}

function xssh {
   # ssh in to a server in a seperate xterm window
   if [ -n "$1" ]; then
      local _server=$1
      $XTERM -e 'eval /usr/bin/ssh -q '"$_server"'' &
   else
      echo "USAGE: xssh HOST"
   fi
}

function y2j {
   # convert YAML to JSON (from either STDIN or by specifying a file
   if [ -n "$1" ]; then
      python -c 'import json, sys, yaml; [json.dump(f, sys.stdout, indent=4) for f in yaml.load_all(sys.stdin, Loader=yaml.FullLoader)]' < "$1" | jq .
   else
      python -c 'import json, sys, yaml; [json.dump(f, sys.stdout, indent=4) for f in yaml.load_all(sys.stdin, Loader=yaml.FullLoader)]' | jq .
   fi
}

function zipstuff {
   # zip up specified files for backup
   local _ZIP_FILE_NAME="$HOME/.$COMPANY.stuff.zip"
   local _CWD
   local _found_zip_files
   _CWD=$(pwd)
   local _FILES=(
      .*rc
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
   )
   # for some reason '*.zip' does not work to exclude all *.zip files
   # like other exclude patterns e.g. '*.sh' to exclude all *.sh files
   # have to specify each sub directory with an extra '*/'
   local _EXCLUDE_FILES=(
      *.DS_Store
      *.git*
      *.hg*
      *.terraform*
      *.zip
      scripts/*.zip
   )
   cd || return
   echo -e "\nziping these files/directories:"
   echo -en "\n   "
   # paste -sd ',' - <<< "$_FILES" | sed -E 's/(^, +|, +$)//g;s/, +/, /g'
   # shellcheck disable=SC2001
   echo "${_FILES[@]}" | sed 's/ /, /g'
   echo -e "\nexcluding these files/directories:"
   echo -en "\n   "
   # shellcheck disable=SC2001
   echo "${_EXCLUDE_FILES[@]}" | sed 's/ /, /g'
   # paste -sd ',' - <<< "$_EXCLUDE_FILES" | sed -E 's/(^, +|, +$)//g;s/, +/, /g'
   # shellcheck disable=SC2086
   if
      _found_zip_files=$(
         zip \
            --show-files -ru "$_ZIP_FILE_NAME" "${_FILES[@]}" \
            -x "${_EXCLUDE_FILES[@]}" |
         grep "\.zip$"
      )
   then
      echo -e "\n[warning] the following zip files would be added to the archieve"
      echo "$_found_zip_files"
      echo -e "\nplease add them to the 'exclude files' list!"
      echo "exiting"
      return
   else
      echo
      local _files
      local _exclude_files
      zip \
         --recurse-paths --update --encrypt \
         "$_ZIP_FILE_NAME" "${_FILES[@]}" \
         --exclude "${_EXCLUDE_FILES[@]}"
   fi
   echo "done - created file: '$_ZIP_FILE_NAME'"
   cd "$_CWD" || return
}

# -------------------- define aliases --------------------

alias ~="cd ~"
alias ..="cd .."
alias -- -="cd -"
alias a="alias | grep -v ^declare | cut -d= -f1 | sort | awk -v c=5 'BEGIN{print \"\n\t--- Aliases (use \`sa\` to show details) ---\"}{if(NR%c){printf \"  %-12s\",\$2}else{printf \"  %-12s\n\",\$2}}END{print CR}'"
alias c="clear"
alias cc="tsend clear"
alias cdh="cd ~; cd"
alias cd-ia="cd ~/repos/infrastructure-automation/exercises/auto_website"
alias cd-t="cd ~/repos/troposphere"
alias cols="tsend 'echo \$COLUMNS'"
alias cp='cp -i'
alias crt='~/scripts/chef_recipe_tree.sh'
#alias cssh='cssh -o "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"'
alias diff="colordiff -u"
alias disp="tsend 'echo \$DISPLAY'"
alias eaf="eval \"$(declare -F | sed -e 's/-f /-fx /')\""
alias egrep="egrep --color=auto"
alias egrpq="egrep --color=always"
alias f="grep '^function .* ' ~/$MAIN_BA_FILE | awk '{print $2}' | cut -d'(' -f1 | sort | awk -v c=4 'BEGIN{print \"\n\t--- Functions (use \`sf\` to show details) ---\"}{if(NR%c){printf \"  %-18s\",\$2}else{printf \"  %-18s\n\",\$2}}END{print CR}'"
alias fgrep="fgrep --color=auto"
alias fgrpa="fgrep --color=always"
alias fuck='echo "sudo $(history -p \!\!)"; sudo $(history -p \!\!)'
alias ghwb="sudo dmidecode | egrep -i 'date|bios'"
alias ghwm="sudo dmidecode | egrep -i '^memory device$|	size:.*B'"
alias ghwt='sudo dmidecode | grep "Product Name"'
alias grep="grep --color=auto"
alias grp="grep --color=auto --exclude-dir node_modules --exclude-dir .git --exclude-dir .terraform --exclude-dir .serverless"
alias grpa="grep --color=always"
alias guid='printf "%x\n" `date +%s`'
alias gxtf="grep --color=auto --exclude-dir .terraform"
alias h="history | tail -20"
alias kaj='eval kill $(jobs -p)'
alias kc='kubectl'
alias kca='kubectl api-resources'
alias kcc='kubectl config current-context'
alias kcs='kubectl -n kube-system'
alias kct='kubectl -n testing'
alias kcw='kubectl -o wide'
if [ "$(uname -s)" == "Darwin" ]; then
   alias l.='ls -dGh .*'
   alias la='ls -aGh'
   alias ll='ls -lGh'
   alias lla='ls -laGh'
   alias ls='ls -CFGh'
else
   alias l.='ls -dh .* --color=auto'
   alias la='ls -ah --color=auto'
   alias ll='ls -lh --color=auto'
   alias lla='ls -lah --color=auto'
   alias ls='ls -CFh --color=auto'
fi
alias less="less -FrX"
alias mv='mv -i'
alias myip='curl http://ipecho.net/plain; echo'
alias n='echo n'
alias pa='ps auxfw'
alias pbp='pbpaste'
alias pe='ps -ef'
alias pssav='PS_SHOW_AV=1'
alias psscv='PS_SHOW_CV=1'
alias psspv='PS_SHOW_PV=1'
alias pssallv='PS_SHOW_AV=1; PS_SHOW_CV=1; PS_SHOW_PV=1'
alias pshav='PS_SHOW_AV=0; unset PS_ANS'
alias pshcv='PS_SHOW_CV=0; unset PS_CHF'
alias pshpv='PS_SHOW_PV=0; unset PS_PY'
alias pshallv='PS_SHOW_AV=0; PS_SHOW_CV=0; PS_SHOW_PV=0; unset PS_ANS; unset PS_CHF; unset PS_PY'
alias ccrlf="sed -e 's/[[:cntrl:]]/\n/g' -i .orig"
alias rcrlf="sed -e 's/[[:cntrl:]]$//g' -i .orig"
alias ring="\$HOME/repos/pataraco/scripts/misc/ring.sh"
alias rmt="rancher-migration-tools"  # github.com/rancher/migration-tools
alias rsshk='ssh-keygen -f "$HOME/.ssh/known_hosts" -R'
alias rm='rm -i'
alias sa=alias
alias sba='source "$HOME/$MAIN_BA_FILE"'
alias sc="command -V"
alias sdl="export DISPLAY=localhost:10.0"
alias sf='showf'
alias shit='echo "sudo $(history -p \!\!)"; sudo $(history -p \!\!)'
alias sing="\$HOME/scripts/tools/sing.sh"
alias sts="grep '= CFNType' \$HOME/repos/stacker/stacker/blueprints/variables/types.py | awk '{print \$1}'"
alias sw='stopwatch'
#alias tt='echo -ne "\e]62;`whoami`@`hostname`\a"'  # change window title
alias ta='tmux attach -t'
alias tf11='/usr/local/bin/terraform.0.11'
alias tf12='/usr/local/bin/terraform.0.12'
alias tf13='/usr/local/bin/terraform.0.13'
alias tmx='tmux new-session -s Raco -n MYSHTUFF \; split-window -h \;  split-window -h \;  split-window -h \;  \; select-layout main-horizontal'
alias tspo='tmux set-window-option synchronize-panes on'
alias tspx='tmux set-window-option synchronize-panes off'
alias tt='echo -ne "\033]0;$(whoami)@$(hostname)\007"'
alias tskap="_tmux_send_keys_all_panes"
alias u='uptime'
alias ua='unalias'
alias vba='echo "editing: $HOME/$MAIN_BA_FILE"; vi "$HOME/$MAIN_BA_FILE"; sba'
# upgrade to neovim if available
[ "$(command -v nvim)" ] && VIM_CMD=$(command -v nvim) || VIM_CMD=$(command -v vim)
# shellcheck disable=SC2139
alias vi="$VIM_CMD"
alias vid="$VIM_CMD -d"
alias vidh="$VIM_CMD -do"
alias vidv="$VIM_CMD -dO"
alias view="$VIM_CMD -R"
alias vih="$VIM_CMD -o"
alias vihd="$VIM_CMD -do"
alias vim="$VIM_CMD"
alias vit="$VIM_CMD -p"
alias viv="$VIM_CMD -O"
alias vivd="$VIM_CMD -dO"
alias viw="$VIM_CMD -R"
# alias vms="set | egrep 'CLUST_(NEW|OLD)|HOSTS_(NEW|OLD)|BRNCH_(NEW|OLD)|ES_PD_TSD|SDELEGATE|DB_SCRIPT|VAULT_PWF|VPC_NAME'"
if command -v which &> /dev/null; then
   if [ "$(uname -s)" == "Darwin" ]; then
      alias which='(alias; declare -f) | which'
   elif [ "$(uname -so)" == "Linux Android" ]; then
      alias which='(alias; declare -f) | which --tty-only --read-alias --read-functions --show-tilde --show-dot'
   else
      alias which='(alias; declare -f) | which'
   fi
fi
alias wgft='echo "$(history -p \!\!) | grep"; $(history -p \!\!) | grep'
alias whoa='echo "$(history -p \!\!) | less"; $(history -p \!\!) | less -FrX'
alias xterm='xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000'
alias y='echo y'

# -------------------- final touches --------------------

# source AWS specific functions and aliases
[ -f "$AWS_SHIT" ] && source "$AWS_SHIT"

# source Chef/Knife specific functions and aliases
[ -f "$CHEF_SHIT" ] && source "$CHEF_SHIT"

# source company specific functions and aliases
[ -f "$COMPANY_SHIT" ] && source "$COMPANY_SHIT"

# set bash prompt command (and bash prompt)
export OLD_PROMPT_COMMAND=$PROMPT_COMMAND
export PROMPT_COMMAND="bash_prompt"

[ -n "$PS1" ] && echo -n "$MAIN_BA_FILE (end). "
