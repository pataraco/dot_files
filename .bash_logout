#!/usr/bin/env bash

# file: ~/.bash_logout: executed by bash(1) when login shell exits.

# shellcheck disable=SC1090,SC2034,SC2139,SC2142,SC1117

#[ -n "$PS1" ] && echo "sourcing: .bash_logout"
[ -n "$PS1" ] && echo -n ".bash_logout (begin)... "

# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

# write commands to history
history -a

[ -n "$PS1" ] && echo -n ".bash_logout (end). "
