" --- Neovim and VSCode Neovim config ---

set clipboard+=unnamed " https://neovim.io/doc/user/options.html#'clipboard'

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
    colorscheme sorbet " https://neovim.io/doc/user/syntax.html#%3Acolorscheme
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
endif
