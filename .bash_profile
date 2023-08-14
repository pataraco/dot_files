#!/usr/bin/env bash

# file: ~/.bash_profile: executed by the command interpreter for login shells.

# This file is sourced by bash(1) instead of .profile
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# shellcheck disable=SC1090,SC2034,SC2139,SC2142,SC1117

[ -n "$PS1" ] && echo -n ".bash_profile (begin)... "

# suppress "The default interactve shell is now zsh" warning
export BASH_SILENCE_DEPRECATION_WARNING=1

# set to use AWS related functions/aliases
export AWS_SHIT=$HOME/.bash_aliases_aws

# set to use Chef/Knife related functions/aliases
export CHEF_SHIT=$HOME/.bash_aliases_chef

# set company specific variable to create/use
# company specific functions/aliases
export COMPANY="innovyze"
export COMPANY_SHIT=$HOME/.bash_aliases_$COMPANY

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# set DISPLAY to forward X11
[ -n "${SSH_CLIENT%% *}" ] && export DISPLAY="${SSH_CLIENT%% *}:0.0"

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    [[ ! $PATH =~ $HOME/bin ]] && export PATH="$HOME/bin:$PATH"
fi

# add arcanist to PATH
arcanist_repo=$HOME/repos/phacility/arcanist
if [ -d "$arcanist_repo" ]; then
   export ARC_ROOT=$arcanist_repo
   arcanist_bin=$ARC_ROOT/bin
   [[ -d $arcanist_bin && ! $PATH =~ ^$arcanist_bin:|:$arcanist_bin:|:$arcanist_bin$ ]] && export PATH="$PATH:$arcanist_bin"
fi

# add Python 2.7 and .local/bin to PATH
python27_bin="${HOME}/Library/Python/2.7/bin"
[[ -d $python27_bin && ! $PATH =~ ^$python27_bin:|:$python27_bin:|:$python27_bin$ ]] && export PATH="$python27_bin:$PATH"
local_bin="${HOME}/.local/bin"
[[ -d $local_bin && ! $PATH =~ ^$local_bin:|:$local_bin:|:$local_bin$ ]] && export PATH="$local_bin:$PATH"

# add AWS ElasticBeanstalk CLI (eb) to path
eb_bin="${HOME}/.ebcli-virtual-env/executables"
[[ -d $eb_bin && ! $PATH =~ ^$eb_bin:|:$eb_bin:|:$eb_bin$ ]] && export PATH="$PATH:$eb_bin"

# add (Homebrew) MySQL client to path
hb_mysql_clnt_bin="/usr/local/opt/mysql-client/bin"
[[ -d $hb_mysql_clnt_bin && ! $PATH =~ ^$hb_mysql_clnt_bin:|:$hb_mysql_clnt_bin:|:$hb_mysql_clnt_bin$ ]] && export PATH="$PATH:$hb_mysql_clnt_bin"

# Should not need this stuff
## add Ruby related info
# export PATH=$PATH:$HOME/.gem/ruby/1.9.1/bin:$HOME/.gem/ruby/2.2.0/bin
# export GEM_PATH=$HOME/.gem/ruby/1.9.1
# export GEM_HOME=$GEM_PATH

# if running bash
if [ -n "$BASH_VERSION" ]; then
   # include .bashrc if it exists
   if [ -f "$HOME/.bashrc" ]; then
      source "$HOME/.bashrc"
   fi
fi

# set up some Ansible environment variable
# export ANSIBLE_HOME=$HOME/repos/cloud_automation/ansible
# export ANSIBLE_CONFIG=$HOME/repos/cloud_automation/ansible/inventory/ansible.cfg
# export ANSIBLE_LIBRARY=$HOME/repos/cloud_automation/ansible/library
# export ANSIBLE_HOME=$HOME/cloud_automation/ansible
# export ANSIBLE_CONFIG=$HOME/cloud_automation/ansible/inventory/ansible.cfg
# export ANSIBLE_LIBRARY=$HOME/cloud_automation/ansible/library

# set up VirtualEnv enviroment variables
export VIRTUAL_ENV_DISABLE_PROMPT=YES  # set to non-empty value to disable
# set up pip list column output formating
export PIP_FORMAT=columns
# set up "vi" command line editing
if command -v nvim &> /dev/null; then
   VIM_CMD=$(command -v nvim)
else
   VIM_CMD=$(command -v vim)
fi
export EDITOR=$VIM_CMD
export VISUAL=$VIM_CMD
# export MANPAGER="col -bx | vim -c 'set ft=man nolist nonu ' -MR -"
# export MANPAGER="col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -"
# use following for GNU
# export MANPAGER="sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -\""
# Less Colors for Man Pages
export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
#export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
export LESS_TERMCAP_md=$'\E[01;38;5;46m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'           # end mode
export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
#export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
#export LESS_TERMCAP_so=$'\E[38;5;196m'    # begin standout-mode - info box
export LESS_TERMCAP_so=$'\E[38;5;46;48;5;27m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'           # end underline
#export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline
export LESS_TERMCAP_us=$'\E[04;38;5;45m' # begin underline

