-- Options
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'
vim.g.qs_highlight_on_keys = { 'f', 'F', 't', 'T' }
vim.o.breakindent = true
vim.o.completeitemalign = 'kind,abbr,menu'
vim.o.completeopt = 'menu,menuone,noinsert,fuzzy'
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.fillchars = 'eob: '
vim.o.foldenable = false
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:block'
vim.o.ignorecase = true
vim.o.laststatus = 3
vim.o.linebreak = true
vim.o.mouse = 'a'
vim.o.mousescroll = 'ver:1,hor:0'
vim.o.number = true
vim.o.pumheight = 10
vim.o.ruler = false
vim.o.shiftwidth = 4
vim.o.showcmd = false
vim.o.showmode = false
vim.o.signcolumn = 'yes:1'
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.splitbelow = true
vim.o.splitkeep = 'screen'
vim.o.splitright = true
vim.o.tabstop = 4
vim.o.wrap = true

vim.opt.shortmess:append('IscWa')

-- Plugins
vim.pack.add({
    'https://github.com/ellisonleao/gruvbox.nvim',
    'https://github.com/ibhagwan/fzf-lua',
    'https://github.com/lewis6991/gitsigns.nvim',
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/mfussenegger/nvim-jdtls',
    'https://github.com/nvim-mini/mini.nvim',
    'https://github.com/nvim-tree/nvim-tree.lua',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/stevearc/aerial.nvim',
    'https://github.com/stevearc/quicker.nvim',
    'https://github.com/unblevable/quick-scope',
}, {
    confirm = false,
})

-- Colorscheme
vim.api.nvim_create_autocmd('ColorSchemePre', {
    group = vim.api.nvim_create_augroup('ConfigColorscheme', { clear = true }),
    pattern = 'gruvbox',
    callback = function()
        local pal = require('gruvbox').palette
        local bg = vim.o.background
        local fg = bg == 'dark' and 'light' or 'dark'
        local accent = bg == 'dark' and 'bright' or 'faded'

        require('gruvbox').setup({
            overrides = {
                IncSearch = { bg = pal[accent .. '_purple'], fg = pal[bg .. '0'], reverse = false },
                LspReferenceRead = { bg = pal[bg .. '2'], fg = pal[accent .. '_blue'] },
                LspReferenceText = { bg = pal[bg .. '2'], fg = pal[accent .. '_purple'] },
                LspReferenceWrite = { bg = pal[bg .. '2'], fg = pal[accent .. '_red'] },
                QuickScopePrimary = { bold = true, fg = pal[accent .. '_purple'], underline = true },
                QuickScopeSecondary = { fg = pal[accent .. '_yellow'], underline = true },
                MiniTablineCurrent = { bg = pal[bg .. '2'], fg = pal[accent .. '_yellow'] },
                MiniTablineFill = { bg = pal[bg .. '0_soft'] },
                MiniTablineHidden = { fg = pal.gray },
                MiniTablineModifiedCurrent = { bg = pal[bg .. '2'], fg = pal[accent .. '_orange'] },
                MiniTablineModifiedHidden = { bg = pal[bg .. '1'], fg = pal.neutral_orange },
                MiniTablineModifiedVisible = { bg = pal[bg .. '1'], fg = pal[accent .. '_orange'] },
                MiniTablineVisible = { fg = pal[fg .. '3'] },
                NvimTreeExecFile = { bold = false, fg = pal[fg .. '1'] },
                SignColumn = { bg = pal[bg .. '0'] },
                WinBar = { bold = true, fg = pal.gray },
                WinBarNC = { bg = pal[bg .. '0'], bold = true, fg = pal[bg .. '4'] },
                WinSeparator = { fg = pal[bg .. '1'] },
                TerminalNormal = { bg = pal[bg .. '0_hard'], fg = pal[fg .. '1'] },
                TerminalEndOfBuffer = { bg = pal[bg .. '0_hard'], fg = pal[bg .. '0_hard'] },
            },
        })
    end,
})
vim.cmd.colorscheme('gruvbox')

-- Icons
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind('replace')

-- Editing
require('mini.bufremove').setup()
require('mini.pairs').setup()

vim.api.nvim_create_autocmd('BufReadPost', {
    group = vim.api.nvim_create_augroup('ConfigEditing', { clear = true }),
    pattern = {
        '/go/pkg/mod/**',
        '*/node_modules/**',
        '/usr/lib/go/**',
        '/usr/lib/go-*/**',
        '/usr/share/nvim/runtime/**',
    },
    command = 'setlocal readonly nomodifiable',
})

