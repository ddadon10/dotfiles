# Neovim Import Notes

Source branch: `nvim`

Current branch during cataloging: `add-neovim`

The Neovim config on the source branch lives under:

- `dev/nvim`

The target branch stores the imported config under:

- `.config/nvim`

Supporting source-branch files include:

- `dev/Dockerfile`
- `dev/.bashrc`
- `dev/bash_profile`
- `dev/scratches` source-only; do not import

Do not merge the whole `nvim` branch blindly. That branch also changes broader dev
environment behavior. The target import removes VS Code web/editor from the
Docker image and moves toward a Neovim-first shell workflow.

## Target Decisions

- Default container command should be `CMD ["/bin/bash", "--login"]`, not VS
  Code web and not Neovim. Runtime setup belongs in `dev/.bashrc`.
- VS Code web/editor and `nginx` should be removed from the Docker image.
- Keep repo `vscode/` settings and keybindings.
- Keep `vscode-langservers-extracted`; it is Neovim LSP tooling, not VS Code
  web/editor.
- Docker installs `@openai/codex@0.141.0`.
- Keep `EDITOR=vim` for now.
- Neovim socket support is deferred; when added, use a stable Unix socket
  outside the repo, for example `/tmp/nvim-${UID}/socket`.
- Do not put `nvim --listen ...` directly in `$EDITOR`.
- Use Tokyonight Night normally:
  - Add `folke/tokyonight.nvim`.
  - Remove `miikanissi/modus-themes.nvim`.
  - Remove custom color overrides and transparency-related theme overrides.
  - Use normal Tokyonight setup with `style = 'night'`, then load
    `colorscheme tokyonight`.
- Set formatting column to 100:
  - Change `textwidth` from `120` to `100`.
  - Keep word wrap, linebreak, and breakindent enabled.
  - Keep `colorcolumn = '+1'` if the marker should stay one column after
    `textwidth`.
- Target layout:
  - Codex terminal on the left.
  - Main editor in the middle at about 100 columns when the terminal is wide
    enough.
  - File explorer on the right.
  - Aerial below the file explorer.
  - This needs a dedicated layout step after base UI, terminal, nvim-tree, and
    Aerial are working.
- Replace Fugitive with Gitsigns for configured Git behavior:
  - Add `lewis6991/gitsigns.nvim`.
  - Remove `tpope/vim-fugitive`.
  - Replace branch/statusline, blame, and diff behavior with Gitsigns plus git
    CLI fallbacks where needed.
  - Gitsigns does not replace broader Fugitive porcelain commands like `:Git`,
    commit, log, object editing, or conflict workflows.
- Remove from the target import:
  - `MeanderingProgrammer/render-markdown.nvim`.
  - `config.autosave`.
  - `config.scratch`.
  - `dev/scratches`.
- Add `github/copilot.vim`:
  - Keep Mini completion on `<Tab>`.
  - Disable Copilot's default Tab mapping.
  - Use an explicit accept mapping such as insert-mode `<C-J>`.
  - Persist credentials by mounting the whole host
    `~/.config/github-copilot` directory into
    `/root/.config/github-copilot`.
  - Run `:Copilot setup` interactively once after the mount exists.
- Neovim config import shape:
  - Keep the imported Lua config in a single `.config/nvim/init.lua`.
  - Append one reviewed section at a time.
  - Do not create `.config/nvim/lua/config/*.lua` modules.
  - Query overrides are the exception and still live under
    `.config/nvim/queries`.

## Plugin Inventory

Plugin manager:

- Native `vim.pack`: Neovim 0.12 built-in package manager.

Configured plugins:

- `folke/flash.nvim`: jump/navigation motions.
- `folke/tokyonight.nvim`: colorscheme.
- `github/copilot.vim`: GitHub Copilot inline suggestions.
- `ibhagwan/fzf-lua`: files, grep, LSP pickers, keymaps, jumps, marks.
- `lewis6991/gitsigns.nvim`: Git signs, hunks, diff, and blame.
- `neovim/nvim-lspconfig`: LSP server definitions.
- `nvim-mini/mini.nvim`: all-in-one Mini module collection.
- `nvim-tree/nvim-tree.lua`: file explorer.
- `nvim-treesitter/nvim-treesitter`: syntax, indent, folds; track default
  branch.
- `stevearc/aerial.nvim`: symbols outline.
- `stevearc/quicker.nvim`: quickfix UI.

