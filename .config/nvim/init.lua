vim.g.copilot_no_tab_map = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.o.breakindent = true
vim.o.completeitemalign = 'kind,abbr,menu'
vim.o.completeopt = 'menu,menuone,noinsert,fuzzy'
vim.o.expandtab = true
vim.o.fileformats = 'unix,dos'
vim.o.fillchars = 'eob: '
vim.o.foldenable = false
vim.o.formatoptions = 'qjl1'
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:block,a:blinkon0'
vim.o.ignorecase = true
vim.o.infercase = true
vim.o.laststatus = 3
vim.o.list = true
vim.o.listchars = 'tab:  ,extends:…,precedes:…,nbsp:␣'
vim.o.mouse = 'a'
vim.o.mousescroll = 'ver:1,hor:1'
vim.o.number = true
vim.o.pumheight = 10
vim.o.ruler = false
vim.o.shell = '/bin/bash'
vim.o.shiftwidth = 4
vim.o.showcmd = false
vim.o.showmode = false
vim.o.signcolumn = 'no'
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.splitbelow = true
vim.o.splitkeep = 'screen'
vim.o.splitright = true
vim.o.swapfile = false
vim.o.tabstop = 4
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.virtualedit = 'block'
vim.o.wrap = false
vim.o.writebackup = false

vim.opt.shortmess:append('IscWaoOtTF')

vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = {
        '/go/pkg/mod/**',
        '*/node_modules/**',
        '/usr/lib/go/**',
        '/usr/lib/go-*/**',
        '/usr/share/nvim/runtime/**',
    },
    command = 'setlocal readonly nomodifiable',
})

vim.pack.add({
    'https://github.com/folke/flash.nvim',
    'https://github.com/folke/tokyonight.nvim',
    'https://github.com/github/copilot.vim',
    'https://github.com/ibhagwan/fzf-lua',
    'https://github.com/lewis6991/gitsigns.nvim',
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/nvim-mini/mini.nvim',
    'https://github.com/nvim-tree/nvim-tree.lua',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/stevearc/aerial.nvim',
    'https://github.com/stevearc/quicker.nvim',
}, {
    confirm = false,
})

-- Colorscheme
require('tokyonight').setup({ style = 'night' })
vim.cmd.colorscheme('tokyonight')
vim.api.nvim_set_hl(0, 'TerminalNormal', { bg = '#1d1e1d', fg = '#ffffff' })
vim.api.nvim_set_hl(0, 'TerminalEndOfBuffer', { bg = '#1d1e1d', fg = '#1d1e1d' })

-- Icons
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind('replace')

-- Editing
require('mini.bufremove').setup()
require('mini.pairs').setup()

-- Navigation
require('flash').setup()

-- Layout
local buffers = {}
local layout_windows = {}

local function layout_dimensions()
    local desktop_width = 223 -- 1920x1080 with JetBrains Mono 14px Bold.
    if vim.o.columns >= desktop_width then
        -- Desktop: 68 explorer + 1 separator + 154 editor.
        return {
            aerial = { height = 16 },
            codex = { height = 16 },
            explorer = { width = 68 },
            quickfix = { height = 16 },
            terminal = { height = 16 },
        }
    end

    -- Macbook Pro 14" has 175 columns with Jetbrains Mono 14px Bold.
    -- MacBook: 40 explorer + 1 separator + 134 editor.
    return {
        aerial = { height = 16 },
        codex = { height = 16 },
        explorer = { width = 40 },
        quickfix = { height = 16 },
        terminal = { height = 16 },
    }
end

local function set_window_width(name, width)
    local window = layout_windows[name]
    if not window or not vim.api.nvim_win_is_valid(window) then return end
    vim.api.nvim_win_set_width(window, width)
end

local function set_window_height(name, height)
    local window = layout_windows[name]
    if not window or not vim.api.nvim_win_is_valid(window) then return end
    vim.api.nvim_win_set_height(window, height)
end

local function apply_layout_dimensions()
    local dimensions = layout_dimensions()

    set_window_width('explorer', dimensions.explorer.width)
    set_window_height('aerial', dimensions.aerial.height)
    set_window_height('quickfix', dimensions.quickfix.height)
    set_window_height('terminal', dimensions.terminal.height)
    set_window_height('codex', dimensions.codex.height)
end

local function open_editor_bottom_split(height)
    if layout_windows.editor and vim.api.nvim_win_is_valid(layout_windows.editor) then
        vim.api.nvim_set_current_win(layout_windows.editor)
    end

    vim.cmd('belowright ' .. height .. 'split')
    vim.wo.winfixheight = true
    return vim.api.nvim_get_current_win()
end

