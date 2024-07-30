" A .vimrc that works both with Vim and IntelliJ IDEA

" ----- Global Settings -----
set ignorecase 
set incsearch
set nohlsearch
set noshowcmd
set number
set smartcase

" In insert or command mode, move by using Ctrl
cnoremap <C-h> <Left>
cnoremap <C-j> <Down>
cnoremap <C-k> <Up>
cnoremap <C-l> <Right>
inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>

" Remove Arrow key
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>
noremap <Up> <NOP>

" Remap / and ? to s and S
nnoremap S ?
nnoremap s /

" Put d/x/r into the black hole register
nnoremap d "_d
nnoremap r "_r
vnoremap d "_d
vnoremap r "_r

" ----- Vim Settings -----
if !has('ide')
    colorscheme desert
    filetype plugin indent on  " Enable filetype detection
    inoremap <silent> <Esc> <Esc>`^ " Prevent vim from moving back one character after leaving insert mode
    set autoindent
    set backspace=indent,eol,start " Backspace in insert mode works like normal editor
    set fileformat=unix
    set foldlevel=99
    set foldmethod=indent
    set omnifunc=syntaxcomplete#Complete
    set shiftwidth=2 
    set softtabstop=2
    set splitbelow 
    set splitright
    set textwidth=120
    syntax on
endif

" ----- IDEAvim Settings -----
if has('ide')
    " -- Settings -- 
    set idearefactormode=keep

    " -- Keybinding --
    " Goto
    map gd <Action>(GotoDeclaration)
    map ge <Action>(GotoNextError)
    map gi <Action>(GotoImplementation)
    map gt <Action>(GotoTypeDeclaration)
    map gu <Action>(GotoDeclaration)
    map gz <Action>(GotoTest)
    " Navigation
    map <leader>1 <Action>(ActivateProjectToolWindow)
    map <leader>2 <Action>(ActivateStructureToolWindow)
    map <leader>3 <Action>(ActivateDebugToolWindow)
    map <leader>4 <Action>(ActivateTerminalToolWindow)
    " VCS
    map <leader>C <Action>(CheckinProject)
    map <leader>B <Action>(Git.Branches)
    map <leader>M <Action>(Annotate)
    map <leader>L <Action>(Vcs.UpdateProject)
    " General IDE Action
    map <leader>d <Action>(Debug)
    map <leader>e <Action>(ShowErrorDescription)
    map <leader>c <Action>(CommentByLineComment)
    map <leader>f <Action>(ReformatCode)
    map <leader>k <Action>(Stop)
    map <leader>l <Action>(ToggleLineBreakpoint)
    map <leader>n <Action>(Resume)
    map <leader>r <Action>(RenameElement)
    map <leader>s <Action>(Run)
    map <leader>v <Action>(IntroduceVariable)
    map <leader>x <Action>(EvaluateExpression)
    map <leader><CR> <Action>(ShowIntentionActions)
    map <leader><Space> <Action>(CodeCompletion)

    " -- Shortcut conflict config --
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
