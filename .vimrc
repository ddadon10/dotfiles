" Thanks to https://github.com/RealPython for this amazing guide! : https://realpython.com/blog/python/vim-and-python-a-match-made-in-heaven/
" I have customized the .vimrc

set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

" Add all your plugins here (note older versions of Vundle used Bundle instead of Plugin)

" Code Styling
Plugin 'tmhedberg/SimpylFold'
Plugin 'vim-scripts/indentpython'

" Autocomplete
Plugin 'Valloric/YouCompleteMe'

" Syntax Checking/Highlighting
Plugin 'w0rp/ale'

" Nerd Tree
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'

" Airline
Plugin 'bling/vim-airline'

" Web/Fullstack
Plugin 'mattn/emmet-vim'

" Icons
Plugin 'ryanoasis/vim-devicons'

" Colors
Plugin 'morhetz/gruvbox'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required


" Split Layouts and Navigations
set splitbelow
set splitright

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


" Custom Syntax Checking/Highlighting
let python_highlight_all=1
syntax on

" Enable folding with spacebar
set foldmethod=indent
set foldlevel=99
nnoremap <space> za



" Tab config

set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" Python Config
au BufNewFile,BufRead *.py
    \ set textwidth=79 |
    \ set autoindent |
    \ set fileformat=unix |

    
" Flag bad whitespaces
highlight BadWhitespace ctermbg=red guibg=darkred
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

" Set Line Numbering
set nu

" Vim Airline
set laststatus=2
let g:airline_powerline_fonts = 1

" NerdTree
let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree
"au VimEnter *  NERDTree "Show NERDTree at start
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:DevIconsEnableFoldersOpenClose = 1


" YouCompleteMe
let g:ycm_show_diagnostics_ui = 0

" Ale config
let g:airline#extensions#ale#enabled = 1
let g:ale_sign_column_always = 1
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'


" Set Fonts 
set encoding=utf-8

" Set Colorscheme
set t_Co=256
set background=dark
colorscheme gruvbox

" Fix Bug background color on 256colors terminal

if &term =~ '256color'
    " Disable Background Color Erase (BCE) so that color schemes
    " work properly when Vim is used inside tmux and GNU screen.
    set t_ut=
endif


" Remove Arrow key
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" Things to do if needed:
" Virtualenv Support

" Plugin to install after experience on VIM:
" CtrlP ('kien/ctrlp.vim')
" Git Fugitive ('tpope/vim-fugitive')

