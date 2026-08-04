local quick_edit = vim.env.NVIM_QUICK_EDIT == '1'

-- Options
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.qs_highlight_on_keys = { 'f', 'F', 't', 'T' }

vim.o.breakindent = true
vim.o.completeitemalign = 'kind,abbr,menu'
vim.o.completeopt = 'menu,menuone,noinsert,fuzzy'
vim.o.expandtab = true
vim.o.fillchars = 'eob: '
vim.o.foldenable = false
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:block'
vim.o.ignorecase = true
vim.o.laststatus = 3
vim.o.linebreak = true
vim.o.mouse = 'a'
vim.o.mousescroll = 'ver:1,hor:1'
vim.o.number = true
vim.o.pumheight = 10
vim.o.relativenumber = true
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
local gruvbox = require('gruvbox')
local palette = gruvbox.palette

gruvbox.setup({
    overrides = {
        QuickScopePrimary = {
            bold = true,
            fg = palette.bright_blue,
            underline = true,
        },
        QuickScopeSecondary = {
            fg = palette.neutral_red,
            underline = true,
        },
    },
})
vim.cmd.colorscheme('gruvbox')
vim.api.nvim_set_hl(0, 'TerminalNormal', { bg = '#1d2021', fg = '#ebdbb2' })
vim.api.nvim_set_hl(0, 'TerminalEndOfBuffer', { bg = '#1d2021', fg = '#1d2021' })

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

local function layout_dimensions()
    local desktop_width = 223 -- 1920x1080 with JetBrains Mono 14px Bold.
    if vim.o.columns >= desktop_width then
        -- Desktop: 66 explorer + 1 separator + 2 sign gutter + 154 editor.
        return {
            aerial = { height = 16 },
            codex = { height = 16 },
            explorer = { width = 66 },
            quickfix = { height = 16 },
            terminal = { height = 16 },
        }
    end

    -- Macbook Pro 14" has 175 columns with Jetbrains Mono 14px Bold.
    -- MacBook: 38 explorer + 1 separator + 2 sign gutter + 134 editor.
    return {
        aerial = { height = 16 },
        codex = { height = 16 },
        explorer = { width = 38 },
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

local function toggle_quickfix()
    local dimensions = layout_dimensions()

    if layout_windows.editor and vim.api.nvim_win_is_valid(layout_windows.editor) then
        vim.api.nvim_set_current_win(layout_windows.editor)
    end

    require('quicker').toggle({ height = dimensions.quickfix.height, open_cmd_mods = { split = 'belowright' } })
end

-- Quickfix
require('quicker').setup({ opts = { winbar = '%= Quickfix %=' } })

vim.api.nvim_create_autocmd('FileType', {
    group = layout_group,
    pattern = 'qf',
    callback = function()
        layout_windows.quickfix = vim.api.nvim_get_current_win()
        set_window_height('quickfix', layout_dimensions().quickfix.height)
        vim.wo.winfixheight = true
    end,
})

-- Search
local fzf_actions = require('fzf-lua.actions')

local function library_info(uri)
    local library, entry = uri:match('jdt://contents/([^/]+)/([^?]+)')

    if not library then
        library, entry = uri:match('jar://(.-)!/([^:]+)')
        library = library and vim.fs.basename(library):gsub('%-sources%.jar$', '.jar')
    end

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
require('gitsigns').setup({ numhl = false, signcolumn = true })

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
    local info = library_info(vim.api.nvim_buf_get_name(0))
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

-- Full layout
if not quick_edit then
    -- Tabline
    require('mini.tabline').setup({
        format = function(buf_id, label)
            local info = library_info(vim.api.nvim_buf_get_name(buf_id))
            if not info then return MiniTabline.default_format(buf_id, label) end

            local icon = MiniIcons.get('file', info.filename)
            return string.format(' %s %s ', icon, info.filename)
        end,
    })

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
        view = { side = 'left' },
    })

    local function open_full_layout()
        if #vim.api.nvim_list_uis() == 0 then return end

        local editor_window = vim.api.nvim_get_current_win()
        local dimensions = layout_dimensions()
        layout_windows.editor = editor_window

        require('nvim-tree.api').tree.open()
        layout_windows.explorer = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_width(layout_windows.explorer, dimensions.explorer.width)
        vim.wo[layout_windows.explorer].winbar = '%= Explorer %='
        vim.wo[layout_windows.explorer].winfixwidth = true

        vim.cmd('belowright ' .. dimensions.aerial.height .. 'split')
        layout_windows.aerial = vim.api.nvim_get_current_win()
        require('aerial').open_in_win(layout_windows.aerial, editor_window)
        vim.api.nvim_win_set_height(layout_windows.aerial, dimensions.aerial.height)
        vim.wo[layout_windows.aerial].winfixheight = true
        vim.wo[layout_windows.aerial].winfixwidth = true
        vim.w[layout_windows.aerial].aerial_set_width = true -- Prevent Aerial's deferred render from resizing the shared vertical split

        vim.api.nvim_set_current_win(editor_window)
    end

    vim.api.nvim_create_autocmd('VimEnter', {
        group = layout_group,
        callback = open_full_layout,
    })
