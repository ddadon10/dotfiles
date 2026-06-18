# Neovim Import Notes

Source branch: `nvim`

Current branch during cataloging: `add-neovim`

The Neovim config on the source branch lives under:

- `dev/nvim`

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
  - Use `colorscheme tokyonight-night`.
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
  - Keep the imported Lua config in a single `dev/nvim/init.lua`.
  - Append one reviewed section at a time.
  - Do not create `dev/nvim/lua/config/*.lua` modules.
  - Query overrides are the exception and still live under `dev/nvim/queries`.

## Plugin Inventory

Plugin manager:

- `nvim-mini/mini.deps`: bootstrapped automatically into Neovim data path.

Configured plugins:

- `akinsho/bufferline.nvim`: buffer tabs.
- `folke/flash.nvim`: jump/navigation motions.
- `folke/tokyonight.nvim`: colorscheme.
- `github/copilot.vim`: GitHub Copilot inline suggestions.
- `ibhagwan/fzf-lua`: files, grep, LSP pickers, keymaps, jumps, marks.
- `lewis6991/gitsigns.nvim`: Git signs, hunks, diff, and blame.
- `neovim/nvim-lspconfig`: LSP server definitions.
- `nvim-mini/mini.bufremove`: safer buffer deletion.
- `nvim-mini/mini.completion`: completion engine.
- `nvim-mini/mini.icons`: icon support.
- `nvim-mini/mini.pairs`: auto-pairs.
- `nvim-mini/mini.statusline`: statusline backend.
- `nvim-tree/nvim-tree.lua`: file explorer.
- `nvim-tree/nvim-web-devicons`: file icons.
- `nvim-treesitter/nvim-treesitter`: syntax, indent, folds; pinned to `90cd6580`.
- `nvim-treesitter/nvim-treesitter-context`: sticky code context.
- `stevearc/aerial.nvim`: symbols outline.
- `stevearc/quicker.nvim`: quickfix UI.

Source branch plugins intentionally removed from the target:

- `MeanderingProgrammer/render-markdown.nvim`.
- `miikanissi/modus-themes.nvim`.
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

- Diagnostics use underline only.
- Diagnostic signs are disabled.
- Virtual text diagnostics are disabled.
- Diagnostics are disabled while typing and re-enabled on insert leave.
- Rename triggers `wall` afterward.
- `<Leader>f` organizes imports and formats.
- `<Leader>w` organizes imports, formats, and saves all.

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

Auto-installs parsers into the MiniDeps package path.

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
- Configures `treesitter-context`.

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
- Bufferline configured with nvim-tree offset.
- `nvim-web-devicons` plus `mini.icons`.
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
- `[c`: go to treesitter context.
- `<Leader>oc`: toggle cursorline.
- `<Leader>od`: toggle diagnostics.
- `<Leader>of`: toggle folding.
- `<Leader>oh`: toggle search highlight.
- `<Leader>oi`: toggle dynamic statusline info.
- `<Leader>ol`: toggle list chars.
- `<Leader>on`: toggle line numbers.
- `<Leader>or`: toggle relative numbers.
- `<Leader>os`: toggle spell check.
- `<Leader>ot`: toggle treesitter context.
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
- `scratch.lua` and `dev/scratches`: useful but depends on `/opt/scratches`.
- `render-markdown.nvim`: removed by decision.
- `tpope/vim-fugitive`: replaced by Gitsigns for configured Git behavior.
- `miikanissi/modus-themes.nvim`: replaced by Tokyonight.

Drop or defer unless explicitly wanted:

- `runner.lua`: narrow Go/JavaScript/Bash runner.
- `bufferline.nvim`: cosmetic and workflow-specific.
- `quicker.nvim`: optional quickfix polish.
- Caddyfile parser/query support: keep only if Caddyfiles are common.
- Terraform/HCL LSP/parser support: keep only if Terraform is common.
- `treesitter-context`: useful but visual noise for some workflows.

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
   `dev/nvim/init.lua`.
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

