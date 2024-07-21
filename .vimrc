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

set noshowcmd  " Don't show cmd while typing

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

" Remap / and ? to s and S
nnoremap s /
nnoremap S ?

" Folding
set foldmethod=indent
set foldlevel=99

" ----- Searching -----
set nohlsearch " Disable search highlighting

set incsearch  " Enable incremental searching

set ignorecase  " Ignore case in search patterns

set smartcase  " Override the 'ignorecase' option if the search pattern contains upper case characters

" ----- Register config -----
" Put d/x/r into the black hole register
nnoremap d "_d
nnoremap r "_r
vnoremap d "_d
vnoremap r "_r

" ----- IDEAvim -----
if has('ide')
    " -- Settings -- 
    set idearefactormode=keep

    " -- Keybinding --
    " Goto
    map ge <Action>(GotoNextError)
    map gd <Action>(GotoDeclaration)
    map gi <Action>(GotoImplementation)
    map gu <Action>(GotoDeclaration)
    map gt <Action>(GotoTypeDeclaration)
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
