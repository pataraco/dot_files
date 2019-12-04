# dot_files
copy of my important dot files

including my .bash_aliases file(s) that have all my cool aliases and functions that make life easier

## Description
repo containing my important dot files

### partial list of files and purposes
* .aws_commands.txt
  * contains a list of AWS CLI commands used/abused
  * save an AWS CLI command to the list with the function: `rac()`
  * recall an AWS CLI command (and add to .bash_history) with the function: `wtac()`
* .commands.txt
  * contains a list of Bash commands used/abused
  * save a Bash command to the list with the function: `rc()`
  * recall a Bash command (and add to .bash_history) with the function: `wtc()`
* .files.txt
  * contains a list of Bash files used/abused
  * save a Bash file to the list with the function: `rf()`
  * recall a Bash file with the function: `wtf()`
* .bash_aliases
  * a bunch of cool aliases and functions that make life easier
  * sourced by .bashrc
* .bash_aliases_aws
  * a bunch of cool aliases and functions specific to AWS
  * sourced by .bash_aliases (enabled in .bash_profile)
  * list and show functions with: `af()` and `saf()`
* .bash_aliases_chef
  * a bunch of cool aliases and functions specific to Chef/Knife
  * sourced by .bash_aliases (enabled in .bash_profile)
  * list and show functions with: `cf()` and `scf()`
* .bash_aliases_{ag,ctcs,onica,r5s} (Company specific)
  * a bunch of cool aliases and functions specific to companies I've worked at
  * sourced by .bash_aliases (enabled in .bash_profile)
  * list and show functions with: `cof()` and `scof()`
* .bash_logout
  * sourced at logout
* .csshrc
  * my cssh config settings
* .tmux.conf
  * my tmux config settings and hacks
* .vimrc
  * my vim config settings and hacks
* .gitconfig
  * my git config settings, aliases and hacks

## Usage
Just place in your home directory
Or you can use the setup.sh script to create links (but I doubt you'll do that)

### "Show Aliases" and "Show Functions"
Here are some useful aliases:
* `a`  - list aliases
* `f`  - list functions
* `sa` - show alias
* `sf` - show function

## AWS CLI Functions
Check out the sweet AWS CLI functions (they begin with "aws") in `.bash_aliases_aws`

## Have Fun!
hope someone picks up some tricks from these!

-Later!
