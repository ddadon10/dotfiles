" A .vimrc that works both with Vim and IntelliJ IDEA

" ----- Global -----
set relativenumber
set number
set ignorecase
set smartcase
set incsearch
set noshowcmd
set clipboard=unnamed

" In insert or command mode, move by using Ctrl
cnoremap <C-h> <Left>
cnoremap <C-j> <Down>
cnoremap <C-k> <Up>
cnoremap <C-l> <Right>
inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>

" Put d into the black hole register
nnoremap d "_d
xnoremap d "_d

" Put r into the black hole register
nnoremap r "_r
xnoremap r "_r

" Paste without yanking the deleted text
xnoremap p P

" Set cursor position at the end of the yanked text
vnoremap y myy`y

" Remap search
nnoremap s /
nnoremap S ?

" Move vertically with Space
nnoremap <Space> -

" ----- Vim -----
if !has('ide')
    colorscheme desert
    filetype plugin indent on
    syntax on
    set autoindent
    set backspace=indent,eol,start
    set fileformat=unix
    set foldlevel=99
    set foldmethod=indent
    set omnifunc=syntaxcomplete#Complete
    set shiftwidth=2
    set softtabstop=2
    set splitbelow
    set splitright
    set textwidth=120
endif

" ----- IDEAvim -----
if has('ide')
    " Settings
    set clipboard+=ideaput
    set idearefactormode=keep
    set ideajoin
    set textobj-indent
    set quickscope
    set surround

    " Quickscope
    let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
    let g:qs_primary_color = '#26F0F1'
    let g:qs_secondary_color = '#F00699'

    " Reject suggested code in insert mode.
    imap <S-Space> <Esc>a

    " Goto Actions
    map gd <Action>(GotoDeclaration)
    map ge <Action>(GotoNextError)
    map gi <Action>(GotoImplementation)
    map gs <Action>(GotoSuperMethod)
    map gt <Action>(GotoTypeDeclaration)
    map gT <Action>(GotoTest)
    map gu <Action>(GotoDeclaration)

    " VCS
    map <leader>C <Action>(CheckinProject)
    map <leader>B <Action>(Git.Branches)
    map <leader>M <Action>(Annotate)
    map <leader>L <Action>(Vcs.UpdateProject)

    " General Actions
    map <leader>d <Action>(Debug)
    map <leader>e <Action>(ShowErrorDescription)
    map <leader>c <Action>(CommentByLineComment)
    map <leader>f <Action>(ReformatCode)
    map <leader>j <Action>(QuickJavaDoc)
    map <leader>k <Action>(Stop)
    map <leader>l <Action>(ToggleLineBreakpoint)
    map <leader>n <Action>(Resume)
    map <leader>r <Action>(RenameElement)
    map <leader>s <Action>(Run)
    map <leader>u <Action>(HighlightUsagesInFile)
    map <leader>v <Action>(IntroduceVariable)
    map <leader>x <Action>(EvaluateExpression)
    map <leader><leader> <Action>(ShowPopupMenu)
    map <leader><CR> <Action>(ShowIntentionActions)
endif
