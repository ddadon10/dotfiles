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

set number  " Show the line number

set relativenumber " Show relative number

set showcmd  " Show cmd while typing

" ----- Keys and shortcut config -----
" Remap shortcut to navigate between splited layouts easily
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Remap j and k to + and - 
nnoremap j +
nnoremap k -

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

set noincsearch  " Disable incremental searching

set ignorecase  " Ignore case in search patterns

set smartcase  " Override the 'ignorecase' option if the search pattern contains upper case characters

" ----- Register config -----
" Put d/x/r into the black hole register
nnoremap d "_d
nnoremap x "_x
nnoremap r "_r

" ----- IDEAvim -----
if has('ide')
    " -- Settings -- 
    set ideamarks " Sync IntelliJ bookmarks and Vim marks
    set idearefactormode=keep
    
    " -- Emulated Vim Plugins --
    set ideajoin
    set surround

    " Standard Vim keybinding delegate to IntelliJ
    map [m <Action>(MethodUp)
    map ]m <Action>(MethodDown)
    map g; <Action>(JumpToLastChange)
    map g, <Action>(JumpToNextChange)

    " -- GoTo keybinding --
    map gd <Action>(GotoDeclaration)
    map ge <Action>(GotoNextError)
    map gi <Action>(GotoImplementation)
    map gt <Action>(GotoTypeDeclaration)
    map gT <Action>(GotoTest)
    " Go to usage and declaration are the same action in IntelliJ
    map gu <Action>(GotoDeclaration)
    
    " -- Leader keybinding --
    map <leader>b <Action>(ActivateDebugToolWindow)
    map <leader>c <Action>(CommentByLineComment)
    map <leader>d <Action>(Debug)
    map <leader>e <Action>(ShowErrorDescription)
    map <leader>f <Action>(ReformatCode)
    map <leader>g <Action>(Generate)
    map <leader>k <Action>(Stop)
    map <leader>l <Action>(ToggleLineBreakpoint)
    map <leader>n <Action>(Resume)
    map <leader>r <Action>(RenameElement)
    map <leader>s <Action>(Run)
    map <leader>t :set relativenumber!<CR>
    map <leader>v <Action>(IntroduceVariable)
    map <leader>x <Action>(EvaluateExpression)
    map <leader>C <Action>(CheckinProject)
    map <leader>L <Action>(Vcs.UpdateProject)
    map <leader>B <Action>(Git.Branches)
    map <leader>M <Action>(Annotate)
    map <leader>1 <Action>(ActivateProjectToolWindow)
    map <leader>2 <Action>(ActivateStructureToolWindow)
    map <leader>3 <Action>(ActivateCommitToolWindow)
    map <leader>4 <Action>(ActivateTerminalToolWindow)
    map <leader><CR> <Action>(ShowIntentionActions)
    map <leader><Space> <Action>(CodeCompletion)

    " -- Shortcut conflict config --
    sethandler <C-2> a:vim
    sethandler <C-S-2> a:vim
    sethandler <C-S-6> a:vim
    sethandler <C-A> a:vim
    sethandler <C-B> a:vim
    sethandler <C-D> a:vim
    sethandler <C-E> a:vim
    sethandler <C-F> a:vim
    sethandler <C-G> a:vim
    sethandler <C-H> a:vim
    sethandler <C-I> a:vim
    sethandler <C-J> a:vim
    sethandler <C-K> a:vim
    sethandler <C-L> a:vim
    sethandler <C-M> a:vim
    sethandler <C-N> a:vim
    sethandler <C-O> a:vim
    sethandler <C-P> a:vim
    sethandler <C-R> a:vim
    sethandler <C-S> a:vim
    sethandler <C-T> a:vim
    sethandler <C-V> a:vim
    sethandler <C-W> a:vim
endif
