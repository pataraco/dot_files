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
Or you can use the setup.sh script to create links (but I doubt you'll do that).
The `setup.sh` script will:
0. Exit if not running on MacBook
1. Set date/time format in menu bar    # (edit the script and change to your desired format)
2. Set the login shell to '/bin/bash'  # (again, edit to your desired, e.g. '/bin/zsh'
3. Install Homebrew and the packages listed in the Brewfile (replace with your own)
4. Saves existing dot files to $HOME/.orig
5. Creates symlinks to all dot files found

In order to run it, you need to:
```
$ git --version  # if git not installed, should be prompted to install it
$ git clone https://github.com/pataraco/dot_files.git
$ vi setup.sh  # change path to repo, date/time format and login shell if desired
$ bash setup.sh
```

### "Show Aliases" and "Show Functions"
After sourcing the .bash_aliases file, you'll get these useful aliases:
* `a`  - (list) aliases
* `f`  - (list) functions
* `sa` - show alias
* `sf` - show function

## AWS CLI Functions
Check out the sweet AWS CLI functions (they begin with "aws") in `.bash_aliases_aws`
and can be listed/seen with the following aliases:
* `af`  - (list) AWS functions
* `saf` - show AWS function

## Have Fun!
hope someone picks up some tricks from these!

-Later!