-- Layout
local buffers = {}
local layout_windows = {}
local layout_group = vim.api.nvim_create_augroup('ConfigLayout', { clear = true })

-- Quickfix
require('quicker').setup({
    max_filename_width = function() return 45 end,
    opts = { winbar = '%= Quickfix %=' },
    trim_leading_whitespace = 'all',
})

-- Search
local fzf_actions = require('fzf-lua.actions')

local function jdt_info(uri)
    local library, entry = uri:match('jdt://contents/([^/]+)/([^?]+)')
    if not library then return end

    return {
        library = library,
        filename = vim.fs.basename(entry),
        symbol = entry:gsub('/', '.'):gsub('%.[^.]+$', ''),
    }
end

vim.api.nvim_create_autocmd('InsertEnter', {
    group = vim.api.nvim_create_augroup('ConfigSearch', { clear = true }),
    callback = function()
        vim.schedule(function()
            vim.cmd('nohlsearch')
            vim.cmd('echo')
        end)
    end,
})

require('fzf-lua').setup({
    actions = {
        files = {
            true,
            ['alt-q'] = { fn = fzf_actions.file_sel_to_qf, prefix = 'select-all' },
        },
    },
    defaults = {
        copen = function() require('quicker').open({ focus = true, height = 16, open_cmd_mods = { split = 'botright' } }) end,
        file_icons = 'mini',
        formatter = 'path.filename_first',
    },
    files = { formatter = 'path.filename_first' },
    grep = { hidden = true },
    winopts = {
        col = 0.50,
        height = 0.50,
        title = 'fzf',
        title_flags = false,
        width = 0.60,
        preview = {
            delay = 0,
            layout = 'vertical',
            vertical = 'down:40%',
        },
    },
})

-- Git
local function toggle_git_blame()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'gitsigns-blame' then
            vim.api.nvim_win_close(win, false)
            return
        end
    end

    require('gitsigns').blame()
end

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ConfigGitsigns', { clear = true }),
    pattern = 'gitsigns-blame',
    callback = function(args)
        vim.keymap.set('n', '<Leader>gb', toggle_git_blame, { buffer = args.buf, desc = 'Git: toggle blame drawer' })
        if _G.MiniClue then MiniClue.ensure_buf_triggers(args.buf) end
    end,
})

require('gitsigns').setup({
    numhl = false,
    on_attach = function(bufnr)
        local gitsigns = require('gitsigns')
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = 'Git: ' .. desc })
        end

        map('n', '<Leader>gb', toggle_git_blame, 'toggle blame drawer')
        map('n', '<Leader>gd', function() gitsigns.diffthis() end, 'diff against index')
        map('n', '<Leader>gD', function() gitsigns.diffthis('~') end, 'diff against previous commit')
        map('n', '<Leader>gj', function() gitsigns.nav_hunk('next') end, 'next hunk')
        map('n', '<Leader>gk', function() gitsigns.nav_hunk('prev') end, 'previous hunk')
        map('n', '<Leader>gl', function() gitsigns.blame_line({ full = true }) end, 'blame line')
        map('n', '<Leader>gp', function() gitsigns.preview_hunk() end, 'preview hunk')
        map('n', '<Leader>gq', function() gitsigns.setqflist('attached') end, 'buffer hunks to quickfix')
        map('n', '<Leader>gQ', function() gitsigns.setqflist('all') end, 'repository hunks to quickfix')
        map('n', '<Leader>gr', function() gitsigns.reset_hunk() end, 'reset hunk')
        map('x', '<Leader>gr', function() gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'reset selection')
        map('n', '<Leader>gs', function() gitsigns.stage_hunk() end, 'stage or unstage hunk')
        map('x', '<Leader>gs', function() gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'stage or unstage selection')
        map('n', '<Leader>gu', function() gitsigns.undo_stage_hunk() end, 'undo staged hunk')
        if _G.MiniClue then MiniClue.ensure_buf_triggers(bufnr) end
    end,
    signcolumn = true,
})

-- Statusline
local statusline_trunc_width = 85 -- Roughly half of 175, which is the number of columns on a MBP 14" with JetBrains Mono 14px Bold.

local function statusline_git()
    return vim.trim((vim.b.gitsigns_head or '') .. ' ' .. (vim.b.gitsigns_status or ''))
