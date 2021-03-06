" A .vimrc without any plugins required without any plugins required

" ----- Vim Behavior -----
filetype plugin indent on  " Enable filetype detection

set backspace=indent,eol,start  " Backspace in insert mode works like normal editor

syntax on  " Enable syntax highlighting

set fileformat=unix  " File format 

set splitbelow  " Horizontal splitting a window will put the new window below the current one

set splitright  " Vertical splitting a window will put the new window right of the current one

set omnifunc=syntaxcomplete#Complete  " Enable omni completion (IntelliSense like)

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
set hlsearch  " highlighting of search matches

set incsearch  " incremental searching

set ignorecase  " Ignore case in search patterns

set smartcase  " Override the 'ignorecase' option if the search pattern contains upper case characters

nnoremap <CR> :nohlsearch<CR><CR>

" ----- Register config -----
" Put d/x/r into the black hole register
nnoremap d "_d
nnoremap x "_x
nnoremap r "_r
" ----- IDEAvim -----
map <leader>9 <Action>(Resume)
map <leader>0 <Action>(Run)
map <leader>) <Action>(RunClass)
map <leader>- <Action>(Debug)
map <leader>_ <Action>(DebugClass)
map <leader>= <Action>(Stop)

map <leader>P <Action>(ActivateProjectToolWindow)
map <leader>S <Action>(ActivateStructureToolWindow)
map <leader>R <Action>(ActivateRunToolWindow)
map <leader>D <Action>(ActivateDebugToolWindow)
map <leader>T <Action>(ActivateTerminalToolWindow)

map <leader>a <Action>(GotoAction)
map <leader>b <Action>(ToggleLineBreakpoint)
map <leader>c <Action>(CommentByLineComment)
map <leader>d <Action>(GotoDeclaration)
map <leader>e <Action>(GotoNextError)
map <leader>f <Action>(ReformatCode)
map <leader>g <Action>(Generate)
map <leader>j <Action>(QuickJavaDoc)
map <leader>i <Action>(GotoImplementation)
map <leader>n <Action>(CloseAllNotifications)
map <leader>r <Action>(RenameElement)
map <leader>t <Action>(GotoTest)
map <leader>u <Action>(FindUsages)
map <leader>x <Action>(EvaluateExpression)
map <leader><CR> <Action>(ShowIntentionActions)

map <leader>C <Action>(CheckinProject)
map <leader>L <Action>(Vcs.UpdateProject)
map <leader>B <Action>(Git.Branches)
map <leader>M <Action>(Annotate)

map <C-CR> <Action>(EditorCompleteStatement)
imap <C-CR> <c-o><C-CR>

" Additonal Settings To add to .ideavimrc that
" set ideamarks " Sync IntellIJ bookmarks and Vim marks
