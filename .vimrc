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
Plugin 'vim-airline/vim-airline-themes'

" Web/Fullstack
Plugin 'mattn/emmet-vim'

" Icons
Plugin 'ryanoasis/vim-devicons'

" Colors
Plugin 'jnurmine/Zenburn'
Plugin 'altercation/vim-colors-solarized'

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

" Custom Vim Airline

if has("gui_running")
    set laststatus=2
    let g:airline_powerline_fonts=1
    let g:airline_theme='solarized'
    let g:airline_solarized_bg='dark'
endif

" Custom Nerdtree
let NERDTreeIgnore=['\.pyc$', '\~$'] "ignore files in NERDTree
if has("gui_running")
    au VimEnter *  NERDTree "Show NERDTree at start
    let g:WebDevIconsUnicodeDecorateFolderNodes = 1
    let g:DevIconsEnableFoldersOpenClose = 1
endif


" Custom YouCompleteMe
let g:ycm_show_diagnostics_ui = 0

" Ale config
let g:airline#extensions#ale#enabled = 1
let g:ale_sign_column_always = 1
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'


" Set Fonts 
set encoding=utf-8
set guifont=DejaVuSansMono\ Nerd\ Font\ 12


" Set Flattened Colorscheme (http://ethanschoonover.com/solarized)
if has("gui_running")
    set background=dark
    colorscheme solarized
else
   colorscheme zenburn
endif

" Remove Menubar,Toolbar, Scrollbar and Mouse on Gvim
if has("gui_running")
    set guioptions-=m  "remove menu bar
    set guioptions-=T  "remove toolbar
    set guioptions-=r  "remove right-hand scroll bar
    set guioptions-=L  "remove left-hand scroll bar
    set mouse=c
endif



" Remove Arrow key
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>

" Remove hjkl
noremap h <NOP>
noremap j <NOP>
noremap k <NOP>
noremap l <NOP>


" Change backspace default behavior
set backspace=indent,eol,start

" Things to do if needed:
" Virtualenv Support

" Plugin to install after experience on VIM:
" CtrlP ('kien/ctrlp.vim')
" Git Fugitive ('tpope/vim-fugitive')