Mini modules to activate later:

- `mini.bufremove`: safer buffer deletion; needed by buffer close mappings.
- `mini.completion`: completion engine; keep completion on `<Tab>`.
- `mini.icons`: icon provider; call `MiniIcons.mock_nvim_web_devicons()` so
  `nvim-tree` can use icons without `nvim-web-devicons`.
- `mini.pairs`: auto-pairs.
- `mini.statusline`: statusline backend.
- `mini.tabline`: buffer tabline; replaces Bufferline.

Source branch plugins intentionally removed from the target:

- `akinsho/bufferline.nvim`: replaced by `mini.tabline`.
- `MeanderingProgrammer/render-markdown.nvim`.
- `miikanissi/modus-themes.nvim`.
- `nvim-tree/nvim-web-devicons`: replaced by `mini.icons` plus
  `MiniIcons.mock_nvim_web_devicons()`.
- `nvim-treesitter/nvim-treesitter-context`.
- `tpope/vim-fugitive`.

## Feature Catalog

### Core Editor

- Space leader and local leader.
- Mouse enabled.
- Swap disabled, undo enabled.
- 4-space indentation.
- `textwidth=100` and colorcolumn at `+1`.
- Wrap enabled with linebreak.
- List characters enabled.
- Search uses smartcase.
- OSC52 clipboard configured.
- Shell set to `/bin/bash`.
- Readonly protection for paths under Go module cache, `node_modules`, GOROOT,
  and the Vim runtime.

### LSP

Enabled servers:

- `bashls`
- `cssls`
- `dockerls`
- `gopls`
- `html`
- `jsonls`
- `lua_ls`
- `tailwindcss`
- `terraformls`
- `ts_ls`
- `yamlls`

Behavior:

- Diagnostic signs are disabled.
- Other diagnostic display behavior uses Neovim defaults.
- Diagnostics are disabled in insert mode and re-enabled on insert leave.
- LuaLS is configured for Neovim Lua development:
  - `runtime.version = 'LuaJIT'`.
  - `runtime.path = { 'lua/?.lua', 'lua/?/init.lua' }`.
  - `workspace.checkThirdParty = false`.
  - `workspace.library = { vim.env.VIMRUNTIME }`.
- Formatting helpers, rename overrides, and LSP keymaps are deferred.

### Completion

- Uses `mini.completion`.
- Tweaks LSP completion detail display.
- Overrides `MiniCompletion.completefunc_lsp` to clean up completion menu text.
- Adds custom inline signature help rendered as end-of-line virtual text.

### Search And Navigation

- `fzf-lua` handles files, grep, buffer search, LSP locations, keymaps, jumps,
  marks, and picker list.
- Workspace root is inferred from the initial cwd's nearest `.git`.
- Grep profiles:
  - `all`
  - `go`
  - `frontend`
- Grep sorts test-file matches later in the results.
- Flash mappings:
  - `s`: jump.
  - `S`: treesitter jump.
  - operator-pending `r`: remote jump.
  - operator/visual `R`: treesitter search.

### Treesitter

Parser install behavior needs review during the Treesitter step; do not rely on
the old source-branch package path.

Configured parsers include:

- Bash
- C
- Caddy
- CSS
- Diff
- Dockerfile
- Git files
- Go
- Go templates
- HCL
- HTML
- HTTP
- JavaScript
- JSON
- Lua
- Markdown
- Query
- Regex
- SQL
- TOML
- TSX
- TypeScript
- Vim
- YAML

Behavior:

- Adds Caddyfile filetype detection.
- Starts treesitter on filetype when possible.
- Sets treesitter fold expression.
- Sets treesitter indentation.
Custom queries:

- Caddyfile highlights, injections, and locals.
- Dockerfile bash injection.
- Go template HTML injection.
- HCL bash heredoc injection.
- Markdown fenced code block injection.
- YAML bash block scalar injection.

### UI

- Tokyonight Night colorscheme with no custom color overrides.
- `mini.statusline` custom statusline.
- `mini.tabline` replaces Bufferline.
- `mini.icons` provides icons and mocks `nvim-web-devicons` for `nvim-tree`.
- `mini.pairs`.
- `nvim-tree` should open as the fixed right-side file explorer.
- Aerial should open below the file explorer, not as a competing right-edge pane.
- Quicker wraps quickfix with custom mappings.
- Terminal buffers get a custom statusline and auto-insert behavior.

### Git