end

local function statusline_indent()
    if vim.bo.expandtab then return string.format('spaces:%d', vim.bo.shiftwidth) end
    return string.format('tabs:%d', vim.bo.tabstop)
end

local function statusline()
    local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = statusline_trunc_width })
    local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = statusline_trunc_width })
    local info = jdt_info(vim.api.nvim_buf_get_name(0))
    local filename = info and info.library .. ' › ' .. info.symbol .. '%r'
        or (MiniStatusline.is_truncated(statusline_trunc_width) and '%t%r' or '%F%r')
    local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = statusline_trunc_width })

    return MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = 'MiniStatuslineDevinfo', strings = { statusline_git() } },
        { hl = 'MiniStatuslineFilename', strings = { filename } },
        '%<',
        '%=',
        { hl = 'MiniStatuslineModeVisual', strings = { diagnostics } },
        { hl = 'MiniStatuslineFileinfo', strings = { fileinfo, statusline_indent() } },
    })
end

require('mini.statusline').setup({ content = { active = statusline, inactive = statusline } })

-- Terminal
local terminal_group = vim.api.nvim_create_augroup('ConfigTerminal', { clear = true })

local function configure_terminal_panel(title)
    vim.bo.bufhidden = 'hide'
    vim.bo.buflisted = false
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = 'no'
    vim.wo.winbar = '%= ' .. title .. ' %='
    vim.wo.winhighlight = 'Normal:TerminalNormal,NormalNC:TerminalNormal,EndOfBuffer:TerminalEndOfBuffer'
    vim.wo.winfixheight = true
    vim.wo.wrap = false
end

vim.api.nvim_create_autocmd({ 'TermOpen', 'BufEnter' }, {
    group = terminal_group,
    pattern = 'term://*',
    command = 'startinsert',
})

local function toggle_terminal_panel(name, title, command)
    if layout_windows[name] and vim.api.nvim_win_is_valid(layout_windows[name]) then
        vim.api.nvim_win_hide(layout_windows[name])
        layout_windows[name] = nil
        return
    end

    if layout_windows.editor and vim.api.nvim_win_is_valid(layout_windows.editor) then
        vim.api.nvim_set_current_win(layout_windows.editor)
    end

    vim.cmd('belowright 16split')
    layout_windows[name] = vim.api.nvim_get_current_win()

    if buffers[name] and vim.api.nvim_buf_is_valid(buffers[name]) then
        vim.api.nvim_win_set_buf(layout_windows[name], buffers[name])
    else
        if command then
            vim.cmd.terminal(command)
        else
            vim.cmd.terminal()
        end
        buffers[name] = vim.api.nvim_get_current_buf()
    end

    configure_terminal_panel(title)
end

local function toggle_codex()
    toggle_terminal_panel('codex', 'Codex', 'codex')
end

local function toggle_terminal()
    toggle_terminal_panel('terminal', 'Terminal')
end

-- Full layout
-- Tabline
require('mini.tabline').setup({
    format = function(buf_id, label)
        local info = jdt_info(vim.api.nvim_buf_get_name(buf_id))
        if not info then return MiniTabline.default_format(buf_id, label) end

        local icon = MiniIcons.get('file', info.filename)
        return string.format(' %s %s ', icon, info.filename)
    end,
})

-- Aerial
require('aerial').setup({
    attach_mode = 'global',
    autojump = true,
    disable_max_lines = 1000000,
    highlight_on_hover = true,
    layout = {
        default_direction = 'right',
        max_width = 40,
        placement = 'edge',
        resize_to_content = false,
        width = 40,
        win_opts = { winbar = '%= Symbols %=' },
    },
    show_guides = true,
})

-- NvimTree
require('nvim-tree').setup({
    filters = { git_ignored = false },
    prefer_startup_root = true,
    update_focused_file = { enable = true, update_root = { enable = true } },
    view = { width = 45 },
})

vim.api.nvim_create_autocmd('VimEnter', {
    group = layout_group,
    callback = function()
        if #vim.api.nvim_list_uis() == 0 then return end

        local editor_window = vim.api.nvim_get_current_win()
        layout_windows.editor = editor_window

        require('nvim-tree.api').tree.open()
        vim.wo.winbar = '%= Explorer %='

        vim.api.nvim_set_current_win(editor_window)
    end,
})

