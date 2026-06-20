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
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:block'
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

-- Icons
require('mini.icons').setup()
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind('replace')

-- Editing
require('mini.bufremove').setup()
require('mini.pairs').setup()

-- Navigation
require('flash').setup()

-- Search
require('fzf-lua').setup({
    defaults = {
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
local statusline_trunc_width = 85

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

-- Tabline
require('mini.tabline').setup()

-- Aerial
require('aerial').setup({
    attach_mode = 'global',
    disable_max_lines = 1000000,
    highlight_on_hover = true,
    show_guides = true,
})

-- Layout
local layout_windows = {}

local function layout_dimensions()
    local desktop_width = 223 -- 1920x1080 with JetBrains Mono 14px Bold.
    if vim.o.columns >= desktop_width then
        -- Editor will have 120 text columns, and 4 number columns.
        -- We substract 1 from explorer and 1 from codex to account for the window separator.
        return { explorer = 41, codex = 56 }
    end

    -- Macbook Pro 14" has 175 columns with Jetbrains Mono 14px Bold.
    -- Editor will have 100 text columns, and 4 number columns.
    -- We substract 1 from explorer and 1 from codex to account for the window separator.
    return { explorer = 30, codex = 39 }
end

local function apply_layout_dimensions()
    local dimensions = layout_dimensions()

    if layout_windows.explorer and vim.api.nvim_win_is_valid(layout_windows.explorer) then
        vim.api.nvim_win_set_width(layout_windows.explorer, dimensions.explorer)
    end

    if layout_windows.codex and vim.api.nvim_win_is_valid(layout_windows.codex) then
        vim.api.nvim_win_set_width(layout_windows.codex, dimensions.codex)
    end
end

-- NvimTree
require('nvim-tree').setup({
    filters = { git_ignored = false },
    prefer_startup_root = true,
    update_focused_file = { enable = true, update_root = { enable = true } },
    view = { side = 'left', width = function() return layout_dimensions().explorer end },
})

-- Terminal
local terminal_group = vim.api.nvim_create_augroup('ConfigTerminal', { clear = true })

vim.api.nvim_create_autocmd({ 'TermOpen', 'BufEnter' }, {
    group = terminal_group,
    pattern = 'term://*',
    command = 'startinsert',
})

local layout_group = vim.api.nvim_create_augroup('ConfigLayout', { clear = true })

vim.api.nvim_create_autocmd('VimEnter', {
    group = layout_group,
    callback = function()
        if #vim.api.nvim_list_uis() == 0 then return end

        local dimensions = layout_dimensions()

        require('nvim-tree.api').tree.open()
        layout_windows.explorer = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_width(layout_windows.explorer, dimensions.explorer)
        vim.wo.winbar = '%= Explorer %='
        vim.wo.winfixwidth = true

        vim.cmd('wincmd p')
        vim.cmd('botright vertical ' .. dimensions.codex .. 'split')
        vim.cmd.terminal('codex')
        layout_windows.codex = vim.api.nvim_get_current_win()
        vim.bo.buflisted = false
        vim.wo.number = false
        vim.wo.signcolumn = 'no'
        vim.wo.winbar = '%= Codex %='
        vim.wo.winhighlight = 'Normal:NvimTreeNormal,NormalNC:NvimTreeNormalNC,EndOfBuffer:NvimTreeNormal'
        vim.wo.winfixwidth = true

        vim.cmd('wincmd p')
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

-- Keymaps
local fzf = require('fzf-lua')

vim.keymap.set({ 'n', 'v' }, 'ga', function() fzf.lsp_code_actions({ silent = true, previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Actions' } }) end, { desc = 'Go to action' })
vim.keymap.set('n', 'gd', function() fzf.lsp_definitions() end, { desc = 'Go to definition' })
vim.keymap.set('n', 'ge', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'Go to next diagnostic' })
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, { desc = 'Hover' })
vim.keymap.set('n', 'gi', function() fzf.lsp_implementations({ previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Implementations' } }) end, { desc = 'Go to implementation' })
vim.keymap.set('n', 'gp', function() fzf.lsp_definitions({ jump1 = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.50, width = 0.60, title = 'Peek', preview = { layout = 'vertical', vertical = 'up:75%' } } }) end, { desc = 'Peek definition' })
vim.keymap.set('n', 'gt', function() fzf.lsp_typedefs({ previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Type Definitions' } }) end, { desc = 'Go to type definition' })
vim.keymap.set('n', 'gu', function() fzf.lsp_references({ previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Usage' } }) end, { desc = 'Go to references' })
vim.keymap.set('n', 'gx', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set('n', '<Leader><Leader>', function() fzf.live_grep() end, { desc = 'Live grep' })
vim.keymap.set('n', '<Leader>.', function() fzf.resume() end, { desc = 'Resume last picker' })
vim.keymap.set('n', '<Leader>/', function() fzf.lgrep_curbuf({ winopts = { title = 'Buffer Search' } }) end, { desc = 'Grep current buffer' })
vim.keymap.set('n', '<Leader>?', function() fzf.keymaps({ previewer = false, winopts = { height = 0.50, title = 'Keymaps' } }) end, { desc = 'Keymaps' })
vim.keymap.set('n', '<Leader>a', function() fzf.builtin({ previewer = false, winopts = { height = 0.50, title = 'Pickers' } }) end, { desc = 'All pickers' })
vim.keymap.set('n', '<Leader>j', function() fzf.jumps({ previewer = false, winopts = { height = 0.50, title = 'Jumps' } }) end, { desc = 'Jumps' })
vim.keymap.set('n', '<Leader>m', function() fzf.marks({ previewer = false, winopts = { height = 0.50, title = 'Marks' } }) end, { desc = 'Marks' })
vim.keymap.set('n', '<Leader>p', function() fzf.global({ cwd_prompt = false, previewer = false, winopts = { height = 0.50, title = 'Pick' } }) end, { desc = 'Global picker' })