- Gitsigns provides buffer signs, hunks, diff, blame, and statusline variables.
- Branch/project name helpers need Gitsigns variables plus git CLI fallbacks.
- `<Leader>b` should toggle a Gitsigns blame split.
- `<Leader>d` should run a Gitsigns diff.
- Fugitive's broader `:Git` workflow is not included in the target import.

### Scratch Projects

Scratch support is source-only and should not be imported.

### Code Runner

- `<Leader>s` runs simple filetype commands.
- Go:
  - If cursor is inside `Test*`, `Benchmark*`, or `Fuzz*`, run that test.
  - Otherwise run the current Go file.
- JavaScript: run current file with `node`.
- Bash or sh: run current file with `bash`.

### Autosave

Autosave is source-only and should not be imported.

## Keymap Catalog

- `gd`: fzf LSP definitions.
- `ge`: next diagnostic.
- `gh`: hover.
- `ga`: code actions.
- `gi`: implementations.
- `gp`: peek definition.
- `gt`: type definitions.
- `gu`: references.
- `gx`: rename.
- `{`: previous buffer.
- `}`: next buffer.
- `|`: close buffer.
- insert `<Tab>`: accept popup completion if visible.
- insert `<C-J>`: target mapping for accepting a Copilot suggestion.
- insert `<C-p>`: signature request.
- terminal `<Esc>`: leave terminal mode.
- `<Leader><Leader>`: live grep.
- `<Leader>G`: live grep Go files.
- `<Leader>F`: live grep frontend files.
- `<Leader>.`: resume last fzf picker.
- `<Leader>/`: grep current buffer.
- `<Leader>?`: keymaps.
- `<Leader>a`: all pickers.
- `<Leader>b`: toggle blame.
- `<Leader>d`: Git diff.
- `<Leader>e`: focus or open file explorer.
- `<Leader>j`: jumps.
- `<Leader>m`: marks.
- `<Leader>p`: global picker.
- `<Leader>s`: run code or test.
- `<Leader>t`: toggle terminal.
- `<Leader>r`: toggle outline.
- `<Leader>q`: toggle quickfix.
- `]q`: next quickfix entry.
- `[q`: previous quickfix entry.
- `<Leader>oc`: toggle cursorline.
- `<Leader>od`: toggle diagnostics.
- `<Leader>of`: toggle folding.
- `<Leader>oh`: toggle search highlight.
- `<Leader>oi`: toggle dynamic statusline info.
- `<Leader>ol`: toggle list chars.
- `<Leader>on`: toggle line numbers.
- `<Leader>or`: toggle relative numbers.
- `<Leader>os`: toggle spell check.
- `<Leader>ow`: toggle word wrap.

## External Dependencies

The target Dockerfile installs or expects:

- `neovim`
- `tree-sitter-cli`
- `ripgrep`
- `fd`
- `fzf`
- `git`
- `gopls`
- `lazygit`
  - Configured by inline Dockerfile YAML at `/root/.config/lazygit/config.yml`
    with:
    - `delta --dark --paging=never` for diffs.
    - Startup popups, random tips, command log, and mouse capture disabled.
    - Background fetch/update behavior disabled.
    - `notARepository: quit`.
- Node and npm
- `typescript`
- `@tailwindcss/language-server`
- `bash-language-server`
- `dockerfile-language-server-nodejs`
- `typescript-language-server`
- `vscode-langservers-extracted`
- `yaml-language-server`
- `lua-language-server`
- `terraform-ls`

Copilot also requires Node.js and npm. Current `dev/Dockerfile` already installs
Node through nvm; keep that path unless we intentionally simplify the image.

## Likely Drop Or Defer Candidates

Explicitly omit:

- `autosave.lua`: surprising write behavior.
- `bufferline.nvim`: replaced by `mini.tabline`.
- `scratch.lua` and `dev/scratches`: useful but depends on `/opt/scratches`.
- `nvim-tree/nvim-web-devicons`: replaced by `mini.icons` plus
  `MiniIcons.mock_nvim_web_devicons()`.
- `nvim-treesitter/nvim-treesitter-context`: removed by decision.
- `render-markdown.nvim`: removed by decision.
- `tpope/vim-fugitive`: replaced by Gitsigns for configured Git behavior.
- `miikanissi/modus-themes.nvim`: replaced by Tokyonight.

Drop or defer unless explicitly wanted:

- `runner.lua`: narrow Go/JavaScript/Bash runner.
- `quicker.nvim`: optional quickfix polish.
- Caddyfile parser/query support: keep only if Caddyfiles are common.
- Terraform/HCL LSP/parser support: keep only if Terraform is common.

## Proposed Step-By-Step Import

Use this order so every step can be reviewed as a small diff. Keep dependency
changes separate from Neovim Lua behavior.

1. Docker: Neovim runtime and language tooling. Completed in `dev/Dockerfile`.
   - Add `neovim`.
   - Add `tree-sitter-cli`.
   - Add npm-based servers as an alphabetized group:
     - `@tailwindcss/language-server`
     - `bash-language-server`
     - `dockerfile-language-server-nodejs`
     - `typescript-language-server`
     - `vscode-langservers-extracted`
     - `yaml-language-server`
   - Keep existing `gopls`.
   - Add `lua-language-server` from the LuaLS GitHub release tarball.
   - Add `terraform-ls` from HashiCorp's official apt repo using the supported
     `trixie` codename.
   - Do not install `marksman`.
   - Do not copy any Neovim config yet.
   - Verify `nvim --version`.
   - Verify `tree-sitter --version`.
   - Verify the kept LSP binaries are on `PATH`.

2. Remove VS Code web/editor and default to shell. Completed in `dev/Dockerfile`
   and `dev/.bashrc`.
   - Remove `nginx`.
   - Remove the Microsoft VS Code apt repo and `code` install.
   - Remove VS Code server directory creation, `code serve-web` prewarm, and
     extension installation.
   - Do not create `/workspace`; it is provided by the runtime mount.
   - Keep `vscode-langservers-extracted`.
   - Update Codex to `@openai/codex@0.141.0`.
   - Remove `dev/entrypoint.sh`.
   - Remove custom `ENTRYPOINT`; use `CMD ["/bin/bash", "--login"]`.
   - Keep runtime shell setup in `dev/.bashrc`.

3. Shell aliases and defaults.
   - Keep `EDITOR=vim` for now.
   - Add color aliases for `ls` and `grep` in `dev/.bashrc`.
   - Keep `cat` and `MANPAGER` backed by `bat`.
   - Defer `NVIM_SOCKET` and the interactive `nvim --listen` wrapper until
     after the next config steps.
   - Do not make the container entrypoint launch Neovim by default.
   - Do not put `nvim --listen ...` directly in `$EDITOR`.

4. Copilot credential mount and zsh launcher cleanup.
   - Remove the obsolete `.zshrc` `codesrv()` launcher.
   - Keep `.zshrc` `dev()` using the Dockerfile default
     `CMD ["/bin/bash", "--login"]`; do not override the entrypoint.
   - Create host `~/.codex` in `.zshrc` `dev()` before mounting it.
   - Create host `~/.config/github-copilot` in `.zshrc` `dev()`.
   - Mount it to `/root/.config/github-copilot` in `.zshrc` `dev()`.
   - Mount only that directory; do not mount host `~/.config` over
     `/root/.config`, because that can hide `/root/.config/nvim`.

5. Create single-file Neovim config with core options first. Completed in
   `.config/nvim/init.lua`.
   - Inlined the former `config/options.lua` body directly into `init.lua`.
   - Do not use `local M = {}`, `M.setup()`, `return M`, or `require(...)`.
   - Reviewed leader keys, mouse, swap/undo, wrapping, list chars, line
     numbers, split behavior, search, folds, indentation, completion options,
     netrw disabling, and readonly autocmds line by line.
   - Keep `vim.g` globals sorted alphabetically by global name.
   - Keep `vim.o` option assignments sorted alphabetically by option name.
   - Keep `vim.opt` mutations in their own sorted block.
   - Changed `textwidth` from `120` to `100`.
   - Keep `colorcolumn = '+1'`, word wrap, linebreak, and breakindent enabled.
   - Keep `shell = '/bin/bash'`.
   - Use static readonly autocmd patterns:
     - `/go/pkg/mod/**`
     - `*/node_modules/**`
     - `/usr/lib/go/**`
     - `/usr/lib/go-*/**`
     - `/usr/share/nvim/runtime/**`