end

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

-- Java and Kotlin LSP
vim.lsp.config('jdtls', {
    settings = {
        java = {
            eclipse = { downloadSources = true },
            jdt = { ls = { kotlinSupport = { enabled = true } } },
            maven = { downloadSources = true },
            signatureHelp = { enabled = true },
        },
    },
})

vim.lsp.config('kotlin_lsp', { settings = { jetbrains = { kotlin = { ['hints.parameters'] = true } } } })

local function open_kotlin_archive_uri(args)
    local client = vim.lsp.get_clients({ name = 'kotlin_lsp', bufnr = 0 })[1] -- Current source during preview
        or vim.lsp.get_clients({ name = 'kotlin_lsp', bufnr = vim.fn.bufnr('#') })[1] -- Source before archive jump
        or vim.lsp.get_clients({ name = 'kotlin_lsp' })[1] -- Fallback without source context
    assert(client, 'No kotlin_lsp client is available to decompile ' .. args.match)

    local res = assert(client:request_sync('workspace/executeCommand', { command = 'decompile', arguments = { args.match } }, 10000))
    local result = assert(res.result, res.err and vim.inspect(res.err) or 'No archive contents for ' .. args.match)

    local bo = vim.bo[args.buf]
    bo.buftype, bo.swapfile, bo.modifiable = 'nofile', false, true
    vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, vim.split(result.code, '\n'))
    bo.filetype, bo.modifiable = result.language, false
    vim.lsp.buf_attach_client(args.buf, client.id)
end

local classfile_group = vim.api.nvim_create_augroup('ConfigClassfiles', { clear = true })

vim.api.nvim_create_autocmd('LspAttach', { -- nvim-jdtls's *.class autocmd also matches Kotlin's jar:// and jrt:// URIs.
    group = classfile_group,
    once = true,
    callback = function() vim.api.nvim_clear_autocmds({ group = 'jdtls', pattern = '*.class' }) end,
})

vim.api.nvim_create_autocmd('BufReadCmd', {
    group = classfile_group,
    pattern = { 'jar://*', 'jrt://*' },
    callback = open_kotlin_archive_uri,
})

vim.api.nvim_create_autocmd('BufReadCmd', {
    group = classfile_group,
    pattern = '*.class',
    callback = function(args)
        if args.match:find('://', 1, true) then return end
        require('jdtls').open_classfile(args.buf, args.match)
    end,
})

