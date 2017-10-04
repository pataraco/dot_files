# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples


# If not running interactively, don't do anything
[ -z "$PS1" ] && return

echo "sourcing: .bashrc"

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL='ignoreboth:erasedups'

# don't record these commands
HISTIGNORE='ls:cd:h:..:history: *:sae:uname *:f:a:sa:sf:cd[aphir]:c:clear'

# append to the history file, don't overwrite it
shopt -s histappend

# TODO: this is NOT quite working correctly - must research and redo
# # share commands between sessions
# export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000		# how many lines to load in memory
HISTFILESIZE=50000	# how many lines to save in file

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    export COLOR_PROMPT=yes
    #PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]│\$ '
    case $KNIFETLA in
      dte|dtu|odt|rou)
         PS1='\[\033[01;36m\][$KNIFETLA]\[\033[00m\]${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;32m\]\W\[\033[00m\]│\[\033[01;36m\]\$\[\033[00m\] ' ;;
      pte|ptu)
         PS1='\[\033[01;33m\][$KNIFETLA]\[\033[00m\]${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;32m\]\W\[\033[00m\]│\[\033[01;33m\]\$\[\033[00m\] ' ;;
      pew|pue|puw|opa)
         PS1='\[\033[01;31m\][$KNIFETLA]\[\033[00m\]${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;32m\]\W\[\033[00m\]│\[\033[01;31m\]\$\[\033[00m\] ' ;;
      *)
         PS1='${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;32m\]\W\[\033[00m\]│\[\033[01;36m\]\$\[\033[00m\] ' ;;
    esac
    srvr_env=`hostname -f | cut -d. -f4`
    case $srvr_env in
      r5internal)
         PS1='${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\[\033[01;36m\]\h\[\033[00m\]:\[\033[01;32m\]\W\[\033[00m\]│\[\033[01;36m\]\$\[\033[00m\] ' ;;
      r5test)
         PS1='${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\[\033[01;33m\]\h\[\033[00m\]:\[\033[01;32m\]\W\[\033[00m\]│\[\033[01;33m\]\$\[\033[00m\] ' ;;
      r5external)
         PS1='${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\u@\[\033[01;31m\]\h\[\033[00m\]:\[\033[01;32m\]\W\[\033[00m\]│\[\033[01;31m\]\$\[\033[00m\] ' ;;
    esac
else
    #PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w│\$ '
    PS1='[$KNIFETLA]${debian_chroot:+($debian_chroot)}\u@\h:\W│\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \W\a\]$PS1"
    #PS1="[$KNIFETLA]\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

## # I put this stuff in .bash_profile
## export ANSIBLE_HOME=$HOME/repos/cloud_automation/ansible
## export ANSIBLE_CONFIG=$HOME/repos/cloud_automation/ansible/inventory/ansible.cfg
## export ANSIBLE_LIBRARY=$HOME/repos/cloud_automation/ansible/library
## export ARC_ROOT=$HOME/repos/phacility/arcanist
## [[ ! $PATH =~ $ARC_ROOT/bin ]] && export PATH="$PATH:$ARC_ROOT/bin"
## export PYENV_ROOT=$HOME/repos/pyenv
## [[ ! $PATH =~ $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
