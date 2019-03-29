" Minimal vimrc, no plugins required

" ----- Vim Behavior -----
" Backspace in insert mode works like normal editor
set backspace=indent,eol,start 

" Indent by 2 spaces when auto-indenting
set shiftwidth=2

" Indent by 2 spaces when hitting tab
set softtabstop=2

"Enable syntax highlighting
syntax on

" No show mode
set noshowmode

" Auto indenting
set autoindent

" Line numbers
set number

" Set 256 colors
set t_Co=256

" Split Layouts and Navigations
set splitbelow
set splitright

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Autocomplete
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" ----- Format the status line -----

" Git branch
function! GitBranch()
  return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
  let l:branchname = GitBranch()
  return strlen(l:branchname) > 0?'  ⎇  '.l:branchname.'':''
endfunction

"Display current Mode 
let g:currentmode={
    \ 'n'  : 'Normal ',
    \ 'no' : 'N·Operator Pending ',
    \ 'v'  : 'Visual ',
    \ 'V'  : 'Visual Line ',
    \ '' : 'Visual Block ',
    \ 's'  : 'Select ',
    \ 'S'  : 'Select Line ',
    \ '^S' : 'Select Block ',
    \ 'i'  : 'Insert ',
    \ 'R'  : 'Replace ',
    \ 'Rv' : 'Visual Replace ',
    \ 'c'  : 'Command ',
    \ 'cv' : 'Vim Ex ',
    \ 'ce' : 'Ex ',
    \ 'r'  : 'Prompt ',
    \ 'rm' : 'More ',
    \ 'r?' : 'Confirm ',
    \ '!'  : 'Shell ',
    \ 't'  : 'Terminal '
    \}


" Default (Normal) Mode Color
hi User1 ctermbg=2 ctermfg=16

"Git Color
hi User2 ctermbg=102 ctermfg=16

"Filename Color
hi User3 ctermbg=240 ctermfg=252

"Separation Color
hi User4 ctermbg=234 ctermfg=252

"Line Color
hi User5 ctermbg=251 ctermfg=232

set laststatus=2
set statusline=
set statusline+=%1*
set statusline+=\ %{toupper(g:currentmode[mode()])} 
set statusline+=%2*
set statusline+=%{StatuslineGit()}\ 
set statusline+=%3*
set statusline+=\ %f\ 
set statusline+=%4*
set statusline+=%=
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}\ 
set statusline+=\[%{&fileformat}\]\ 
set statusline+=%5*
set statusline+=\ %p%%
set statusline+=\ LN\ %l:%c
set statusline+=\ 