vim.lsp.enable({
    'bashls',
    'cssls',
    'dockerls',
    'gopls',
    'html',
    'jsonls',
    'jdtls',
    'kotlin_lsp',
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

local function lsp_location_opts(title, jump1)
    local separator = '\31'
    return {
        fzf_opts = { ['--delimiter'] = separator, ['--with-nth'] = '1' },
        jump1 = jump1,
        regex_filter = function(item)
            if vim.startswith(item.filename, 'jdt://') and item.filename:find('/kotlin_generated=/true', 1, true) then
                return false
            end

            local info = library_info(item.filename)
            if not info then return true end

            item.filename = string.format('%s/%s:%d:%d%s%s', info.library, info.filename, item.lnum, item.col, separator, item.filename)
            return true
        end,
        _headers = { 'actions' },
        _fmt = { _from = function(entry) return entry:match(separator .. '(.*)$') or entry end },
        winopts = { title = title },
    }
end

vim.keymap.set('n', 'qq', '<cmd>quitall<cr>', { desc = 'Quit Neovim' })
vim.keymap.set({ 'n', 'x' }, 'd', '"_d', { desc = 'Delete without copying' })
vim.keymap.set('n', 's', '/', { desc = 'Search forward' })
vim.keymap.set('n', 'S', function() fzf.lgrep_curbuf({ winopts = { title = 'Buffer Search' } }) end, { desc = 'Grep current buffer' })
vim.keymap.set('t', '<C-w>h', '<C-\\><C-n><C-w>h', { desc = 'Move to left window' })
vim.keymap.set('t', '<C-w>j', '<C-\\><C-n><C-w>j', { desc = 'Move to lower window' })
vim.keymap.set('t', '<C-w>k', '<C-\\><C-n><C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('t', '<C-w>l', '<C-\\><C-n><C-w>l', { desc = 'Move to right window' })
vim.keymap.set('x', '<D-c>', '"+y', { desc = 'Copy selection to system clipboard' })
vim.keymap.set({ 'n', 'v' }, 'ga', function() fzf.lsp_code_actions({ previewer = false, winopts = { relative = 'cursor', row = 1, col = 0, height = 0.30, width = 0.50, title = 'Actions' } }) end, { desc = 'Go to action' })
vim.keymap.set('n', 'gd', function() fzf.lsp_definitions(lsp_location_opts('Definitions')) end, { desc = 'Go to definition' })
vim.keymap.set('n', 'ge', function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = 'Go to next diagnostic' })
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, { desc = 'Hover' })
vim.keymap.set('n', 'gi', function() fzf.lsp_implementations(lsp_location_opts('Implementations')) end, { desc = 'Go to implementation' })
vim.keymap.set('n', 'gp', function() fzf.lsp_definitions(lsp_location_opts('Peek', false)) end, { desc = 'Peek definition' })
vim.keymap.set('n', 'gt', function() fzf.lsp_typedefs(lsp_location_opts('Type Definitions')) end, { desc = 'Go to type definition' })
vim.keymap.set('n', 'gu', function() fzf.lsp_references(lsp_location_opts('Usage')) end, { desc = 'Go to references' })
vim.keymap.set('n', 'gw', function() fzf.grep_cword({ winopts = { title = 'Word Usage' } }) end, { desc = 'Grep word under cursor' })
vim.keymap.set('n', 'gx', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set('n', '[q', '<cmd>cprevious<cr>', { desc = 'Previous quickfix item' })
vim.keymap.set('n', ']q', '<cmd>cnext<cr>', { desc = 'Next quickfix item' })
vim.keymap.set('n', '{', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
vim.keymap.set('n', '|', function() MiniBufremove.delete() end, { desc = 'Close buffer' })
vim.keymap.set('n', '}', '<cmd>bnext<cr>', { desc = 'Next buffer' })
vim.keymap.set('n', '<Leader><Leader>', function() fzf.live_grep({ winopts = { title = 'Global Grep' } }) end, { desc = 'Global grep' })
vim.keymap.set('x', '<Leader><Leader>', function() fzf.grep_visual({ winopts = { title = 'Selection Search' } }) end, { desc = 'Global grep on selection' })
vim.keymap.set('n', '<Leader>.', function() fzf.resume() end, { desc = 'Resume last picker' })
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
