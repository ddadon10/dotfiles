" A .vimrc that works both with Vim and IntelliJ IDEA

" ----- Vim Behavior -----
filetype plugin indent on  " Enable filetype detection

set backspace=indent,eol,start  " Backspace in insert mode works like normal editor

syntax on  " Enable syntax highlighting

set fileformat=unix  " File format 

set splitbelow  " Horizontal splitting a window will put the new window below the current one

set splitright  " Vertical splitting a window will put the new window right of the current one

set omnifunc=syntaxcomplete#Complete  " Enable omni completion (IntelliSense like)

" Prevent vim from moving back one character after leaving insert mode
inoremap <silent> <Esc> <Esc>`^

" ----- Indentation -----
set autoindent  " Enable Auto indent

set shiftwidth=2  " Indent by 2 spaces when auto-indenting

set softtabstop=2  " Indent by 2 spaces when hitting tab

" ----- UI -----
colorscheme desert  " Good default colorscheme

set textwidth=79  " Max textwidth

set number  " Show line numbers

set showcmd  " Show cmd while typing

set showmode  " Show the current mode, like --INSERT--

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
set nohlsearch " Disable search highlighting

set incsearch  " incremental searching

set ignorecase  " Ignore case in search patterns

set smartcase  " Override the 'ignorecase' option if the search pattern contains upper case characters

" ----- Register config -----
" Put d/x/r into the black hole register
nnoremap d "_d
nnoremap x "_x
nnoremap r "_r

" ----- IDEAvim -----
if has('ide')
    " Inline comments are not supported, so each comment apply to the line below

    " -- Settings -- 
    set ideamarks " Sync IntellIJ bookmarks and Vim marks

    " -- GoTo keybinding --
    map gd <Action>(GotoDeclaration)
    map ge <Action>(GotoNextError)
    map gi <Action>(GotoImplementation)
    map gt <Action>(GotoTest)
    map gu <Action>(FindUsages)

    " -- Leader keybinding --

    " Attach
    map <leader>a <Action>(XDebugger.AttachToProcess)
    " deBug
    map <leader>b <Action>(Debug)
    map <leader>c <Action>(CommentByLineComment)
    map <leader>f <Action>(ReformatCode)
    map <leader>g <Action>(Generate)
    " searcH
    map <leader>h <Action>(Find)
    " Kill
    map <leader>k <Action>(Stop)
    " Line breakpoint
    map <leader>l <Action>(ToggleLineBreakpoint)
    " Next
    map <leader>n <Action>(Resume)
    map <leader>r <Action>(RenameElement)
    " Start
    map <leader>s <Action>(Run)
    " consTant 
    map <leader>t <Action>(IntroduceConstant)
    map <leader>v <Action>(IntroduceVariable)
    " evaluate eXpression
    map <leader>x <Action>(EvaluateExpression)
    map <leader><CR> <Action>(ShowIntentionActions)
    map <leader>C <Action>(CheckinProject)
    map <leader>L <Action>(Vcs.UpdateProject)
    map <leader>B <Action>(Git.Branches)
    map <leader>M <Action>(Annotate)
    
    " -- Other keybinding --
    " Replace vim back/forward with IntellIJ
    map <C-o> <Action>(Back)
    map <C-i> <Action>(Forward)
endif
