" ============================================================================
" Plugin-less vimrc compatible with both Vim and IdeaVim
" ============================================================================
" This vimrc is designed to be completely self-contained without requiring
" any plugin managers or external dependencies. It works with Vim and
" JetBrains IdeaVim.
"
" Includes:
"   - A Vendored implementation of QuickScope (highlight-on-keypress for f/F/t/T motions)
"   - A Plugin-less Statusline
"
" Written as a legacy script for broader compatibility.
" Latest legacy script user manual can be found here: https://github.com/vim/vim/blob/v8.2.3951/runtime/doc/usr_41.txt
" ============================================================================

" ============================================================================
" QuickScope - Vendored Implementation
" ============================================================================
" This is a vendored, minimal implementation of the quick-scope plugin
" (https://github.com/unblevable/quick-scope) that provides highlight-on-keypress
" functionality for f/F/t/T motions.
"
" This implementation includes the following features:
"   - Highlights unique characters when pressing f/F/t/T
"   - Shows primary (first occurrence) and secondary (second occurrence) highlights
"   - Handles multibyte characters
"
" ============================================================================

" Configuration
let g:qs_enable = 1
let g:qs_max_line_length = 1000
let g:qs_highlight_priority = 1
let g:qs_cursor_priority = 2
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
let g:qs_accepted_chars = [
\ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o','p',
\ 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F',
\ 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
\ 'W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
\ ]

" Define highlight groups
augroup qs_colors
  autocmd!
  autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
  autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
  autocmd ColorScheme * highlight QuickScopeCursor gui=reverse cterm=reverse
augroup END

" QSUpdatePosition updates the index and character position
" Returns: [new_index, new_char_position]
function! s:QSUpdatePosition(i, c, char, is_forward) abort
  if a:is_forward
    return [a:i + 1, a:c + strlen(a:char)]
  else
    return [a:i - 1, a:c - strlen(a:char)]
  endif
endfunction

" QSShouldSetHighlight determines if a highlight should be set based on direction
" Forward: greedy (take first occurrence), Backward: reluctant (take last occurrence)
" Returns: true if highlight should be set
function! s:QSShouldSetHighlight(current_highlight, is_forward) abort
  if a:is_forward
    return a:current_highlight == 0
  else
    return v:true
  endif
endfunction

" QSAddToPattern adds highlight positions to pattern strings
" Returns: [updated_patt_p, updated_patt_s]
function! s:QSAddToPattern(is_first_word, hi_p, hi_s, patt_p, patt_s) abort
  if a:is_first_word
    return [a:patt_p, a:patt_s]
  endif

  if a:hi_p > 0
    return [printf('%s|%%%sc', a:patt_p, a:hi_p), a:patt_s]
  elseif a:hi_s > 0
    return [a:patt_p, printf('%s|%%%sc', a:patt_s, a:hi_s)]
  endif

  return [a:patt_p, a:patt_s]
endfunction

" QSGetPatterns finds which characters to highlight in a line
" Returns: [primary_pattern, secondary_pattern]
function! s:QSGetPatterns(line, cursor, end, targets) abort
  let occurrences = {}
  let [patt_p, patt_s] = ['', '']
  let is_first_word = v:true
  let is_first_char = v:true
  let [hi_p, hi_s] = [0, 0]
  let is_forward = a:cursor < a:end

  let c = 1
  let i = 0
  while c != a:cursor
    let char = matchstr(a:line, '.', byteidx(a:line, i))
    let c += len(char)
    let i += 1
  endwhile

  if !is_forward
    let c += len(matchstr(a:line, '.', byteidx(a:line, i))) - 1
  endif

  while (is_forward && c <= a:end || !is_forward && c >= a:end)
    let char = matchstr(a:line, '.', byteidx(a:line, i))
    let is_word_boundary = char !~# '\k' || empty(char)

    if is_first_char
      let is_first_char = v:false
      let [i, c] = s:QSUpdatePosition(i, c, char, is_forward)
      continue
    endif

    if is_word_boundary
      let [patt_p, patt_s] = s:QSAddToPattern(is_first_word, hi_p, hi_s, patt_p, patt_s)
      let [hi_p, hi_s] = [0, 0]  " Reset highlights for next word
      let is_first_word = v:false
      let [i, c] = s:QSUpdatePosition(i, c, char, is_forward)
      continue
    endif

    if index(a:targets, char) == -1
      let [i, c] = s:QSUpdatePosition(i, c, char, is_forward)
      continue
    endif

    let char_count = get(occurrences, char, 0) + 1
    let occurrences[char] = char_count

    if is_first_word
      let [i, c] = s:QSUpdatePosition(i, c, char, is_forward)
      continue
    endif


    let char_offset = is_forward ? 0 : len(char) - 1

    if char_count == v:count1 && s:QSShouldSetHighlight(hi_p, is_forward)
      let hi_p = c - char_offset
    elseif char_count == (v:count1 + 1) && s:QSShouldSetHighlight(hi_s, is_forward)
      let hi_s = c - char_offset
    endif

    let [i, c] = s:QSUpdatePosition(i, c, char, is_forward)
  endwhile

  let [patt_p, patt_s] = s:QSAddToPattern(is_first_word, hi_p, hi_s, patt_p, patt_s)

  return [patt_p, patt_s]
