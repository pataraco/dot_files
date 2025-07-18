#!/usr/bin/env bash

# file: ~/.bash_profile: executed by the command interpreter for login shells.

# This file is sourced by bash(1) instead of .profile
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# shellcheck disable=SC1090,SC2034,SC2139,SC2142,SC1117

# CodeWhisperer pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/bash_profile.pre.bash" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/bash_profile.pre.bash"

# some ansi colorization escape sequences
[[ "$(uname)" == "Darwin" ]] && ESC="\033" || ESC="\e"
export GRN="${ESC}[32m"   # green FG
export RED="${ESC}[31m"   # red FG
export NRM="${ESC}[m"     # to make text normal

[[ -n "$PS1" ]] && echo -en "${GRN}.bash_profile${NRM} "

# set (uncomment) this to see the PATH getting built
# export PATH_DEBUG=true
[[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"

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

# set up Serverless Framework v4 license key from secure file
if [[ -f "$HOME/.ssh/.serverless_license" ]]; then
    export SERVERLESS_LICENSE_KEY="$(cat "$HOME/.ssh/.serverless_license")"
fi

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# set DISPLAY to forward X11
[[ -n "${SSH_CLIENT%% *}" ]] && export DISPLAY="${SSH_CLIENT%% *}:0.0"

# set PATH so it includes user's private bin if it exists
if [[ -d "$HOME/bin" ]] ; then
  [[ ! $PATH =~ $HOME/bin ]] && export PATH="$HOME/bin:$PATH" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"
fi

# add arcanist to PATH
arcanist_repo=$HOME/repos/phacility/arcanist
if [[ -d "$arcanist_repo" ]]; then
  export ARC_ROOT=$arcanist_repo
  arcanist_bin=$ARC_ROOT/bin
  [[ -d $arcanist_bin ]] && [[ ! $PATH =~ ^$arcanist_bin:|:$arcanist_bin:|:$arcanist_bin$ ]] && export PATH="$PATH:$arcanist_bin" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"
fi

# add Python 2.7 to PATH
# shouldn't need this with `pyenv`
## python27_bin="${HOME}/Library/Python/2.7/bin"
## [[ -d $python27_bin ]] && [[ ! $PATH =~ ^$python27_bin:|:$python27_bin:|:$python27_bin$ ]] && export PATH="$python27_bin:$PATH" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"

# add .local/bin to PATH
local_bin="${HOME}/.local/bin"
[[ -d $local_bin ]] && [[ ! $PATH =~ ^$local_bin:|:$local_bin:|:$local_bin$ ]] && export PATH="$local_bin:$PATH" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"

# add AWS ElasticBeanstalk CLI (eb) to path
eb_bin="${HOME}/.ebcli-virtual-env/executables"
[[ -d $eb_bin ]] && [[ ! $PATH =~ ^$eb_bin:|:$eb_bin:|:$eb_bin$ ]] && export PATH="$PATH:$eb_bin" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"

## add Ruby related info
# Should not need this stuff
# export PATH=$PATH:$HOME/.gem/ruby/1.9.1/bin:$HOME/.gem/ruby/2.2.0/bin
# export GEM_PATH=$HOME/.gem/ruby/1.9.1
# export GEM_HOME=$GEM_PATH

# this is to remove the nvm path from the PATH so that homebrew installation dirs are not first
nvm deactivate &> /dev/null

# set Homebrew environment and add brew installtion dirs to PATH
# (sets HOMEBREW_REPOSITORY, HOMEBREW_PREFIX, HOMEBREW_CELLAR)
eval "$(/opt/homebrew/bin/brew shellenv)" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"

# if running bash
if [[ -n "$BASH_VERSION" ]]; then
   # include .bashrc if it exists
   if [[ -f "$HOME/.bashrc" ]]; then
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

# Source SSH settings, if applicable

if [[ -f "$SSH_ENV" ]]; then
   source "$SSH_ENV" > /dev/null
   #ps -ef | grep "$SSH_AGENT_PID.*ssh-agent$" > /dev/null || start_ssh_agent
   # shellcheck disable=SC2009
   ps -u "$USER" | grep -q "$SSH_AGENT_PID.*ssh-agent$" || start_ssh_agent
else
    start_ssh_agent
fi

# enable bash completion (brew install bash-completion)
hb_bash_completion_script="$HOMEBREW_REPOSITORY/etc/profile.d/bash_completion.sh"
[[ -r "$hb_bash_completion_script" ]] && source "$hb_bash_completion_script"

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
## export NVM_SCRIPT="/opt/homebrew/opt/nvm/nvm.sh"
## export NVM_COMPLETION="/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
export NVM_SCRIPT="$HOMEBREW_REPOSITORY/opt/nvm/nvm.sh"
export NVM_COMPLETION="$HOMEBREW_REPOSITORY/opt/nvm/etc/bash_completion.d/nvm"
[[ -s "$NVM_SCRIPT" ]] && source "$NVM_SCRIPT"          # loads nvm
[[ -s "$NVM_COMPLETION" ]] && source "$NVM_COMPLETION"  # loads nvm CLI completion
## [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"                    # loads nvm
## [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"  # loads nvm bash_completion

# add (Homebrew) MySQL client to path
hb_mysql_clnt_bin="$HOMEBREW_REPOSITORY/opt/mysql-client/bin"
[[ -d $hb_mysql_clnt_bin ]] && [[ ! $PATH =~ ^$hb_mysql_clnt_bin:|:$hb_mysql_clnt_bin:|:$hb_mysql_clnt_bin$ ]] && export PATH="$PATH:$hb_mysql_clnt_bin" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"

# Enamble git CLI auto completion
export GIT_COMPLETION="$HOME/.git-completion.bash"
[[ -s "$GIT_COMPLETION" ]] && source "$GIT_COMPLETION"  # loads git CLI completion

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
## if [[ $? -eq 0 ]]; then
##     eval "$__conda_setup"
## else
##     if [[ -f "$HOME/opt/anaconda3/etc/profile.d/conda.sh" ]]; then
##         source "$HOME/opt/anaconda3/etc/profile.d/conda.sh"
##     else
##         export PATH="$HOME/opt/anaconda3/bin:$PATH"
##     fi
## fi
## unset __conda_setup
## # <<< conda initialize <<<

# added by Snowflake SnowSQL installer v1.2
snowsql_bin="/Applications/SnowSQL.app/Contents/MacOS"
if [[ -d "$snowsql_bin" ]]; then
  export PATH=$PATH:$snowsql_bin
  [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"
fi

# add $HOME/repos/pyenv/bin to beginning of PATH (if it exists)
pyenv_repo=$HOME/repos/pyenv
if [[ -d "$pyenv_repo" ]]; then
   export PYENV_ROOT=$pyenv_repo
   pyenv_bin=$PYENV_ROOT/bin
   [[ -d $pyenv_bin ]] && [[ ! $PATH =~ ^$pyenv_bin:|:$pyenv_bin:|:$pyenv_bin$ ]] && export PATH="$pyenv_bin:$PATH" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"
fi

# add `pyenv init` to shell to enable shims and autcompletion
# adds $HOME/.pyenv/shims to beginning of PATH
# OLD: command -v pyenv &> /dev/null && eval "$(pyenv init -)"
command -v pyenv &> /dev/null && eval "$(pyenv init --path)" && [[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"
# use `pipenv`
# # add `pyenv virtualenv-init` to shell to enable shims and autcompletion
# # adds pyenv-virtualenv shims to beginning of PATH
# [[ $(command -v pyenv) ]] && eval "$(pyenv virtualenv-init -)"

# remove duplicate entries in the PATH (both work - take your pick)
# PATH=$(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')
PATH=$(echo "$PATH" | awk -v RS=: -v ORS=: '!arr[$0]++' | sed 's/:$//')
[[ -n "$PATH_DEBUG" ]] && echo "(debug): PATH='$PATH'"

# set up "vi" command line editing
VIM_CMD=$(command -v nvim || command -v vim)
export EDITOR=$VIM_CMD
export VISUAL=$VIM_CMD

# CodeWhisperer post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/bash_profile.post.bash" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/bash_profile.post.bash"

# Output completion message
[[ -n "$PS1" ]] && echo -en "${RED}.bash_profile${NRM} "