# set up `ls` colors (see the man page)
export LSCOLORS=ExFxBxDxCxegedabagacad

# set up GIT pager
export GIT_PAGER='less -FrX'

## For ssh-agent
##  I also put this into my .bash_aliases so that I can
##  enter my passkey if/when I actually ssh to a host
SSH_ENV="$HOME/.ssh/environment"

function start_ssh_agent {
    echo "Initializing new SSH agent..."
    ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
    echo "succeeded"
    chmod 600 "$SSH_ENV"
    source "$SSH_ENV" > /dev/null
    /usr/bin/ssh-add
}

# enable bash completion (brew install bash-completion)
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] &&
   source "/usr/local/etc/profile.d/bash_completion.sh"

# Source SSH settings, if applicable

if [ -f "$SSH_ENV" ]; then
   source "$SSH_ENV" > /dev/null
   #ps -ef | grep "$SSH_AGENT_PID.*ssh-agent$" > /dev/null || start_ssh_agent
   # shellcheck disable=SC2009
   ps -u "$USER" | grep -q "$SSH_AGENT_PID.*ssh-agent$" || start_ssh_agent
else
    start_ssh_agent
fi

# Node Version Manager
# export NVM_SCRIPT="/usr/local/opt/nvm/nvm.sh"
# export NVM_COMPLETION="/usr/local/opt/nvm/etc/bash_completion.d/nvm"
# export NVM_SCRIPT="$HOMEBREW_REPOSITORY/opt/nvm/nvm.sh"
# export NVM_COMPLETION="$HOMEBREW_REPOSITORY/opt/nvm/etc/bash_completion.d/nvm"
# [ -s "$NVM_SCRIPT" ] && source "$NVM_SCRIPT"          # loads nvm
# [ -s "$NVM_COMPLETION" ] && source "$NVM_COMPLETION"  # loads nvm CLI completion
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"                    # loads nvm
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"  # loads nvm bash_completion

# Enamble git CLI auto completion
export GIT_COMPLETION="$HOME/.git-completion.bash"
[ -s "$GIT_COMPLETION" ] && source "$GIT_COMPLETION"  # loads git CLI completion

# Enamble AWS CLI auto completion
if command -v aws_completer &> /dev/null; then
   complete -C "$(command -v aws_completer)" aws
fi

# Enamble kubectl auto completion
if command -v kubectl &> /dev/null; then
   source <(kubectl completion bash)
fi

## # >>> conda initialize >>>
## # !! Contents within this block are managed by 'conda init' !!
## __conda_setup="$(''$HOME'/opt/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
## if [ $? -eq 0 ]; then
##     eval "$__conda_setup"
## else
##     if [ -f "$HOME/opt/anaconda3/etc/profile.d/conda.sh" ]; then
##         . "$HOME/opt/anaconda3/etc/profile.d/conda.sh"
##     else
##         export PATH="$HOME/opt/anaconda3/bin:$PATH"
##     fi
## fi
## unset __conda_setup
## # <<< conda initialize <<<

# added by Snowflake SnowSQL installer v1.2
export PATH=/Applications/SnowSQL.app/Contents/MacOS:$PATH

# add $HOME/repos/pyenv/bin to beginning of PATH (if it exists)
pyenv_repo=$HOME/repos/pyenv
if [ -d "$pyenv_repo" ]; then
   export PYENV_ROOT=$pyenv_repo
   pyenv_bin=$PYENV_ROOT/bin
   [[ -d $pyenv_bin && ! $PATH =~ ^$pyenv_bin:|:$pyenv_bin:|:$pyenv_bin$ ]] && export PATH="$pyenv_bin:$PATH"
fi

# add `pyenv init` to shell to enable shims and autcompletion
# adds $HOME/.pyenv/shims to beginning of PATH
# OLD: command -v pyenv &> /dev/null && eval "$(pyenv init -)"
command -v pyenv &> /dev/null && eval "$(pyenv init --path)"
# use `pipenv`
# # add `pyenv virtualenv-init` to shell to enable shims and autcompletion
# # adds pyenv-virtualenv shims to beginning of PATH
# [ $(command -v pyenv) ] && eval "$(pyenv virtualenv-init -)"

# remove duplicate entries in the PATH (both work - take your pick)
# PATH=$(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')
PATH=$(echo "$PATH" | awk -v RS=: -v ORS=: '!arr[$0]++' | sed 's/:$//')

# add brew installtion dirs to PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Output completion message
[ -n "$PS1" ] && echo -n ".bash_profile (end). "