6. Append plugin bootstrap and declarations to `dev/nvim/init.lua`.
   - Inline the former `config/bootstrap.lua` behavior in a clearly separated
     section.
   - Inline the former `config/plugins.lua` plugin declarations after bootstrap.
   - Add `folke/tokyonight.nvim`.
   - Add `lewis6991/gitsigns.nvim`.
   - Add `github/copilot.vim`.
   - Omit `miikanissi/modus-themes.nvim`.
   - Omit `MeanderingProgrammer/render-markdown.nvim`.
   - Omit `tpope/vim-fugitive`.
   - Keep `nvim-treesitter/nvim-treesitter` pinned to `90cd6580` until the
     Treesitter step decides otherwise.

7. Append theme and global plugin flags to `dev/nvim/init.lua`.
   - Set `vim.g.copilot_no_tab_map = true` before Copilot can map `<Tab>`.
   - Use `colorscheme tokyonight-night`.
   - Do not add Tokyonight custom `on_colors`, `on_highlights`, or transparency
     overrides.
   - Defer detailed UI setup until later.

8. Append completion setup to `dev/nvim/init.lua`.
   - Inline the former `config/completion.lua` behavior.
   - Keep Mini completion on `<Tab>`.
   - Review custom signature-help rendering line by line.

9. Append Treesitter setup to `dev/nvim/init.lua`.
   - Inline the former `config/treesitter.lua` behavior.
   - Review the parser list one language at a time.
   - Remove `require('render-markdown').setup({})`.
   - Drop specialized parsers if not useful, especially Caddy, Terraform/HCL,
     SQL, and HTTP.

10. Append LSP setup to `dev/nvim/init.lua`.
    - Inline the former `config/lsp.lua` behavior.
    - Review enabled servers against the Docker-installed binaries.
    - Only enable servers that are installed and useful.

11. Append workspace state, Git helpers, and search to `dev/nvim/init.lua`.
    - Inline only the needed behavior from former `config/state.lua` and
      `config/search.lua`.
    - Replace Fugitive helpers with git CLI or Gitsigns-backed behavior.
    - Use git CLI fallbacks for project name, worktree, and branch where needed.
    - Keep workspace-aware fzf behavior.

12. Append UI, statusline, and Git signs to `dev/nvim/init.lua`.
    - Inline the former `config/ui.lua` and `config/statusline.lua` behavior
      after pruning.
    - Configure `gitsigns.setup()`.
    - Use Gitsigns status variables where attached.
    - Strong candidates to remove or defer here:
      - `bufferline.nvim`
      - `quicker.nvim`

13. Append terminal behavior to `dev/nvim/init.lua`.
    - Inline the former `config/terminal.lua` behavior.
    - Keep terminal statusline and auto-insert behavior only if it still fits
      the single-file layout.

14. Append fixed layout behavior to `dev/nvim/init.lua`.
    - Create or focus a left Codex terminal pane.
    - Keep the editor pane near 100 columns where terminal width permits.
    - Configure nvim-tree on the right.
    - Place Aerial below nvim-tree rather than as a competing right-edge pane.
    - Use `winfixwidth` and `winfixheight` for side panes.
    - Add a resize autocmd or fallback behavior for narrow terminals.

15. Append keymaps to `dev/nvim/init.lua`.
    - Import late because mappings wire together prior sections.
    - Prune features before adding mappings.
    - Remove `<Leader>n` scratch mapping.
    - Add Copilot accept mapping, likely insert-mode `<C-J>`.
    - Replace Fugitive blame/diff mappings with Gitsigns equivalents.
    - Decide whether to add hunk mappings for preview, stage, reset, and
      navigation or keep parity with the old mappings only.

16. Optional workflow code.
    - Review former `config/runner.lua` separately and probably defer initially.
    - Do not import former `config/autosave.lua`.
    - Do not import former `config/scratch.lua`.
    - Do not import `dev/scratches`.

17. Query overrides.
    - Import under `dev/nvim/queries`.
    - Review last.
    - Import only query files for languages we keep.

18. Docker: copy and prewarm config.
    - Copy `dev/nvim` into `/root/.config/nvim`.
    - Run `nvim --headless "+qa"` during build only after `init.lua` is
      coherent.
    - Do not reintroduce VS Code web/editor setup.

19. Interactive verification.
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