-- Treesitter
local treesitter_parsers = {
    'bash',
    'c',
    'css',
    'diff',
    'dockerfile',
    'gitcommit',
    'gitignore',
    'go',
    'gomod',
    'gosum',
    'gotmpl',
    'gowork',
    'groovy',
    'hcl',
    'html',
    'java',
    'javascript',
    'jsdoc',
    'json',
    'kotlin',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'query',
    'regex',
    'sql',
    'toml',
    'tsx',
    'typescript',
    'vim',
    'vimdoc',
    'yaml',
}

require('nvim-treesitter').install(treesitter_parsers):wait()

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ConfigTreesitter', { clear = true }),
    callback = function(args)
        if pcall(vim.treesitter.start, args.buf) then
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo[0][0].foldmethod = 'expr'
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})

-- LSP
vim.diagnostic.config({ signs = false })

local diagnostic_group = vim.api.nvim_create_augroup('ConfigDiagnostics', { clear = true })

vim.api.nvim_create_autocmd('InsertEnter', {
    group = diagnostic_group,
    callback = function() vim.diagnostic.enable(false) end,
})

vim.api.nvim_create_autocmd('InsertLeave', {
    group = diagnostic_group,
    callback = function() vim.diagnostic.enable() end,
})

vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
                path = {
                    'lua/?.lua',
                    'lua/?/init.lua',
                },
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                },
            },
        },
    },
})

-- Java LSP
local project_root = vim.env.DEV_PROJECT_ROOT or vim.fn.getcwd()

vim.lsp.config('jdtls', {
    cmd = {
        'jdtls',
        '-data',
        vim.fs.joinpath(
            vim.fn.stdpath('cache'),
            'jdtls',
            'workspace',
            vim.fs.basename(project_root) .. '-' .. vim.fn.sha256(project_root):sub(1, 12)
        ),
    },
    settings = {
        java = {
            eclipse = { downloadSources = true },
            jdt = { ls = { kotlinSupport = { enabled = true } } },
            maven = { downloadSources = true },
            signatureHelp = { enabled = true },
        },
    },
})

vim.lsp.enable({
    'bashls',
    'cssls',
    'dockerls',
    'gopls',
    'html',
    'jsonls',
    'jdtls',
    'lua_ls',
    'tailwindcss',
    'terraformls',
    'ts_ls',
    'yamlls',
})

-- Completion
require('mini.completion').setup({ delay = { completion = 250, info = 0, signature = 0 } })

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ConfigCompletion', { clear = true }),
    pattern = 'markdown',
    callback = function(args)
        vim.b[args.buf].minicompletion_disable = true
    end,
})

-- Keymaps
local fzf = require('fzf-lua')

local function lsp_opts(title, jump1)
    local separator = '\31' -- Unit Separator
    return {
        fzf_opts = { ['--delimiter'] = separator, ['--with-nth'] = '1' },
        jump1 = jump1,
        regex_filter = function(item)
            if vim.startswith(item.filename, 'jdt://') and item.filename:find('/kotlin_generated=/true', 1, true) then
                return false
            end

            local info = jdt_info(item.filename)
            if not info then return true end

            item.filename = string.format('%s/%s:%d:%d%s%s', info.library, info.filename, item.lnum, item.col, separator, item.filename)
            return true
        end,
        _headers = { 'actions' },
        _fmt = { _from = function(entry) return entry:match(separator .. '(.*)$') or entry end },
        winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = title },
    }
end