endfunction

" QSHighlightMatches highlights multiple column positions on a line
function! s:QSHighlightMatches(pattern, group_name, line_num) abort
  " Pattern structure: \v = very magic, %Nl = line N, (pat) = captured group
  " Example: \v%5l(%5c|%10c) matches columns 5 or 10 on line 5
  " See: https://vimhelp.org/pattern.txt.html#%2Fmagic

  let columns_pattern = a:pattern[1:]
  let match_pattern = printf('\v%%%dl(%s)', a:line_num, columns_pattern)
  call matchadd(a:group_name, match_pattern, g:qs_highlight_priority)
endfunction

" QSHighlight highlights characters on the current line
function! s:QSHighlight(motion, targets) abort
  if !g:qs_enable
    return
  endif

  let line = getline('.')
  if empty(line) || strlen(line) > g:qs_max_line_length
    return
  endif

  let line_num = line('.')
  let cursor_pos = col('.')
  let line_end = strlen(line)

  let is_forward = (a:motion ==# 'f' || a:motion ==# 't')

  if is_forward
    let [patt_p, patt_s] = s:QSGetPatterns(line, cursor_pos, line_end, a:targets)
  else
    let [patt_p, patt_s] = s:QSGetPatterns(line, cursor_pos, -1, a:targets)
  endif

  if !empty(patt_p)
    call s:QSHighlightMatches(patt_p, 'QuickScopePrimary', line_num)
  endif

  if !empty(patt_s)
    call s:QSHighlightMatches(patt_s, 'QuickScopeSecondary', line_num)
  endif
endfunction

" QSUnhighlight removes all QuickScope highlights
function! s:QSUnhighlight() abort
  for m in filter(getmatches(), 'v:val.group ==# "QuickScopePrimary" || v:val.group ==# "QuickScopeSecondary" || v:val.group ==# "QuickScopeCursor"')
    call matchdelete(m.id)
  endfor
endfunction

" QSStartHighlightMode prepares the environment for highlighting
" Returns: [cursor_match_id, saved_mapping]
function! s:QSStartHighlightMode() abort
  let cursor_match_id = matchadd('QuickScopeCursor', '\%#', g:qs_cursor_priority)

  " Save current <C-c> mapping and set to default
  let saved_mapping = maparg('<c-c>', 'n', 0, 1)
  nnoremap <silent> <c-c> <c-c>

  return [cursor_match_id, saved_mapping]
endfunction

" QSStopHighlightMode restores the environment after highlighting
function! s:QSStopHighlightMode(cursor_match_id, saved_mapping) abort
  call matchdelete(a:cursor_match_id)

  if empty(a:saved_mapping)
    nunmap <c-c>
  else
    call mapset('n', 0, a:saved_mapping)
  endif

  call s:QSUnhighlight()
endfunction

" QSGetTargetCharacter gets the target character from user input
" Returns: the target character
function! s:QSGetTargetCharacter() abort
  let char_code = getchar()
  " getchar() returns "\<S-lt>" for '<' instead of a number, handle this special case
  return char_code ==# "\<S-lt>" ? '<' : nr2char(char_code)
endfunction

" QSAim handles the main motion logic
" Returns: motion + target character
function! s:QSAim(motion) abort
  if !g:qs_enable
    return a:motion
  endif

  let [cursor_match_id, saved_mapping] = s:QSStartHighlightMode()

  call s:QSHighlight(a:motion, g:qs_accepted_chars)
  redraw

  let target = s:QSGetTargetCharacter()

  call s:QSStopHighlightMode(cursor_match_id, saved_mapping)

  return a:motion . target
endfunction

" QSSetupMappings creates the mappings
function! s:QSSetupMappings() abort
  for mode in ['n', 'x', 'o']
    for motion in g:qs_highlight_on_keys
      execute printf('%snoremap <expr> %s <SID>QSAim(''%s'')', mode, motion, motion)
    endfor
  endfor
endfunction

" ============================================================================
" Satusline
" ============================================================================

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

" ============================================================================
" Vim and IdeaVim Configuration
" ============================================================================
set clipboard+=unnamed " https://vimhelp.org/options.txt.html#clipboard-unnamed
set norelativenumber " https://vimhelp.org/options.txt.html#%27relativenumber%27
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

" Scrolling
nnoremap J <C-e>
nnoremap K <C-y>
nnoremap D <C-d>
nnoremap U <C-u>

" ============================================================================
" Vim Only Configuration
" ============================================================================

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
    packadd comment " https://vimhelp.org/usr_05.txt.html#comment-install
    call s:SetupStatusline()
    call s:QSSetupMappings()
endif

" ============================================================================
" IdeaVim Only Configuration
" ============================================================================

if has('ide')
    " Settings
    set clipboard+=ideaput
    set idearefactormode=keep
    set ideajoin
    set textobj-indent
    set quickscope
    set surround

    " Navigation & Jumps
    map <D-o> <C-o>
    map <D-i> <C-i>
    map <D-d> <C-d>
    map <D-u> <C-u>
    map <D-b> <C-b>
    map <D-e> <C-e>
    map <D-y> <C-y>

    " Editing
    map <D-r> <C-r>
    map <D-n> <C-n>
    map <D-p> <C-p>

    " Quickscope
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
