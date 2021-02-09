" A .vimrc without any plugins required

" ----- Vim Behavior -----
filetype plugin indent on  " Enable filetype detection

set backspace=indent,eol,start  " Backspace in insert mode works like normal editor

syntax on  " Enable syntax highlighting

set fileformat=unix  " File format 

set splitbelow  " Horizontal splitting a window will put the new window below the current one

set splitright  " Vertical splitting a window will put the new window right of the current one

set omnifunc=syntaxcomplete#Complete  " Enable omni completion (IntelliSense like)

" ----- Indentation -----
set autoindent  " Enable Auto indent

set shiftwidth=2  " Indent by 2 spaces when auto-indenting

set softtabstop=2  " Indent by 2 spaces when hitting tab

" ----- UI -----
colorscheme desert  " Good default colorscheme

set textwidth=79  " Max textwidth

set number  " Show line numbers

set showcmd  " Show cmd while typing

set noshowmode  " Do not show the mode, like --INSERT--, it wil be added back to the status line

" ----- Keys and shortcut config -----
" Remap shortcut to navigate between splited layouts easily
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" In insert or command mode, move by using Ctrl
inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>
cnoremap <C-h> <Left>
cnoremap <C-j> <Down>
cnoremap <C-k> <Up>
cnoremap <C-l> <Right>

" Remove Arrow key
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" Enable folding with spacebar
set foldmethod=indent
set foldlevel=99
nnoremap <space> za

" ----- Searching -----
set hlsearch  " highlighting of search matches

set incsearch  " incremental searching

set ignorecase  " Ignore case in search patterns

set smartcase  " Override the 'ignorecase' option if the search pattern contains upper case characters

nnoremap <CR> :nohlsearch<CR><CR>  " turn off search highlighting with <CR> (carriage-return)

" ----- Status line -----
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