local function configure_terminal_panel(title)
    vim.bo.bufhidden = 'hide'
    vim.bo.buflisted = false
    vim.wo.number = false
    vim.wo.signcolumn = 'no'
    vim.wo.winbar = '%= ' .. title .. ' %='
    vim.wo.winhighlight = 'Normal:TerminalNormal,NormalNC:TerminalNormal,EndOfBuffer:TerminalEndOfBuffer'
    vim.wo.winfixheight = true
end

local function toggle_quickfix()
    local dimensions = layout_dimensions()

    if layout_windows.editor and vim.api.nvim_win_is_valid(layout_windows.editor) then
        vim.api.nvim_set_current_win(layout_windows.editor)
    end

    require('quicker').toggle({ height = dimensions.quickfix.height, open_cmd_mods = { split = 'belowright' } })
end

-- Quickfix
require('quicker').setup({ opts = { winbar = '%= Quickfix %=' } })

-- Search
local fzf_actions = require('fzf-lua.actions')

require('fzf-lua').setup({
    actions = {
        files = {
            true,
            ['ctrl-q'] = { fn = fzf_actions.file_sel_to_qf, prefix = 'select-all' },
        },
    },
    defaults = {
        copen = 'belowright copen ' .. layout_dimensions().quickfix.height,
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
require('gitsigns').setup({ numhl = true, signcolumn = false })

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
    local filename = MiniStatusline.is_truncated(statusline_trunc_width) and '%t%r' or '%F%r'
    local location = MiniStatusline.section_location({ trunc_width = statusline_trunc_width })
    local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = statusline_trunc_width })

    return MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = 'MiniStatuslineDevinfo', strings = { statusline_git() } },
        { hl = 'MiniStatuslineFilename', strings = { filename } },
        '%<',
        '%=',
        { hl = 'MiniStatuslineModeVisual', strings = { diagnostics } },
        { hl = 'MiniStatuslineFileinfo', strings = { location, fileinfo, statusline_indent() } },
    })
end

require('mini.statusline').setup({ content = { active = statusline, inactive = statusline } })

-- Tabline
require('mini.tabline').setup()

-- Aerial
require('aerial').setup({
    attach_mode = 'global',
    disable_max_lines = 1000000,
    highlight_on_hover = true,
    layout = { resize_to_content = false, win_opts = { winbar = '%= Symbols %=' } },
    show_guides = true,
})

-- NvimTree
require('nvim-tree').setup({
    filters = { git_ignored = false },
    prefer_startup_root = true,
    update_focused_file = { enable = true, update_root = { enable = true } },
    view = { side = 'left', width = function() return layout_dimensions().explorer.width end },
})

-- Terminal
local terminal_group = vim.api.nvim_create_augroup('ConfigTerminal', { clear = true })

vim.api.nvim_create_autocmd({ 'TermOpen', 'BufEnter' }, {
    group = terminal_group,
    pattern = 'term://*',
    command = 'startinsert',
})

local layout_group = vim.api.nvim_create_augroup('ConfigLayout', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
    group = layout_group,
    pattern = 'qf',
    callback = function()
        layout_windows.quickfix = vim.api.nvim_get_current_win()
        set_window_height('quickfix', layout_dimensions().quickfix.height)
        vim.wo.winfixheight = true
    end,
})

vim.api.nvim_create_autocmd('VimEnter', {
    group = layout_group,
    callback = function()
        if #vim.api.nvim_list_uis() == 0 then return end

        local editor_window = vim.api.nvim_get_current_win()
        local dimensions = layout_dimensions()

        layout_windows.editor = editor_window

        require('nvim-tree.api').tree.open()
        layout_windows.explorer = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_width(layout_windows.explorer, dimensions.explorer.width)
        vim.wo.winbar = '%= Explorer %='
        vim.wo.winfixwidth = true

        vim.cmd('belowright ' .. dimensions.aerial.height .. 'split')
        layout_windows.aerial = vim.api.nvim_get_current_win()
        require('aerial').open_in_win(layout_windows.aerial, editor_window)
        vim.api.nvim_win_set_height(layout_windows.aerial, dimensions.aerial.height)
        vim.wo[layout_windows.aerial].winfixheight = true
        vim.wo[layout_windows.aerial].winfixwidth = true

        vim.api.nvim_set_current_win(editor_window)
    end,
})

