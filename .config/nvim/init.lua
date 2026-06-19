vim.g.copilot_no_tab_map = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.o.breakindent = true
vim.o.colorcolumn = '+1'
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
vim.o.linebreak = true
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
vim.o.signcolumn = 'yes'
vim.o.smartcase = true
vim.o.smartindent = true
vim.o.splitbelow = true
vim.o.splitkeep = 'screen'
vim.o.splitright = true
vim.o.swapfile = false
vim.o.tabstop = 4
vim.o.textwidth = 100
vim.o.undofile = true
vim.o.updatetime = 250
vim.o.virtualedit = 'block'
vim.o.wrap = true
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

-- Git
require('gitsigns').setup()

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
