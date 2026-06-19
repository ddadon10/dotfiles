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
