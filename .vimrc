" my vimrc
" --------
let mapleader = " "		" type this char first then additional defined below
let maplocalleader = "\\"	" used for alternate context
set incsearch			" Find the next match as we type the search
set hlsearch			" Highlight searches by default
set ignorecase			" Ignore case when searching...
set smartcase			" ...unless we type a capital
set showmatch			" flashes matching {}[]()
set formatoptions-=c		" stop auto commenting in general
set formatoptions-=r		" stop auto commenting with [Enter]
set formatoptions-=o		" stop auto commenting with 'o' or 'O'
set ffs=unix			" show ^M from DOS files
" turn off search highlight
"nnoremap <silent> <space> :silent nohlsearch<CR>
"nnoremap <silent> <space> :nohlsearch<CR>
syntax on			" turn on syntax highlighting
" key mappings
" ------------
" to see key mappings use `:map`
" one-liner to put & search `:redir @"|silent map|redir END|new|put!`
"
" split windows
" increase the size of the pane
map <C-i> <C-W>+
" reduce the size of the pane
map <C-u> <C-W>-
" move to left pane
map <C-h> <C-W>h
" move to down pane
map <C-j> <C-W>j
" move to up pane 
map <C-k> <C-W>k
" move to right pane
map <C-l> <C-W>l
" preserve line: copy line & comment it out
map <C-c> yypkI#j
" comment out the current line and move down 1
map <C-x> I#j
" comment out begining of current line and move down 1
map <C-n> 0i# j
" for vimdiff (vim -d) - set following 2 mappings to jump to prev/next diff
map ] ]c
map [ [c
map du :silent diffupdate<CR>
" turn line numbering on/off
" use <Leader>n (below)
"map <C-n> :set number!<CR>
" set highlight coloring for line numbering, cursor line/column and searching
hi LineNr       cterm=none ctermfg=black ctermbg=cyan guifg=black guibg=yellow
hi CursorLine   cterm=none ctermfg=black ctermbg=cyan guifg=black guibg=yellow
hi CursorColumn cterm=none ctermfg=black ctermbg=cyan guifg=black guibg=yellow
hi Search       cterm=none ctermfg=black ctermbg=yellow guifg=black guibg=yellow
hi Visual       cterm=none ctermfg=black ctermbg=green  guifg=black guibg=green
" Fix the difficult-to-read default setting for diff text highlighting
hi DiffAdd      cterm=none ctermfg=lightgray ctermbg=blue gui=none guifg=bg guibg=fg
hi DiffDelete   cterm=none ctermfg=lightgray ctermbg=blue gui=none guifg=bg guibg=fg
hi DiffChange   cterm=none ctermfg=lightgray ctermbg=blue gui=none guifg=bg guibg=fg
hi DiffText     cterm=none ctermfg=lightgray ctermbg=red  gui=none guifg=bg guibg=fg
" Set other specific colors
hi StatusLine   cterm=bold ctermfg=black ctermbg=green gui=bold guifg=bg guibg=fg
hi StatusLineNC cterm=bold ctermfg=black ctermbg=red  gui=bold guifg=bg guibg=fg
hi VertSplit    cterm=none ctermfg=black ctermbg=cyan  gui=none guifg=bg guibg=fg
hi MatchParen   cterm=none ctermfg=black ctermbg=cyan  gui=none guifg=bg guibg=fg
hi Folded       cterm=none ctermfg=black ctermbg=cyan   gui=none guifg=bg guibg=fg
hi FoldColumn   cterm=none ctermfg=black ctermbg=cyan   gui=none guifg=bg guibg=fg
"hi Normal       cterm=none ctermfg=grey ctermbg=black   gui=none guifg=bg guibg=fg
"hi Cursor       cterm=none ctermfg=black ctermbg=magenta gui=none guifg=bg guibg=fg

" turn cursor highlighting on/off
nnoremap <silent> <Leader>x :silent set cursorline! \| set cursorcolumn!<CR>
nnoremap <silent> <Leader>l :silent set cursorline!<CR>
nnoremap <silent> <Leader>c :silent set cursorcolumn!<CR>
" turn line numbering on/off
nnoremap <silent> <Leader>n :silent set number!<CR>
" Press Space to turn off highlighting and clear any message already displayed.
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>
" yank to end of line
map Y y$
set laststatus=2
set ruler
" Display the number of matches for the last search
nmap <leader># :%s:<C-R>/::gn<cr>
set showmode
set showcmd
"set cmdheight=2
let g:highlighting = 0
" function to highlight the current word with [Enter]
function! Highlighting()
  if g:highlighting == 1 && @/ =~ '^\\<'.expand('<cword>').'\\>$'
    let g:highlighting = 0
    return ":silent nohlsearch\<CR>"
  endif
  let @/ = '\<'.expand('<cword>').'\>'
  let g:highlighting = 1
  return ":silent set hlsearch\<CR>"
endfunction
" map [Enter] <CR> to call Highlighting function to highlight current word
nnoremap <silent> <expr> <CR> Highlighting()