vim.api.nvim_create_autocmd('VimResized', {
    group = layout_group,
    callback = function()
        if #vim.api.nvim_list_uis() == 0 then return end
        apply_layout_dimensions()
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
    'hcl',
    'html',
    'javascript',
    'jsdoc',
    'json',
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

vim.lsp.enable({
    'bashls',
    'cssls',
    'dockerls',
    'gopls',
    'html',
    'jsonls',
    'lua_ls',
    'tailwindcss',
    'terraformls',
    'ts_ls',
    'yamlls',
})

-- Completion
require('mini.completion').setup({ delay = { completion = 250, info = 0, signature = 0 } })

vim.keymap.set('i', '<Tab>', 'copilot#Accept(pumvisible() ? "\\<C-y>" : "\\<Tab>")', {
    expr = true,
    replace_keycodes = false,
    silent = true,
})

local function toggle_terminal_panel(name, title, command)
    local dimensions = layout_dimensions()

    if layout_windows[name] and vim.api.nvim_win_is_valid(layout_windows[name]) then
        vim.api.nvim_win_hide(layout_windows[name])
        layout_windows[name] = nil
        return
    end

    layout_windows[name] = open_editor_bottom_split(dimensions[name].height)

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

-- Keymaps
local fzf = require('fzf-lua')

vim.keymap.set('t', '<C-w>h', '<C-\\><C-n><C-w>h', { desc = 'Move to left window' })
vim.keymap.set('t', '<C-w>j', '<C-\\><C-n><C-w>j', { desc = 'Move to lower window' })
vim.keymap.set('t', '<C-w>k', '<C-\\><C-n><C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('t', '<C-w>l', '<C-\\><C-n><C-w>l', { desc = 'Move to right window' })
vim.keymap.set('x', '<D-c>', '"+y', { desc = 'Copy selection to system clipboard' })
vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = 'Flash jump' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash treesitter' })
vim.keymap.set('o', 'r', function() require('flash').remote() end, { desc = 'Remote Flash' })
vim.keymap.set({ 'n', 'v' }, 'ga', function() fzf.lsp_code_actions({ silent = true, previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Actions' } }) end, { desc = 'Go to action' })
vim.keymap.set('n', 'gd', function() fzf.lsp_definitions() end, { desc = 'Go to definition' })
vim.keymap.set('n', 'ge', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'Go to next diagnostic' })
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, { desc = 'Hover' })
vim.keymap.set('n', 'gi', function() fzf.lsp_implementations({ previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Implementations' } }) end, { desc = 'Go to implementation' })
vim.keymap.set('n', 'gp', function() fzf.lsp_definitions({ jump1 = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.50, width = 0.60, title = 'Peek', preview = { layout = 'vertical', vertical = 'up:75%' } } }) end, { desc = 'Peek definition' })
vim.keymap.set('n', 'gt', function() fzf.lsp_typedefs({ previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Type Definitions' } }) end, { desc = 'Go to type definition' })
vim.keymap.set('n', 'gu', function() fzf.lsp_references({ previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Usage' } }) end, { desc = 'Go to references' })
vim.keymap.set('n', 'gx', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set('n', '[q', '<cmd>cprevious<cr>', { desc = 'Previous quickfix item' })
vim.keymap.set('n', ']q', '<cmd>cnext<cr>', { desc = 'Next quickfix item' })
vim.keymap.set('n', '{', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '|', function() MiniBufremove.delete() end, { desc = 'Close buffer' })
vim.keymap.set('n', '}', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<Leader><Leader>', function() fzf.live_grep() end, { desc = 'Live grep' })
vim.keymap.set('x', '<Leader><Leader>', function() fzf.grep_visual({ winopts = { title = 'Selection Search' } }) end, { desc = 'Search selection' })
vim.keymap.set('n', '<Leader>.', function() fzf.resume() end, { desc = 'Resume last picker' })
vim.keymap.set('n', '<Leader>/', function() fzf.lgrep_curbuf({ winopts = { title = 'Buffer Search' } }) end, { desc = 'Grep current buffer' })
vim.keymap.set('n', '<Leader>?', function() fzf.keymaps({ previewer = false, winopts = { height = 0.50, title = 'Keymaps' } }) end, { desc = 'Keymaps' })
vim.keymap.set('n', '<Leader>a', function() fzf.builtin({ previewer = false, winopts = { height = 0.50, title = 'Pickers' } }) end, { desc = 'All pickers' })
vim.keymap.set('n', '<Leader>b', function() require('gitsigns').blame() end, { desc = 'Blame' })
vim.keymap.set('n', '<Leader>c', toggle_codex, { desc = 'Toggle Codex' })
vim.keymap.set('n', '<Leader>d', function() require('gitsigns').diffthis() end, { desc = 'Git diff' })
vim.keymap.set('n', '<Leader>j', function() fzf.jumps({ previewer = false, winopts = { height = 0.50, title = 'Jumps' } }) end, { desc = 'Jumps' })
vim.keymap.set('n', '<Leader>m', function() fzf.marks({ previewer = false, winopts = { height = 0.50, title = 'Marks' } }) end, { desc = 'Marks' })
vim.keymap.set('n', '<Leader>p', function() fzf.global({ cwd_prompt = false, previewer = false, winopts = { height = 0.50, title = 'Pick' } }) end, { desc = 'Global picker' })
vim.keymap.set('n', '<Leader>q', toggle_quickfix, { desc = 'Toggle quickfix' })
vim.keymap.set('n', '<Leader>t', toggle_terminal, { desc = 'Toggle terminal' })
