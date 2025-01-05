" A .vimrc that works both with Vim and IntelliJ IDEA

" ----- Global -----
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

" Remap search to Space
nnoremap <Space> /
nnoremap <S-Space> ?

" Remap motions
nnoremap `] `>
nnoremap `[ `<

" Put d into the black hole register
nnoremap d "_d
xnoremap d "_d

" Put r into the black hole register
nnoremap r "_r
xnoremap r "_r

" Paste without yanking the deleted text
xnoremap p P

" ----- Vim -----
if !has('ide')
    colorscheme desert
    filetype plugin indent on
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
    syntax on
endif

" ----- IDEAvim -----
if has('ide')
    " Settings
    set idearefactormode=keep

    " Goto
    map gd <Action>(GotoDeclaration)
    map ge <Action>(GotoNextError)
    map gi <Action>(GotoImplementation)
    map gt <Action>(GotoTypeDeclaration)
    map gu <Action>(GotoDeclaration)
    map gz <Action>(GotoTest)

    " Command key
    noremap <D-l> <Right>
    cnoremap <D-l> <Right>
    inoremap <D-l> <Right>
    map <D-i> <Action>(CallInlineCompletionAction)
    cmap <D-i> <Action>(CallInlineCompletionAction)
    imap <D-i> <Action>(CallInlineCompletionAction)

    " Navigation
    map <leader>1 <Action>(ActivateProjectToolWindow)
    map <leader>2 <Action>(ActivateAIAssistantToolWindow)
    map <leader>3 <Action>(ActivateDebugToolWindow)
    map <leader>4 <Action>(ActivateProblemsViewToolWindow)
    map <leader>5 <Action>(ActivateTerminalToolWindow)

    " VCS
    map <leader>C <Action>(CheckinProject)
    map <leader>B <Action>(Git.Branches)
    map <leader>M <Action>(Annotate)
    map <leader>L <Action>(Vcs.UpdateProject)

    " General IDE Actions
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
    map <leader>v <Action>(IntroduceVariable)
    map <leader>x <Action>(EvaluateExpression)
    map <leader><CR> <Action>(ShowIntentionActions)

endif