6. Append plugin declarations to `.config/nvim/init.lua`. Completed in
   `.config/nvim/init.lua`.
   - Use Neovim 0.12 native `vim.pack.add`.
   - Use `confirm = false`.
   - Do not set `load`.
   - Add `folke/tokyonight.nvim`.
   - Add `lewis6991/gitsigns.nvim`.
   - Add `github/copilot.vim`.
   - Add `nvim-mini/mini.nvim` as the only Mini dependency.
   - Remove the separate `nvim-mini/mini.*` plugin declarations.
   - Omit `miikanissi/modus-themes.nvim`.
   - Omit `MeanderingProgrammer/render-markdown.nvim`.
   - Omit `tpope/vim-fugitive`.
   - Omit `akinsho/bufferline.nvim`; use `mini.tabline` later instead.
   - Omit `nvim-tree/nvim-web-devicons`; use `mini.icons` plus
     `MiniIcons.mock_nvim_web_devicons()` later instead.
   - Omit `nvim-treesitter/nvim-treesitter-context`.
   - Let `nvim-treesitter/nvim-treesitter` track its default branch.

7. Append theme setup to `.config/nvim/init.lua`. Completed in
   `.config/nvim/init.lua`.
   - Add a `-- Colorscheme` comment before the theme block.
   - Configure Tokyonight normally with one-line setup:
     `require('tokyonight').setup({ style = 'night' })`.
   - Load it with `vim.cmd.colorscheme('tokyonight')`.
   - Do not add Tokyonight custom `on_colors`, `on_highlights`, or transparency
     overrides.
   - Leave default Tokyonight italics, sidebar, float, terminal color, dimming,
     and cache behavior unchanged for now.
   - Defer Copilot `<Tab>` behavior until the completion/keymap step.
   - Defer detailed UI setup until later.

8. Append independent plugin foundation setup to `.config/nvim/init.lua`.
   Completed in `.config/nvim/init.lua`.
   - Configure `mini.icons` before any plugin expects icon support.
   - Call `MiniIcons.mock_nvim_web_devicons()` so `nvim-tree` can use icons
     without `nvim-tree/nvim-web-devicons`.
   - Call `MiniIcons.tweak_lsp_kind('replace')` before LSP/UI code displays
     LSP kinds.
   - Configure `mini.pairs`.
   - Configure `mini.bufremove` so later buffer-close mappings can use it.
   - Configure `flash.nvim` with defaults.
   - Defer Flash behavior changes and mappings to the keymap review step.
   - Do not configure `mini.completion` here; review it together with Copilot
     insert-mode behavior.
   - Do not configure `mini.statusline`, `mini.tabline`, `fzf-lua`,
     `nvim-tree`, Aerial, Quicker, or Gitsigns here.

9. Append Treesitter setup to `.config/nvim/init.lua`. Completed in
   `.config/nvim/init.lua`.
   - Inline the former `config/treesitter.lua` behavior.
   - Parser list is the source list minus `caddy` and `http`.
   - Keep `sql`; SQL editing is useful.
   - Install parsers with `require('nvim-treesitter').install(...):wait()`.
   - Import the Treesitter `FileType` autocmd here.
   - Remove `require('render-markdown').setup({})`.
   - Do not import `treesitter-context`.
   - Defer Caddy filetype detection and Caddy query files.
   - Import non-Caddy custom query files in the next step.

10. Import non-Caddy Treesitter query overrides. Completed under
    `.config/nvim/queries`.
    - Import Dockerfile Bash injection query.
    - Import Go template HTML injection query.
    - Import HCL Bash heredoc injection query.
    - Import Markdown fenced code block injection query.
    - Import YAML Bash block scalar injection query.
    - Do not import `queries/caddyfile/*` yet.

11. Append LSP setup to `.config/nvim/init.lua`. Completed in
    `.config/nvim/init.lua`.
    - Enable installed servers only.
    - Omit `marksman`.
    - Disable diagnostic signs only; keep other diagnostic display defaults.
    - Disable diagnostics on `InsertEnter`.
    - Re-enable diagnostics on `InsertLeave`.
    - Configure `lua_ls` for Neovim Lua development with LuaJIT, Neovim-style
      module paths, disabled third-party prompts, and `vim.env.VIMRUNTIME`.
    - Defer organize-imports/format helpers.
    - Defer rename overrides.
    - Defer state helpers.
    - Defer LSP keymaps.

12. Append completion and Copilot insert behavior to `.config/nvim/init.lua`.
    - Inline the former `config/completion.lua` behavior.
    - Configure `mini.completion` from `nvim-mini/mini.nvim`.
    - Review custom signature-help rendering line by line.
    - Import the `ConfigSignature` autocmds here.
    - Review Copilot `<Tab>` behavior in this same step.
    - Do not set `vim.g.copilot_no_tab_map = true` unless the keymap review
      changes direction.

