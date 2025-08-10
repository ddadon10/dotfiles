" A .vimrc that works both with Vim and IdeaVim
" For compatibility reason, this is a "legacy" script.
" Latest legacy script user manual can be found here: https://github.com/vim/vim/blob/v8.2.3951/runtime/doc/usr_41.txt

" --- Vim and IdeaVim ---
set clipboard+=unnamed " https://vimhelp.org/options.txt.html#clipboard-unnamed
set relativenumber " https://vimhelp.org/options.txt.html#%27relativenumber%27
set number " https://vimhelp.org/options.txt.html#%27number%27
set ignorecase " https://vimhelp.org/options.txt.html#%27ignorecase%27
set incsearch " https://vimhelp.org/options.txt.html#%27incsearch%27
set smartcase  " https://vimhelp.org/options.txt.html#%27smartcase%27
set noshowcmd " https://vimhelp.org/options.txt.html#%27noshowcmd%27
set fileformats=unix,dos " https://vimhelp.org/options.txt.html#%27fileformats%27

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

let g:statusline_mode_map = {
    \ 'n': 'NORMAL',
    \ 'i': 'INSERT',
    \ 'v': 'VISUAL',
    \ 'V': 'V-LINE',
    \ "\<C-v>": 'V-BLOCK',
    \ 'c': 'COMMAND',
    \ 'R': 'REPLACE',
    \ 's': 'SELECT',
    \ 'S': 'S-LINE',
    \ "\<C-s>": 'S-BLOCK',
    \ 't': 'TERM'
    \ }

" Setup the statusline
" See: https://vimhelp.org/options.txt.html#%27statusline%27
function! s:SetupStatusline()
    " Clear any existing statusline
    set statusline=

    " Left side
    set statusline+=%F " Full path to the file in the buffer
    set statusline+=%m " Modified flag
    set statusline+=%r " Readonly flag

    " Separator
    set statusline+=\ │

    set statusline+=\ %y " Type of file in the buffer
    set statusline+=\ [%{&fileencoding}] " Character encoding
    set statusline+=\ [%{&fileformat}] " File Format
    set statusline+=\ [%{&expandtab?'spaces:'..&shiftwidth:'tabs:'..&tabstop}] " Spaces vs Tabs

    " Right side
    set statusline+=%= " Separation point between alignment sections

    " Separator
    set statusline+=\ │

    " Character info section
    set statusline+=\ %{&fileencoding=='utf-8'?'U+':''}%04B " Value of character under cursor, in hexadecimal
    set statusline+=\ %03b " Value of character under cursor, in decimal

    " Separator
    set statusline+=\ │

    " Position info section
    set statusline+=\ Ln:%04l/%04L " Line number / Number of lines in buffer
    set statusline+=\ Col:%03c " Column number (byte index)

    " Separator
    set statusline+=\ │

    " Mode
    set statusline+=\ %{printf('%-8s',get(g:statusline_mode_map,mode(),mode()))} " Mode name
endfunction


" --- Vim ---
if !has('ide')
    if has('autocmd')
        autocmd InsertEnter,InsertLeave,CmdlineEnter,CmdlineLeave * redrawstatus!
    endif
    set shortmess+=I " https://vimhelp.org/options.txt.html#%27shortmess%27
    set laststatus=2 " https://vimhelp.org/options.txt.html#%27laststatus%27
    set noshowmode " https://vimhelp.org/options.txt.html#%27noshowmode%27
    set ttimeoutlen=100 " https://vimhelp.org/options.txt.html#%27ttimeoutlen%27
    colorscheme sorbet " https://vimhelp.org/syntax.txt.html#%3Acolorscheme
    syntax enable " https://vimhelp.org/syntax.txt.html#%3Asyn-on
    filetype plugin indent on " https://vimhelp.org/filetype.txt.html#%3Afiletype-overview
    highlight EndOfBuffer ctermfg=bg ctermfg=bg " https://vimhelp.org/syntax.txt.html#highlight-groups
    call s:SetupStatusline()
endif

" --- IdeaVim ---
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
    map <leader>h <Action>(ShowHoverInfo)
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
