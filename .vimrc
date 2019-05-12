" vim: ft=vim:fdm=marker

" my vimrc
" --------
"  Steps to use neovim (nvim)
"  1. brew install neovim
"  3. mkdir ~/.vim
"  3. ln -l ~/.vimrc ~/.vim/init.vim
"  4. curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
"       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"  5. vim: PlugInstall
"  6. Color scheme downloads
"       ~/.config/nvim/colors
"       https://github.com/znake/znake-vim/blob/master/colors/znake.vim

" TODO {{{
" - add "long-line" automatic fixing
" - add automatic folding of vimrc (similar to .vim files)
" - add automatic folding of VARIABLES section in stacker blueprints
" - add switching of fold type marker when using <Leader>f
" - add rotating line numbering
" TODO }}}

" Settings {{{
" --------
 let g:highlighting = 0
"set cmdheight=2                " set height of status bar
 set ffs=unix                   " show ^M from DOS files
 " here's a plugin to try; set fold column only if/when folds exist
 "   https://github.com/benknoble/vim-auto-origami
 set foldcolumn=1               " set width of foldcolumn
 set foldlevel=0                " set foldlevel
 set formatoptions-=c           " stop auto commenting in general
 set formatoptions-=o           " stop auto commenting with 'o' or 'O'
 set formatoptions-=r           " stop auto commenting with [Enter]
 set hlsearch                   " Highlight searches by default
 set ignorecase                 " Ignore case when searching...
 set incsearch                  " Find the next match as we type the search
 set laststatus=2               " turn on the status bar (always)
                                " strings to use in 'list' mode (:set list!)
			        " use (:digraphs) to see a list of [ctrl-k] opts
"set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<,conceal:?,nbsp:_
 set listchars=eol:ϟ,tab:»·,trail:‥,extends:▷,precedes:◁,conceal:□,nbsp:ι
 set number                     " turn on line numbering
 set path+=**                   " turn on fuzzy file finding
 set relativenumber             " turn on relative line numbering
 set ruler                      " show line, column numbers on the status line
 set showcmd                    " show commands in status line
 set showmatch                  " flashes matching {}[]()
 set showmode                   " show command/edit mode in status line
 set smartcase                  " ...unless we type a capital
 set syntax=on                  " turn on syntax highlighting
 set wildmenu                   " enables a muenu at the bottom of the vim window
 set wildmode=list:longest,full " set up wild modes
" Settings }}}

