set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" ----- Plugins -----

" Autocomplete
Plugin 'ajh17/VimCompletesMe'

" Syntax Checking/Highlighting
Plugin 'w0rp/ale'

" Autoformat
Plugin 'Chiel92/vim-autoformat'

" Nerd Tree
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'

" Airline
Plugin 'bling/vim-airline'

" Icons
Plugin 'ryanoasis/vim-devicons'

" Colors
Plugin 'morhetz/gruvbox'

" Python
"Plugin 'vim-scripts/indentpython'

" HTML/CSS 
Plugin 'mattn/emmet-vim'

" End Plugins and call Vundle

call vundle#end()            " required
filetype plugin indent on    " required


" ----- Keys and shortcut config -----

" Split Layouts and Navigations
set splitbelow
set splitright

" Remap shortcut to navigate between splited layouts easily
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


" Tab key config
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" Enable folding with spacebar
set foldmethod=indent
set foldlevel=99
nnoremap <space> za

" Remove Arrow key
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" ----- Vim Behavior -----

" Set Line Numbering
set nu

" Set Fonts 
" For console vim (nogui) directly change the font of your terminal
set encoding=utf-8
if has("gui_running")
  set guifont=DejaVuSansMono\ Nerd\ Font:h12
endif

" Set Colorscheme
set t_Co=256
set background=dark
colorscheme gruvbox

" Enable Syntax Highlighting
let python_highlight_all=1
syntax on

" Layout config
set textwidth=79
set autoindent

" Backspace configuration
set backspace=indent,eol,start

" File format config
set fileformat=unix


" Show cmd while typing
set showcmd

" Fix Bug background color on 256colors terminal
if &term =~ '256color'
    " Disable Background Color Erase (BCE) so that color schemes
    " work properly when Vim is used inside tmux and GNU screen.
    set t_ut=
endif


" -- Python --

" Flag bad whitespaces
highlight BadWhitespace ctermbg=red guibg=darkred
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/


" ----- Plugin Config -----

" Vim Airline
set laststatus=2
let g:airline_powerline_fonts = 1

" NerdTree
let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree
"au VimEnter *  NERDTree "Show NERDTree at start
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:DevIconsEnableFoldersOpenClose = 1

" Ale config
let g:airline#extensions#ale#enabled = 1
let g:ale_sign_column_always = 1
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'

"Autoformat config
noremap <F3> :Autoformat<CR>

" ----- Misc -----

" Things to do if needed:
" Virtualenv Support

" Plugin to install after experience on VIM:
" CtrlP ('kien/ctrlp.vim')
" Nerd Commenter ('https://github.com/scrooloose/nerdcommenter')
"
" Plugin to install when I will need git integration
" Git Fugitive ('tpope/vim-fugitive')
" Vim Gitgutter ('https://github.com/airblade/vim-gitgutter')
"
" Plugin to install if needed:
" Simpyl fold (Python) 'tmhedberg/SimpylFold'