vim.keymap.set({ 'n', 'x' }, 'd', '"_d', { desc = 'Delete without copying' })
vim.keymap.set('n', 's', '/', { desc = 'Search forward' })
vim.keymap.set('n', 'S', '?', { desc = 'Search backward' })
vim.keymap.set('c', '<CR>', function()
    if vim.fn.getcmdtype() == '/' or vim.fn.getcmdtype() == '?' then
        vim.schedule(function()
            vim.cmd.nohlsearch()
            vim.cmd('echo')
        end)
    end
    return '<CR>'
end, { desc = 'Accept command and clear search highlight', expr = true })
vim.keymap.set('n', '<A-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<A-j>', '<C-w>j', { desc = 'Move to lower window' })
vim.keymap.set('n', '<A-k>', '<C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('n', '<A-l>', '<C-w>l', { desc = 'Move to right window' })
vim.keymap.set('t', '<A-h>', '<C-\\><C-n><C-w>h', { desc = 'Move to left window' })
vim.keymap.set('t', '<A-j>', '<C-\\><C-n><C-w>j', { desc = 'Move to lower window' })
vim.keymap.set('t', '<A-k>', '<C-\\><C-n><C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('t', '<A-l>', '<C-\\><C-n><C-w>l', { desc = 'Move to right window' })
vim.keymap.set('x', '<D-c>', '"+y', { desc = 'Copy selection to system clipboard' })
vim.keymap.set({ 'n', 'x' }, 'ga', function() fzf.lsp_code_actions({ previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Actions' } }) end, { desc = 'Go to action' })
vim.keymap.set('n', 'gd', function() fzf.lsp_definitions(lsp_opts('Definitions')) end, { desc = 'Go to definition' })
vim.keymap.set('n', 'ge', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'Go to next diagnostic' })
vim.keymap.set('n', 'gE', function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = 'Go to previous diagnostic' })
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, { desc = 'Hover' })
vim.keymap.set('n', 'gi', function() fzf.lsp_implementations(lsp_opts('Implementations')) end, { desc = 'Go to implementation' })
vim.keymap.set('n', 'gl', function()
    if #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/documentHighlight' }) == 0 then return end

    if vim.b.symbol_highlighted then vim.lsp.buf.clear_references() else vim.lsp.buf.document_highlight() end
    vim.b.symbol_highlighted = not vim.b.symbol_highlighted
end, { desc = 'Toggle local symbol highlight' })
vim.keymap.set('n', 'gp', function() fzf.lsp_definitions(lsp_opts('Peek', false)) end, { desc = 'Peek definition' })
vim.keymap.set('n', 'gt', function() fzf.lsp_typedefs(lsp_opts('Type Definitions')) end, { desc = 'Go to type definition' })
vim.keymap.set('n', 'gu', function() fzf.lsp_references(lsp_opts('Usage')) end, { desc = 'Go to references' })
vim.keymap.set('n', 'gw', function() fzf.grep_cword({ winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Word Usage' } }) end, { desc = 'Grep word under cursor' })
vim.keymap.set('n', 'gx', vim.lsp.buf.rename, { desc = 'Rename symbol' })

vim.keymap.set('n', '<Space><Space>', function() fzf.live_grep({ winopts = { title = 'Global Grep' } }) end, { desc = 'Search: global grep' })
vim.keymap.set('x', '<Space><Space>', function() fzf.grep_visual({ winopts = { title = 'Selection Search' } }) end, { desc = 'Search: selection' })
vim.keymap.set('n', '<Space>.', function() fzf.resume() end, { desc = 'Search: resume last picker' })
vim.keymap.set('n', '<Space>?', function() fzf.keymaps({ previewer = false, winopts = { height = 0.50, title = 'Keymaps' } }) end, { desc = 'Search: keymaps' })
vim.keymap.set('n', '<Space>a', function() fzf.builtin({ previewer = false, winopts = { height = 0.50, title = 'Pickers' } }) end, { desc = 'Search: all pickers' })
vim.keymap.set('n', '<Space>b', function() fzf.buffers() end, { desc = 'Search: buffers' })
vim.keymap.set('n', '<Space>c', function() fzf.commands() end, { desc = 'Search: commands' })
vim.keymap.set('n', '<Space>d', function() fzf.diagnostics_workspace() end, { desc = 'Search: diagnostics' })
vim.keymap.set('n', '<Space>f', function() fzf.files() end, { desc = 'Search: files' })
vim.keymap.set('n', '<Space>h', function() fzf.helptags() end, { desc = 'Search: help' })
vim.keymap.set('n', '<Space>j', function() fzf.jumps({ previewer = false, winopts = { height = 0.50, title = 'Jumps' } }) end, { desc = 'Search: jumps' })
vim.keymap.set('n', '<Space>m', function() fzf.marks({ previewer = false, winopts = { height = 0.50, title = 'Marks' } }) end, { desc = 'Search: marks' })
vim.keymap.set('n', '<Space>p', function() fzf.global({ cwd_prompt = false, previewer = false, winopts = { height = 0.50, title = 'Pick' } }) end, { desc = 'Search: global picker' })
vim.keymap.set('n', '<Space>q', function() fzf.quickfix() end, { desc = 'Search: quickfix' })
vim.keymap.set('n', '<Space>r', function() fzf.history() end, { desc = 'Search: history' })
vim.keymap.set('n', '<Space>s', function() fzf.lgrep_curbuf({ winopts = { title = 'Buffer Search' } }) end, { desc = 'Search: current buffer' })
vim.keymap.set('n', '<Space>gb', function() fzf.git_branches() end, { desc = 'Git search: branches' })
vim.keymap.set('n', '<Space>gc', function() fzf.git_commits() end, { desc = 'Git search: commits' })
vim.keymap.set('n', '<Space>gf', function() fzf.git_bcommits() end, { desc = 'Git search: current file commits' })
vim.keymap.set('n', '<Space>gh', function() fzf.git_hunks() end, { desc = 'Git search: hunks' })
vim.keymap.set('n', '<Space>gr', function() fzf.git_reflog() end, { desc = 'Git search: reflog' })
vim.keymap.set('n', '<Space>gs', function() fzf.git_status() end, { desc = 'Git search: status' })
vim.keymap.set('n', '<Space>gt', function() fzf.git_tags() end, { desc = 'Git search: tags' })
vim.keymap.set('n', '<Space>gw', function() fzf.git_worktrees() end, { desc = 'Git search: worktrees' })

vim.keymap.set('n', '<Leader>c', 'gcc', { desc = 'Comment line', remap = true })
vim.keymap.set('x', '<Leader>c', 'gc', { desc = 'Comment selection', remap = true })
vim.keymap.set({ 'n', 'x' }, '<Leader>f', function() vim.lsp.buf.format() end, { desc = 'Format' })
vim.keymap.set('n', '<Leader>s', '<cmd>write<cr>', { desc = 'Save buffer' })
vim.keymap.set('n', '<Leader>x', '<cmd>wqall<cr>', { desc = 'Save all buffers and quit Neovim' })
vim.keymap.set('n', '<Leader>ba', '<cmd>buffer #<cr>', { desc = 'Buffer: alternate' })
vim.keymap.set('n', '<Leader>bd', function()
    if vim.bo.buftype ~= '' and #vim.api.nvim_tabpage_list_wins(0) > 1 then
        vim.api.nvim_win_close(0, false)
    else
        MiniBufremove.delete()
    end
end, { desc = 'Buffer: close current' })
vim.keymap.set('n', '<Leader>bD', function()
    local source_window = vim.api.nvim_get_current_win()
    fzf.buffers({
        actions = {
            ['enter'] = function(selected, opts)
                vim.cmd('diffthis')
                fzf_actions.buf_vsplit(selected, opts)
                vim.cmd('diffthis')
                if vim.api.nvim_win_is_valid(source_window) then vim.api.nvim_set_current_win(source_window) end
            end,
        },
        fzf_opts = { ['--no-multi'] = true },
        ignore_current_buffer = true,
        previewer = false,
        show_unloaded = false,
        winopts = { height = 0.50, title = 'Diff Buffer' },
    })
end, { desc = 'Buffer: diff selected' })
vim.keymap.set('n', '<Leader>bn', '<cmd>bnext<cr>', { desc = 'Buffer: next' })
vim.keymap.set('n', '<Leader>bp', '<cmd>bprevious<cr>', { desc = 'Buffer: previous' })
vim.keymap.set('n', '<Leader>pc', toggle_codex, { desc = 'Panel: Codex' })
vim.keymap.set('n', '<Leader>pe', function() require('nvim-tree.api').tree.toggle() end, { desc = 'Panel: Explorer' })
vim.keymap.set('n', '<Leader>po', '<cmd>AerialToggle!<cr>', { desc = 'Panel: outline' })
vim.keymap.set('n', '<Leader>pt', toggle_terminal, { desc = 'Panel: terminal' })
vim.keymap.set('n', '<Leader>q', function() require('quicker').toggle({ focus = true, height = 16, open_cmd_mods = { split = 'botright' } }) end, { desc = 'Quickfix: toggle' })

local miniclue = require('mini.clue')
miniclue.setup({
    clues = {
        { mode = 'n', keys = '<Space>g', desc = '+Git search' },
        { mode = 'n', keys = '<Leader>b', desc = '+Buffers' },
        { mode = 'n', keys = '<Leader>g', desc = '+Git actions' },
        { mode = 'n', keys = '<Leader>p', desc = '+Panels' },
    },
    triggers = {
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },
        { mode = 'n', keys = '<Space>' },
        { mode = 'x', keys = '<Space>' },
        { mode = 'n', keys = 'g' },
        { mode = 'x', keys = 'g' },
    },
})
miniclue.ensure_buf_triggers()