" Key Mappings {{{
" ------------
" to see key mappings use `:map`
" one-liner to put & search `:redir @"|silent map|redir END|new|put!`
"
" scrolling
" <C-y> scrolls up and <C-e> scrolls down
" add <C-b> to scroll down
map <C-b> <C-E>
" split windows
" increase the height of the pane
map <C-u> <C-W>+
" reduce the height of the pane
map <C-i> <C-W>-
" increase the width of the pane
map <C-p> <C-W>>
" reduce the width of the pane
map <C-o> <C-W><
" move to left pane
map <C-h> <C-W>h
" move to down pane
map <C-j> <C-W>j
" move to up pane
map <C-k> <C-W>k
" move to right pane
map <C-l> <C-W>l
" preserve line: copy line & comment it out
map <C-c> yypkI# jB
" comment out the current line and move down 1
map <C-x> I# j
" comment out begining of current line and move down 1
map <C-n> 0i# j
" for vimdiff (vim -d) - set following 2 mappings to jump to prev/next diff
map ] ]c
map [ [c
" use 'du' to update diff after changes
map du :silent diffupdate<CR>
" turn line numbering on/off - instead: use <Leader>n (below)
"map <C-n> :set number!<CR>
" yank to end of line
map Y y$
" turn off search highlight
"nnoremap <silent> <space> :silent nohlsearch<CR>
"nnoremap <silent> <space> :nohlsearch<CR>
" set up shifting and un-shifting of current line in normal mode
nnoremap <Tab> >>_
nnoremap <S-Tab> <<_
" set up un-shifting of current line in insert mode
"inoremap <S-Tab> <C-D>
" set up shifting and un-shifting of current selection in visual mode
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv
" Key Mappings }}}

" Leader Mappings {{{
" ---------------
let mapleader      = ' '   " type this char first then additional defined below
let maplocalleader = '\'   " used for alternate context - certain file types
" Display the number of matches for the last search
nnoremap <silent> <Leader># :%s:<C-R>/::gn<cr>
" turn cursor highlighting on/off
nnoremap <silent> <Leader>x :silent set cursorline! \| set cursorcolumn!<CR>
nnoremap <silent> <Leader>l :silent set cursorline!<CR>
nnoremap <silent> <Leader>c :silent set cursorcolumn!<CR>
" turn line numbering on/off - see below (line numbering rotation function)
"nnoremap <silent> <Leader>n :silent set number!<CR>
" Press Space to turn off highlighting and clear any message already displayed.
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
" highlight extra white space (trailing whitespace and tabs)
nnoremap <silent> <Leader>w :match ExtraWhitespace /\s\+$\<Bar>\t/<CR>
nnoremap <silent> <Leader>W /\s\+$\<Bar>\t/<CR>
nnoremap <silent> <Leader>m :match<CR>
" highlight/search git merge conflicts
nnoremap <silent> <Leader>mc /<<<<<<<\<Bar>>>>>>>>\<Bar>=======<CR>
" highlight lines longer than 79 chars
nnoremap <silent> <Leader>L /\%>79v.\+<CR>
" paste from system clipbaard
nnoremap <silent> <Leader>p "+p<CR>
" change word to ALL CAPS
nnoremap <silent> <Leader>ac gUiw
" change word to all lowercase
nnoremap <silent> <Leader>al guiw
" redraw the screen
nnoremap <silent> <Leader>r :redraw!<CR>
" source (re-load) .vimrc
nnoremap <silent> <Leader>sv :source $MYVIMRC<CR>
" fold current block
nnoremap <silent> <Leader>f mf}zf'f<CR>
" sort current visually selected block
vnoremap <silent> <Leader>sb :sort<CR>
" Leader Mappings }}}

" Plug Ins {{{
" --------
" vim-plug plugin (https://github.com/junegunn/vim-plug)
" auto-install vim-plug plugin (https://github.com/junegunn/vim-plug)
"if empty(glob('~/.vim/autoload/plug.vim'))
"  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
"    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
"endif
" use vim-plug 
" 1. Begin the section with call plug#begin()
call plug#begin('~/.local/share/nvim/plugged')
" 2. List the plugins with Plug commands
" install: https://github.com/python-mode/python-mode
" python-mode didn't work 100%
" Plug 'python-mode/python-mode', { 'branch': 'develop' }
Plug 'neomake/neomake'
" https://github.com/scrooloose/nerdtree
Plug 'scrooloose/nerdtree'
nnoremap <silent> <Leader>nt :NERDTreeToggle<CR>
" https://github.com/tpope/vim-fugitive
Plug 'tpope/vim-fugitive'
" 3. call plug#end() to update &runtimepath and initialize plugin system
call plug#end()
" Plug Ins }}}

" Colorizations {{{
" -------------
" - Color Schemes -
"colorscheme Tomorrow-Night-Bright  " pretty good - has python
"colorscheme clearance  " not good - not working - doesn't look correct
"colorscheme dracula  " not bad
"colorscheme highwayman  " no thanks - has python - doesn't work
"colorscheme iceberg  " nice
"colorscheme jellybeans  " nope - has python
"colorscheme newproggie  " meh
"colorscheme VisualStudioDark  " pretty good
"colorscheme zellner  " ok
colorscheme znake  " pretty good - has python
" General Syntax highlighting
 hi Comment      cterm=none ctermfg=24  ctermbg=0  gui=italic guibg=fg guifg=bg
 hi Conditional  cterm=none ctermfg=69  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi Delimiter    cterm=none ctermfg=4   ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Error        cterm=none ctermfg=0   ctermbg=1  gui=none   guibg=fg guifg=bg
 hi Exception    cterm=none ctermfg=75  ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Function     cterm=none ctermfg=37  ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Include      cterm=none ctermfg=31  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi Keyword      cterm=none ctermfg=4   ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Number       cterm=none ctermfg=172 ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Operator     cterm=none ctermfg=30  ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Repeat       cterm=none ctermfg=31  ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Special      cterm=none ctermfg=172 ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Statement    cterm=none ctermfg=33  ctermbg=0  gui=none   guibg=fg guifg=bg
 hi String       cterm=none ctermfg=74  ctermbg=0  gui=none   guibg=fg guifg=bg
 hi Todo         cterm=none ctermfg=0   ctermbg=41 gui=none   guibg=fg guifg=bg
 hi Type         cterm=none ctermfg=69  ctermbg=0  gui=none   guibg=fg guifg=bg
" Bash Syntax highlighting
 hi shCasein            cterm=none ctermfg=69  ctermbg=0  gui=none guibg=fg guifg=bg
"hi shComment           cterm=none ctermfg=24  ctermbg=0  gui=italic guibg=fg guifg=bg
"hi shConditional       cterm=none ctermfg=69  ctermbg=0  gui=none guibg=fg guifg=bg
 hi shCtrlSeq           cterm=none ctermfg=172 ctermbg=0  gui=none guibg=fg guifg=bg "\n
 hi shEcho              cterm=none ctermfg=229 ctermbg=0  gui=none guibg=fg guifg=bg
 hi shFunction          cterm=none ctermfg=38  ctermbg=0  gui=none guibg=fg guifg=bg
 hi shIdentifier        cterm=none ctermfg=82  ctermbg=0  gui=none guibg=fg guifg=bg
 hi shQuote             cterm=none ctermfg=202 ctermbg=0  gui=none guibg=fg guifg=bg
"hi shSpecial           cterm=none ctermfg=172 ctermbg=0  gui=none guibg=fg guifg=bg "\n
 hi shStatement         cterm=none ctermfg=69  ctermbg=0  gui=none guibg=fg guifg=bg
 hi shString            cterm=none ctermfg=74  ctermbg=0  gui=none guibg=fg guifg=bg
"hi shTodo              cterm=none ctermfg=0   ctermbg=41 gui=none guibg=fg guifg=bg
" Python Syntax highlighting
"hi pythonAsync          cterm=none ctermfg=0   ctermbg=1  gui=none   guibg=fg guifg=bg  "async await
 hi pythonAttribute      cterm=none ctermfg=0   ctermbg=1  gui=none   guibg=fg guifg=bg
 hi pythonBuiltin        cterm=none ctermfg=30  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonComment        cterm=none ctermfg=24  ctermbg=0  gui=italic guibg=fg guifg=bg
"hi pythonConditional    cterm=none ctermfg=69  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonDecorator      cterm=none ctermfg=82  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonDecoratorName  cterm=none ctermfg=82  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonDoctest        cterm=none ctermfg=0   ctermbg=1  gui=none   guibg=fg guifg=bg ">>>
"hi pythonDoctestValue   cterm=none ctermfg=0   ctermbg=1  gui=none   guibg=fg guifg=bg
"hi pythonEscape         cterm=none ctermfg=172 ctermbg=0  gui=none   guibg=fg guifg=bg "\n
"hi pythonException      cterm=none ctermfg=75  ctermbg=0  gui=none   guibg=fg guifg=bg "finally raise except try
 hi pythonExceptions     cterm=none ctermfg=124 ctermbg=0  gui=none   guibg=fg guifg=bg "KeyError
"hi pythonFunction       cterm=none ctermfg=37  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonInclude        cterm=none ctermfg=31  ctermbg=0  gui=none   guibg=fg guifg=bg
 hi pythonMatrixMultiply cterm=none ctermfg=0   ctermbg=2  gui=none   guibg=fg guifg=bg
"hi pythonNumber         cterm=none ctermfg=172 ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonOperator       cterm=none ctermfg=30  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonRawString      cterm=none ctermfg=0   ctermbg=1  gui=none   guibg=fg guifg=bg
"hi pythonRepeat         cterm=none ctermfg=31  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonSpaceError     cterm=none ctermfg=0   ctermbg=1  gui=none   guibg=fg guifg=bg
"hi pythonStatement      cterm=none ctermfg=33  ctermbg=0  gui=none   guibg=fg guifg=bg
"hi pythonString         cterm=none ctermfg=74  ctermbg=0  gui=none   guibg=fg guifg=bg
 hi pythonSync           cterm=none ctermfg=0   ctermbg=1  gui=none   guibg=fg guifg=bg
 hi pythonTodo           cterm=none ctermfg=0   ctermbg=41 gui=none   guibg=fg guifg=bg
" YAML Syntax highlighting
hi yamlComment  cterm=none ctermfg=35  ctermbg=0   gui=none guibg=fg guifg=bg
hi yamlAnchor   cterm=none ctermfg=100 ctermbg=0   gui=none guibg=fg guifg=bg
hi yamlAlias    cterm=none ctermfg=100 ctermbg=0   gui=none guibg=fg guifg=bg
hi yamlTodo     cterm=none ctermfg=0   ctermbg=43  gui=none guibg=fg guifg=bg
" set highlight coloring for line numbering, cursor line/column and searching
hi LineNr       cterm=none ctermfg=36  ctermbg=0   gui=none guifg=bg guibg=fg
hi CursorLine   cterm=none ctermfg=0   ctermbg=36  gui=none guifg=bg guibg=fg
hi CursorColumn cterm=none ctermfg=0   ctermbg=36  gui=none guifg=bg guibg=fg
hi Search       cterm=none ctermfg=0   ctermbg=191 gui=none guifg=bg guibg=fg
hi Visual       cterm=none ctermfg=15  ctermbg=34  gui=none guifg=bg guibg=fg
" Fix the difficult-to-read default setting for diff text highlighting
hi DiffAdd      cterm=none ctermfg=48  ctermbg=29  gui=none guifg=bg guibg=fg
hi DiffDelete   cterm=none ctermfg=196 ctermbg=88  gui=none guifg=bg guibg=fg
hi DiffChange   cterm=none ctermfg=39  ctermbg=17  gui=none guifg=bg guibg=fg
hi DiffText     cterm=none ctermfg=17  ctermbg=39  gui=none guifg=bg guibg=fg
hi Folded       cterm=none ctermfg=39  ctermbg=17  gui=none guifg=bg guibg=fg
hi FoldColumn   cterm=none ctermfg=39  ctermbg=17  gui=none guifg=bg guibg=fg
" Set other specific colors
hi StatusLine   cterm=none ctermfg=15  ctermbg=22  gui=bold guifg=bg guibg=fg
hi StatusLineNC cterm=none ctermfg=15  ctermbg=52  gui=bold guifg=bg guibg=fg
hi VertSplit    cterm=none ctermfg=25  ctermbg=24  gui=none guifg=bg guibg=fg
hi MatchParen   cterm=none ctermfg=0   ctermbg=190 gui=none guifg=bg guibg=fg
" setting the following messes with schemes in nvim
"""""hi Normal       cterm=none ctermfg=grey ctermbg=black   gui=none guifg=bg guibg=fg
"hi Cursor       cterm=none ctermfg=black ctermbg=magenta gui=none guifg=bg guibg=fg
" Set the colors for extra white space
hi ExtraWhitespace cterm=none ctermfg=red ctermbg=red guifg=red guibg=red
" Show trailing whitepace and spaces before a tab
"autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\t/ containedin=ALL
" Show trailing whitepace and tabs (NOT WORKING)
"autocmd Syntax * syn match ExtraWhitespace /\s\+$\|\t/ containedin=ALL
" Highlight th 80th column
set colorcolumn=80          " set the column width
hi ColorColumn   cterm=none ctermfg=1 ctermbg=233  gui=none guifg=bg guibg=fg
" Colorizations }}}

" enable File type based auto indentation
filetype plugin indent on

" Functions {{{
" ---------

" HighlightCurrentWord() --- {{{2
" function to highlight the current word with [Enter]
function! HighlightCurrentWord () "
  if g:highlighting == 1 && @/ =~ '^\\<'.expand('<cword>').'\\>$'
    let g:highlighting = 0
    return ":silent nohlsearch\<CR>"
  endif
  let @/ = '\<'.expand('<cword>').'\>'
  let g:highlighting = 1
  return ":silent set hlsearch\<CR>"
endfunction
" map [Enter] <CR> to call HighlightCurrentWord function to highlight current word
nnoremap <silent> <expr> <CR> HighlightCurrentWord()
" HighlightCurrentWord() --- }}}2

" AlignAssignments()     --- {{{2
" function to align variable assignments in the current block
function! AlignAssignments ()
  " Patterns needed to locate assignment operators...
  let ASSIGN_OP   = '[-+*/%|&]\?=\@<!=[=~]\@!'
  let ASSIGN_LINE = '^\(.\{-}\)\s*\(' . ASSIGN_OP . '\)\(.*\)$'
  " Locate block of code to be considered (same indentation, no blanks)
  let indent_pat = '^' . matchstr(getline('.'), '^\s*') . '\S'
  let firstline  = search('^\%('. indent_pat . '\)\@!','bnW') + 1
  let lastline   = search('^\%('. indent_pat . '\)\@!', 'nW') - 1
  if lastline < 0
    let lastline = line('$')
  endif
  " Decompose lines at assignment operators...
  let lines = []
  for linetext in getline(firstline, lastline)
    let fields = matchlist(linetext, ASSIGN_LINE)
    call add(lines, fields[1:3])
  endfor
  " Determine maximal lengths of lvalue and operator...
  let op_lines = filter(copy(lines),'!empty(v:val)')
  let max_lval = max(map(copy(op_lines), 'strlen(v:val[0])')) + 1
  let max_op   = max(map(copy(op_lines), 'strlen(v:val[1])'))
  " Recompose lines with operators at the maximum length...
  let linenum = firstline
  for line in lines
    if !empty(line)
      let newline = printf("%-*s%*s%s", max_lval, line[0], max_op, line[1], line[2])
      call setline(linenum, newline)
    endif
    let linenum += 1
  endfor
endfunction
" map [Enter] <CR> to call HighlightCurrentWord function to highlight current word
nnoremap <silent> <Leader>aa :call AlignAssignments()<CR>
" AlignAssignments()     --- }}}2

" AddCompletion()        --- {{{2
" Table of completion specifications (a list of lists)...
let s:completions = []
" Function to add user-defined completions...
function! AddCompletion (left, right, completion, restore)
    call insert(s:completions, [a:left, a:right, a:completion, a:restore])
endfunction
let s:NONE = ""
" Table of completions...
"                  Left  Right   Complete with...      Restore
"                  ===== ======= ====================  =======
call AddCompletion('{',  s:NONE, "}",                     1   )
call AddCompletion('{',  '}',    "\<CR>\<C-D>\<ESC>O",    0   )
call AddCompletion('\[', s:NONE, "]",                     1   )
call AddCompletion('\[', '\]',   "\<CR>\<ESC>O\<TAB>",    0   )
call AddCompletion('(',  s:NONE, ")",                     1   )
call AddCompletion('(',  ')',    "\<CR>\<ESC>O\<TAB>",    0   )
call AddCompletion('<',  s:NONE, ">",                     1   )
call AddCompletion('<',  '>',    "\<CR>\<ESC>O\<TAB>",    0   )
call AddCompletion('"',  s:NONE, '"',                     1   )
call AddCompletion('"',  '"',    "\\n",                   1   )
call AddCompletion("'",  s:NONE, "'",                     1   )
call AddCompletion("'",  "'",    s:NONE,                  0   )
" AddCompletion()        --- }}}2

" SmartComplete()        --- {{{2
" Implement smart completion magic...
function! SmartComplete ()
    " Remember where we parked...
    let cursorpos = getpos('.')
    let cursorcol = cursorpos[2]
    let curr_line = getline('.')
    " Special subpattern to match only at cursor position...
    let curr_pos_pat = '\%' . cursorcol . 'c'
    " Tab as usual at the left margin...
    if curr_line =~ '^\s*' . curr_pos_pat
        return "\<TAB>"
    endif
    " How to restore the cursor position...
    let cursor_back = "\<C-O>:call setpos('.'," . string(cursorpos) . ")\<CR>"
    " If a matching smart completion has been specified, use that...
    for [left, right, completion, restore] in s:completions
        let pattern = left . curr_pos_pat . right
        if curr_line =~ pattern
            " Code around bug in setpos() when used at EOL...
            if cursorcol == strlen(curr_line)+1 && strlen(completion)==1 
                let cursor_back = "\<LEFT>"
            endif
            " Return the completion...
            return completion . (restore ? cursor_back : "")
        endif
    endfor
    " If no contextual match and after an identifier, do keyword completion...
    if curr_line =~ '\k' . curr_pos_pat
        return "\<C-N>"
    " Otherwise, just be a <TAB>...
    else
        return "\<TAB>"
    endif
endfunction
" Remap <TAB> for smart completion on various characters...
inoremap <silent> <TAB>   <C-R>=SmartComplete()<CR>
" SmartComplete()        --- }}}2

" MyFoldText()           --- {{{2
" change Folded text
set foldtext=MyFoldText()
"set foldtext=NeatFoldText()
"set foldtext=pymode#folding#text()
function! MyFoldText()
  " clear fold from fillchars to set it up the way we want later
  let &l:fillchars = substitute(&l:fillchars,',\?fold:.','','gi')
  let l:numwidth = (v:version < 701 ? 8 : &numberwidth)
  if &fdm=='diff'
    let l:linetext=''
    let l:foldtext='---------- '.(v:foldend-v:foldstart+1).' lines the same ----------'
    let l:align = winwidth(0)-&foldcolumn-(&nu ? Max(strlen(line('$'))+1, l:numwidth) : 0)
    let l:align = (l:align / 2) + (strlen(l:foldtext)/2)
    " note trailing space on next line
    setlocal fillchars+=fold:\ 
  elseif !exists('b:foldpat') || b:foldpat==0
    let l:foldtext = ' '.(v:foldend-v:foldstart).' lines folded '.v:folddashes.'|'
    let l:endofline = (&textwidth>0 ? &textwidth : 80)
    "let l:linetext = strpart(getline(v:foldstart),0,l:endofline-strlen(l:foldtext))
    let l:line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
    setlocal fillchars+=fold:-
    let l:foldchar = matchstr(&fillchars, 'fold:\zs.')
    let l:linetext = strpart('+' . repeat(l:foldchar, v:foldlevel) . l:line, 0, (winwidth(0)*2)/3)
    let l:align = l:endofline-strlen(l:linetext)
  elseif b:foldpat==1
    let l:align = winwidth(0)-&foldcolumn-(&nu ? Max(strlen(line('$'))+1, l:numwidth) : 0)
    let l:foldtext = ' '.v:folddashes
    let l:linetext = substitute(getline(v:foldstart),'\s\+$','','')
    let l:linetext .= ' ---'.(v:foldend-v:foldstart-1).' lines--- '
    let l:linetext .= substitute(getline(v:foldend),'^\s\+','','')
    let l:linetext = strpart(l:linetext,0,l:align-strlen(l:foldtext))
    let l:align -= strlen(l:linetext)
    setlocal fillchars+=fold:-
  endif
  return printf('%s%*s', l:linetext, l:align, l:foldtext)
endfunction

function! NeatFoldText()
 let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
 let lines_count = v:foldend - v:foldstart + 1
 let lines_count_text = '| ' . printf("%10s", lines_count . ' lines') . ' |'
 let foldchar = matchstr(&fillchars, 'fold:\zs.')
 let foldtextstart = strpart('+' . repeat(foldchar, v:foldlevel*2) . line, 0, (winwidth(0)*2)/3)
 let foldtextend = lines_count_text . repeat(foldchar, 8)
 let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
 return foldtextstart . repeat(foldchar, winwidth(0)-foldtextlength) . foldtextend
endfunction
" MyFoldText()           --- }}}2

" CycleNumbering()       --- {{{2
" Cycle through relativenumber + number, number (only), and no numbering.
function! CycleNumbering() abort
  if exists('+relativenumber')
    let l:nr = &number . &relativenumber
    execute {
          \ '00': 'set relativenumber   | set number',
          \ '01': 'set norelativenumber | set number',
          \ '10': 'set norelativenumber | set nonumber',
          \ '11': 'set norelativenumber | set number' }[l:nr]
  else
    " No relative numbering, just toggle numbers on and off.
    set number!<CR>
  endif
endfunction
" map <Leader>n to call CycleNumbering function
nnoremap <silent> <Leader>n :call CycleNumbering()<CR>
" CycleNumbering() --- }}}2

" Functions }}}

" Auto Commands {{{
" -------------
augroup myvimrchooks
    au!
    autocmd bufwritepost .vimrc source ~/.vimrc
    " more cross-platform compatible version
    "au BufWritePost .vimrc,_vimrc,vimrc,.gvimrc,_gvimrc,gvimrc so $MYVIMRC | if has('gui_running') | so $MYGVIMRC | endif
augroup END
" wrap long diffed lines
autocmd VimEnter * if &diff | execute 'windo set wrap' | endif
" set tab -> space conversions based on file types
autocmd FileType sh     set tabstop=3 | set shiftwidth=3 | set expandtab
autocmd FileType yaml   set tabstop=2 | set shiftwidth=2 | set expandtab
autocmd FileType python set tabstop=4 | set shiftwidth=4 | set expandtab
" Auto Commands }}}

" for neomake PlugIn (keep at the end of .vimrc
" ------------------
" When writing a buffer (no delay).
"call neomake#configure#automake('w')
" When writing a buffer (no delay), and on normal mode changes (after 750ms).
"call neomake#configure#automake('nw', 750)
" When reading a buffer (after 1s), and when writing (no delay).
"call neomake#configure#automake('rw', 1000)
" Full config: when writing or reading a buffer, and on changes in insert and
"   normal mode (after 2s; no delay when writing).
"call neomake#configure#automake('nrwi', 2000)
" Full config: when writing or reading a buffer and
"   normal mode (after 1/2s; no delay when writing).
call neomake#configure#automake('nrw', 500)

" set up the fold method to 'marker'
" XXXvimXXX: set fdm=marker fmr={{{,}}} fdl=0 fdc=1 :
" XXXvimXXX: set foldmethod=marker foldmarker={{{,}}} foldlevel=0 foldcolumn=1 :