13. Append workspace state, Git helpers, and search to `.config/nvim/init.lua`.
    - Inline only the needed behavior from former `config/state.lua` and
      `config/search.lua`.
    - Replace Fugitive helpers with git CLI or Gitsigns-backed behavior.
    - Use git CLI fallbacks for project name, worktree, and branch where needed.
    - Keep workspace-aware fzf behavior.
    - Configure `fzf-lua` picker UI and actions after state helpers exist.

14. Append Git signs, statusline, and tabline to `.config/nvim/init.lua`.
    - Configure `gitsigns.setup()`.
    - Replace Fugitive branch/statusline helpers with Gitsigns variables plus
      git CLI fallbacks where needed.
    - Configure `mini.statusline`.
    - Configure `mini.tabline` instead of Bufferline.
    - Use Gitsigns status variables where attached.

15. Append file explorer, symbols, and quickfix UI to `.config/nvim/init.lua`.
    - Configure `nvim-tree` after `mini.icons` has mocked `nvim-web-devicons`.
    - Configure Aerial.
    - Decide whether to keep or defer Quicker.
    - Import Aerial and nvim-tree autocmds only after their setup blocks exist.

16. Append terminal behavior to `.config/nvim/init.lua`.
    - Inline the former `config/terminal.lua` behavior.
    - Import terminal autocmds here.
    - Keep terminal statusline and auto-insert behavior only if it still fits
      the single-file layout.

17. Append fixed layout behavior to `.config/nvim/init.lua`.
    - Create or focus a left Codex terminal pane.
    - Keep the editor pane near 100 columns where terminal width permits.
    - Configure nvim-tree on the right.
    - Place Aerial below nvim-tree rather than as a competing right-edge pane.
    - Use `winfixwidth` and `winfixheight` for side panes.
    - Add a resize autocmd or fallback behavior for narrow terminals.

18. Append keymaps to `.config/nvim/init.lua`.
    - Import late because mappings wire together prior sections.
    - Prune features before adding mappings.
    - Do not import the old `ConfigSearchMaps` autocmd for `<CR>` and
      `<S-CR>` search navigation.
    - Remove `<Leader>n` scratch mapping.
    - Remove treesitter-context mappings `[c]` and `<Leader>ot`.
    - Add Copilot accept mapping, likely insert-mode `<C-J>`.
    - Replace Fugitive blame/diff mappings with Gitsigns equivalents.
    - Decide whether to add hunk mappings for preview, stage, reset, and
      navigation or keep parity with the old mappings only.

19. Optional workflow code.
    - Review former `config/runner.lua` separately and probably defer initially.
    - Do not import former `config/autosave.lua`.
    - Do not import former `config/scratch.lua`.
    - Do not import `dev/scratches`.

20. Docker: copy and prewarm config. Completed in `dev/Dockerfile`.
    - Copy `.config/nvim` into `/root/.config/nvim`.
    - Run `nvim --headless "+qa"` during build.
    - Do not reintroduce VS Code web/editor setup.

21. Interactive verification.
    - Start the container shell.
    - After socket support exists, start `nvim` and confirm it listens on
      `$NVIM_SOCKET`.
    - Run `:Copilot setup` once after the credential mount exists.
    - Run `:Copilot status`.
    - Confirm Gitsigns signs, blame, and diff behavior in a git repo.
    - Confirm the fixed layout at normal and narrow terminal widths.

## References

- Tokyonight: https://github.com/folke/tokyonight.nvim
- Gitsigns: https://github.com/lewis6991/gitsigns.nvim
- Copilot.vim: https://github.com/github/copilot.vim
- Neovim `--listen`: https://neovim.io/doc/user/starting/#--listen
- Neovim RPC/socket security note: https://neovim.io/doc/user/api/#rpc-connecting

## Open Decisions

- Should the Codex left pane auto-run `codex`, or open a shell intended for
  manual `codex` use?
- Should Gitsigns get full hunk mappings, or only old Fugitive parity mappings?
- Should Copilot use its default `npx` language server behavior, or pin/use the
  bundled server with `vim.g.copilot_version = false`?
- Which LSP servers should be kept for the actual work done in this repo?
- Should treesitter be pinned to the old commit or allowed to track latest?
