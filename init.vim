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

if !exists('g:vscode')
    set relativenumber " https://neovim.io/doc/user/options.html#'relativenumber'
    set number " https://neovim.io/doc/user/options.html#'number'
    set ignorecase " https://neovim.io/doc/user/options.html#'ignorecase'
    set smartcase  " https://neovim.io/doc/user/options.html#'smartcase'
    set noshowcmd " https://neovim.io/doc/user/options.html#'noshowcmd'
    set shortmess+=I " https://neovim.io/doc/user/options.html#shm-I
    set clipboard+=unnamed " https://neovim.io/doc/user/options.html#'clipboard'
    colorscheme sorbet " https://neovim.io/doc/user/syntax.html#%3Acolorscheme
    filetype plugin indent on " https://neovim.io/doc/user/options.html#'filetype'
    highlight EndOfBuffer ctermfg=bg ctermfg=bg " https://neovim.io/doc/user/syntax.html#hl-EndOfBuffer
endif

if exists('g:vscode')
    " Cursor Relative Actions
    nnoremap gd <Cmd>call VSCodeNotify('editor.action.revealDefinition')<CR>
    nnoremap gi <Cmd>call VSCodeNotify('editor.action.goToImplementation')<CR>
    nnoremap gp <Cmd>call VSCodeNotify('editor.action.peekDefinition')<CR>
    nnoremap gh <Cmd>call VSCodeNotify('editor.action.showHover')<CR>
    nnoremap gr <Cmd>call VSCodeNotify('editor.action.goToReferences')<CR>
    nnoremap gs <Cmd>call VSCodeNotify('typescript.goToSourceDefinition')<CR>
    nnoremap gt <Cmd>call VSCodeNotify('editor.action.goToTypeDefinition')<CR>

    " Leader Actions
    nnoremap <leader>b <Cmd>call VSCodeNotify('editor.action.toggleBreakpoint')<CR>
    nnoremap <leader>c <Cmd>call VSCodeNotify('editor.action.commentLine')<CR>
    nnoremap <leader>e <Cmd>call VSCodeNotify('editor.action.marker.next')<CR>
    nnoremap <leader>d <Cmd>call VSCodeNotify('workbench.action.debug.start')<CR>
    nnoremap <leader>f <Cmd>call VSCodeNotify('editor.action.formatDocument')<CR>
    nnoremap <leader>m <Cmd>call VSCodeNotify('gitlens.toggleFileBlame')<CR>
    nnoremap <leader>o <Cmd>call VSCodeNotify('editor.action.organizeImports')<CR>
    nnoremap <leader>r <Cmd>call VSCodeNotify('editor.action.rename')<CR>
    nnoremap <leader>t <Cmd>call VSCodeNotify('go.toggle.test.file')<CR> " Todo: Handle case when it's not a go file
    nnoremap <leader>r <Cmd>call VSCodeNotify('editor.action.refactor')<CR>

    nnoremap <leader><CR> <Cmd>call VSCodeNotify('editor.action.quickFix')<CR>
endif
