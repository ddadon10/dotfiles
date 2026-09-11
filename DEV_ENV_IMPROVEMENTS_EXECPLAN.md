# DEV_ENV_IMPROVEMENTS ExecPlan

## Purpose and Context

This task improves the development image and replaces the repository's ad hoc Neovim mappings with a compact,
contextual, Mini Clue-discoverable command graph. The observable result is:

- The Debian package list contains exactly one entry each for `npm`, `python3-venv`, and `yarnpkg`.
- Runtime npm installs reject dependency releases newer than three days through `min-release-age = 3`.
- `gcheckout` is removed from both tracked shell environments and their guidance text.
- JSON and JSONC continue to use the existing `jsonls`; formatting is exposed through the common `\f` mapping and
  verified with a real attached JSON buffer.
- Neovim uses three discoverable roots: `g` for cursor-dependent actions, literal `<Space>` for search/pickers, and
  backslash leader for general actions and noun groups.
- The flat Space picker layer includes direct common Fzf Lua pickers plus a `<Space>g` Git-search subgroup.
- Gitsigns actions live only in relevant buffers under `\g`; the blame drawer is a same-key `\gb` toggle and
  `\bd` closes the current ordinary buffer or special panel.
- Panels use `\p`: Explorer, Aerial outline, and one reusable shell terminal. The redundant Codex launcher and state
  are absent. Quickfix uses direct `\q` for toggling and `<Space>q` for selecting entries.
- NvimTree has no inherited plugin defaults. Its buffer-local mappings treat the selected Explorer node as the noun
  and expose mnemonic actions and small Open/Clipboard groups through Mini Clue.
- Mini Clue describes the project-owned `g`, literal-Space, and backslash families, including mappings added later by
  Gitsigns and NvimTree attachment, after a 250 ms delay.
- Bufferline replaces Mini Tabline with a Gruvbox-adaptive, VS Code-style adjacent-insertion buffer row, a blue active
  indicator, a modified marker, hover-revealed close controls, safe MiniBufremove-backed mouse closing, and a titled
  `File Explorer` offset matching the NvimTree sidebar. Literal `{`/`}` and discoverable `\bp`/`\bn` traverse its
  visual order; literal `|` closes through the same universal close action as `\bd`. It displays no LSP diagnostics.
- The statusline retains mode, Git, filename/status, filetype, line-ending format, indentation, and cursor location
  while omitting diagnostics/LSP state, search count, encoding, and buffer size. Git and metadata blocks use adaptive
  blue and purple backgrounds.
- Gitsigns blame uses a one-character author label. Existing split diffs become same-key toggles and close through
  `\bd`/`|` with complete diff-option cleanup; `\gi` adds an automatically dismissed inline hunk preview.
- Neovim's native right-click menu is not customized.

Relevant repository state:

- Branch `20260911-improvement` was clean at commit `cfe0dba` when approved follow-up implementation began.
  Milestones 1–6 are implemented in the six local commits ending at `0708952`; the later plan commits resolve the
  follow-up design.
- `docker/Dockerfile` uses Debian trixie and contains exactly one package entry each for `npm`, `python3-venv`, and
  `yarnpkg`.
- `.npmrc` is copied to `/root/.npmrc` by the development image.
- Neither tracked shell environment defines or advertises `gcheckout`.
- Neovim configuration remains a single tracked file, `.config/nvim/init.lua`. It now installs and configures Fzf
  Lua, Gitsigns, Mini.nvim, NvimTree, Aerial, Quicker, Bufferline, and the required LSP dependencies. Bufferline is the
  sole tabline implementation and Mini Icons supplies its devicons-compatible API.
- Both leader variables are backslash; the global and contextual keymap graph, Mini Clue, custom NvimTree maps,
  Gitsigns maps, Aerial toggle, and JSON formatting have passed headless behavioral fixtures.
- The installed exploration environment has Neovim 0.12.4, npm 11.16.0,
  `vscode-langservers-extracted` 4.10.0, Fzf Lua
  `05e44d38de0a79c11fba5f7bf8138791b1dbdd1e`, Gitsigns
  `5be654f2232c10ddcad19c1607a67b6b4b78fc29`, Mini.nvim
  `9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a`, NvimTree
  `b2aadda94b107480c48e548d6db51c6840b7b33c`, and Aerial
  `28fe6e822ae344544c379d60fcb13c9519a1f08a`. Bufferline exploration used upstream commit
  `655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3`.

Assumptions and boundaries:

- The requested npm setting means npm's documented relative-age key `min-release-age`, whose unit is days;
  `min-release-date` is not an npm v11 key.
- Change both leader variables to a literal backslash. Every search mapping must use an explicit `<Space>` left-hand
  side after that change; it must not use `<Leader>`.
- The project intentionally does not preserve Neovim defaults. It does preserve the selected direct editing
  primitives `d`, `s`/`S`, `<A-h/j/k/l>`, Visual `<D-c>`, and command-line `<CR>`.
- Keep `qq`, project `[q`/`]q`, and `+` absent. Use literal `{`/`}` as fast previous/next visual Bufferline actions
  and literal `|` as an alias of universal close. Leave `[`/`]` free for Neovim's bracket-prefixed mappings.
- Keep direct global `\c` Comment and `\x` Save-all-and-quit stable inside NvimTree. NvimTree clipboard actions
  therefore live under `\y`. Contextual NvimTree `\s` intentionally shadows Save because the Explorer scratch
  buffer cannot meaningfully be written.
- Do not map Gitsigns whole-buffer reset, hunk selection, stage-buffer, or display toggles. The balanced trim exposes
  the original twelve actions plus the later-approved `\gi` inline hunk preview.
- JSON formatting already works. Do not add `provideFormatter`, format-on-save, SchemaStore, or another formatter;
  the new `\f` mapping calls `vim.lsp.buf.format()` for any attached formatter.
- Bufferline must use `sort_by = 'insert_after_current'`; every next/previous action must use Bufferline cycle commands
  so navigation follows the visible order. Keep diagnostics disabled, the Mini Icons devicons mock, and JDT virtual
  filename behavior; add no separate devicons or statusline plugin.
- Use the corrected `{}`/`|` fast-key set: `{` is previous, `}` is next, and `|` is universal close. Keep the
  discoverable `\bp`/`\bn` aliases as well.
- Use the approved Layered Gruvbox theme: soft/base backgrounds for fill, inactive, and selected states; adaptive
  bright/faded blue for the active indicator and Explorer separator; and adaptive bright/faded orange for modified
  markers. Recompute it on `ColorScheme` for dark/light changes.
- Keep native split diffs. Add one small close helper and same-key Gitsigns toggles rather than a custom unified-diff
  buffer or Diffview dependency.
- Bufferline's per-buffer close click and right-click action must call MiniBufremove rather than its forced-delete
  defaults. Its hover interaction is a tabline mouse action, not native popup-menu customization.
- Do not customize native menus, add a context-menu plugin, preserve/redirect Neovim's original `gx` browser
  callback, or build a mouse-access keymap registry. Mini Clue is the only new discovery interface.
- Docker cannot run in this environment. Source-level checks run here; a real image build and executable smoke test
  remain downstream validation.
- Do not run `git pull` or `git push`. Stage only the ExecPlan and files named by the current milestone. Every Audit
  Log update must be committed locally with exactly the task changes it describes.

## Plan of Work

### Milestone 1: Container packages, npm policy, and alias cleanup

Affected files and interfaces:

- `docker/Dockerfile`: the first `apt-get install --yes --no-install-recommends` package list.
- `.npmrc`: npm CLI configuration copied to the image user's home.
- `docker/.bashrc`: development-container aliases.
- `.zshrc`: host-side Git client wrapper aliases and disabled-Git guidance.

Steps:

1. Keep the existing single `npm` entry in `docker/Dockerfile`, add `python3-venv` after `python3-pip`, and add
   `yarnpkg` after `xz-utils`. Do not add a duplicate npm entry, Yarn upstream repository, Corepack configuration,
   or `yarn` symlink.
2. Add `min-release-age = 3` to `.npmrc` using its existing `key = value` style. Do not reorder the Dockerfile
   copy: this policy governs interactive/runtime dependency resolution, not earlier global-install layers.
3. Remove `alias gcheckout='git checkout'` from `docker/.bashrc`.
4. Remove `alias gcheckout='_gitclient checkout'` from `.zshrc` and remove `gcheckout, ` from its disabled-Git
   error message.
5. Validate the milestone once:
   - `npm --userconfig /workspace/.npmrc config get min-release-age` prints `3`.
   - `bash -n docker/.bashrc` exits zero.
   - `rg -n 'gcheckout' docker/.bashrc .zshrc` returns no matches.
   - A static apt-block check reports exactly one `npm`, one `python3-venv`, and one `yarnpkg`, in stable order.
   - Record `zsh -n .zshrc` as a downstream check because zsh is not installed here.
   - Do not run `build.sh`; it invokes Docker and pushes images.
6. Update Progress, Findings and Decisions, and Audit Log with exact results. Stage only this ExecPlan,
   `docker/Dockerfile`, `.npmrc`, `docker/.bashrc`, and `.zshrc`, then create a local commit such as
   `Configure development package tooling` with a validation summary in its body.

Expected result: the next image build requests all three packages once, npm reports a three-day minimum release age,
and neither shell defines or advertises `gcheckout`.

Recovery: before the milestone commit, restore only failed edits with `apply_patch`. After commit, use
`git revert <milestone-commit>` to back out the whole milestone without resetting unrelated work. If a later image
build cannot resolve a package, verify the pinned Debian base and apt sources before changing names or repositories.

### Milestone 2: Three-root global keymap graph, panels, and Mini Clue

Affected file and interfaces:

- `.config/nvim/init.lua`: leader variables, global project keymaps, Mini Clue setup, panel toggles, and keymap
  descriptions.
- Fzf Lua picker functions, Neovim's native Comment/LSP format functions, MiniBufremove, NvimTree's tree toggle,
  Quicker's toggle, Aerial's `:AerialToggle!`, and Mini Clue triggers/clues.

Steps:

1. Change both `vim.g.mapleader` and `vim.g.maplocalleader` to `'\\'`.
2. Preserve and complete the cursor-dependent `g` family:

   | Mapping | Modes | Action |
   | --- | --- | --- |
   | `ga` | Normal, Visual | Fzf LSP code actions |
   | `gd` | Normal | Fzf LSP definitions |
   | `ge` / `gE` | Normal | Next/previous diagnostic with float |
   | `gh` | Normal | LSP hover |
   | `gi` | Normal | Fzf LSP implementations |
   | `gl` | Normal | Toggle document-symbol highlight |
   | `gp` | Normal | Peek definition without single-result auto-jump |
   | `gt` | Normal | Fzf LSP type definitions |
   | `gu` | Normal | Fzf LSP references/usages |
   | `gw` | Normal | Fzf grep word under cursor |
   | `gx` | Normal | LSP rename |

3. Convert the Search surface to literal-Space mappings and implement the selected flat layer:

   | Mapping | Modes | Fzf Lua action |
   | --- | --- | --- |
   | `<Space><Space>` | Normal / Visual | `live_grep()` / `grep_visual()` |
   | `<Space>.` | Normal | `resume()` |
   | `<Space>?` | Normal | `keymaps()` |
   | `<Space>a` | Normal | `builtin()`, the complete picker catalog |
   | `<Space>b` | Normal | `buffers()` |
   | `<Space>c` | Normal | `commands()` |
   | `<Space>d` | Normal | `diagnostics_workspace()` |
   | `<Space>f` | Normal | `files()`, including untracked non-ignored files |
   | `<Space>h` | Normal | `helptags()` |
   | `<Space>j` | Normal | `jumps()` |
   | `<Space>m` | Normal | `marks()` |
   | `<Space>p` | Normal | `global()`, combining files/buffers/symbols |
   | `<Space>q` | Normal | `quickfix()` |
   | `<Space>r` | Normal | `history()`, including the current session |
   | `<Space>s` | Normal | `lgrep_curbuf()` |

4. Add the selected `<Space>g` Git-search subgroup:

   | Mapping | Fzf Lua action |
   | --- | --- |
   | `<Space>gb` | `git_branches()` |
   | `<Space>gc` | `git_commits()` |
   | `<Space>gf` | `git_bcommits()`, current-file history |
   | `<Space>gh` | `git_hunks()` |
   | `<Space>gr` | `git_reflog()` |
   | `<Space>gs` | `git_status()` |
   | `<Space>gt` | `git_tags()` |
   | `<Space>gw` | `git_worktrees()` |

5. Install the direct general actions:
   - `\c` in Normal and Visual modes invokes Neovim's native line/selection comment behavior and has a Comment
     description. Use a remapping RHS so the built-in `gcc`/`gc` mappings execute.
   - `\f` in Normal and Visual modes calls `vim.lsp.buf.format()`; Visual mode relies on Neovim's selected-range
     default.
   - `\s` writes the current buffer.
   - `\x` writes all buffers and quits Neovim.
6. Install the balanced noun/action mappings:

   | Group | Mapping | Action |
   | --- | --- | --- |
   | Buffers | `\ba` | Alternate buffer |
   | Buffers | `\bd` | Close current buffer or special panel |
   | Buffers | `\bD` | Diff current buffer against an Fzf-selected buffer |
   | Buffers | `\bn` / `\bp` | Next/previous buffer |
   | Panels | `\pc` | Toggle Codex |
   | Panels | `\pe` | Toggle NvimTree Explorer |
   | Panels | `\po` | Toggle Aerial with `AerialToggle!` and preserve editor focus |
   | Panels | `\pt` | Toggle terminal |
   | Quickfix | `\q` | Toggle Quicker with focus |

   Implement `\bd` using the previously verified close rule: when the current buffer has non-empty `buftype` and
   the tab has another window, close the current window; otherwise call `MiniBufremove.delete()`. This is the
   universal current-buffer action and replaces `|`.
7. Remove the old project mappings `qq`, `[q`, `]q`, `+`, `{`, `|`, and `}`. Keep `d`, `s`/`S`,
   `<A-h/j/k/l>`, Visual `<D-c>`, and command-line `<CR>`; add
   `desc = 'Accept command and clear search highlight'` to the command-line mapping.
8. Configure Mini Clue with only the project roots:
   - `<Leader>` in Normal and Visual modes.
   - Literal `<Space>` in Normal and Visual modes.
   - `g` in Normal and Visual modes.
   - Explicit global group clues: `<Space>g = +Git search`, `<Leader>b = +Buffers`,
     `<Leader>g = +Git actions`, and `<Leader>p = +Panels`.
   - Do not add the old broad starter generators or triggers for brackets, completion, marks, registers, windows,
     `q`, or `z`; the user wants project mappings, not a catalog of Neovim defaults. Some built-in `g` maps may
     still appear because Mini Clue inspects every effective continuation and has no general exclusion filter.
9. Validate once after the related edits:
   - A headless map inventory reports the exact project leaves/descriptions, backslash leader, literal-Space mappings,
     and no removed mapping.
   - `qa` records macro `a` and `q` stops recording, proving removal of `qq` restored ordinary behavior.
   - `\c` comments/uncomments a normal line and a Visual range.
   - A temporary JSON buffer attaches `jsonls`; `\f` changes compact JSON into the expected four-space-indented
     output and no extra JSON configuration exists.
   - `\bd` preserves ordinary MiniBufremove semantics and closes a representative special split without `E1513`.
   - `\pc`, `\pe`, `\po`, `\pt`, and `\q` each open and close their target; Aerial retains source focus.
   - Mini Clue installs buffer-local trigger maps for all three roots without losing any continuation.
10. Record results in the ExecPlan and commit it with `.config/nvim/init.lua` as a local milestone commit such as
    `Reorganize Neovim keymaps`.

Expected result: global mappings have one discoverable semantic home, direct editing primitives remain fast, panels
toggle consistently, JSON formatting is available through `\f`, and Mini Clue teaches only the selected project graph.

Recovery: if the leader migration makes a mapping unreachable, inspect `maparg()` for the literal encoded left-hand
side before changing the design. If a Mini Clue trigger loses precedence to a later buffer-local map, keep the global
configuration and use `MiniClue.ensure_buf_triggers(bufnr)` in that plugin's attachment path. Revert the milestone
commit if the graph cannot be made internally consistent without changing the approved layout.

### Milestone 3: Contextual Gitsigns actions and blame closing

Affected file and interfaces:

- `.config/nvim/init.lua`: Gitsigns `setup({ on_attach = ... })`, a reusable blame-toggle callback, and
  `gitsigns-blame` buffer attachment.
- Gitsigns public hunk navigation, blame, diff, preview, stage/reset/undo, and quickfix APIs.
- Mini Clue's `ensure_buf_triggers(bufnr)`.

Steps:

1. Replace the simple Gitsigns setup with an `on_attach(bufnr)` callback that creates only buffer-local mappings with
   descriptions and does not leak them into non-Git buffers.
2. Install the selected balanced `\g` family:

   | Mapping | Modes | Gitsigns action |
   | --- | --- | --- |
   | `\gb` | Normal | Toggle the full blame drawer |
   | `\gd` | Normal | `diffthis()`, current file against index |
   | `\gD` | Normal | `diffthis('~')`, current file against previous commit |
   | `\gj` / `\gk` | Normal | Next/previous hunk |
   | `\gl` | Normal | Full blame for current line |
   | `\gp` | Normal | Popup preview of current hunk |
   | `\gq` | Normal | Put current-buffer hunks in quickfix |
   | `\gQ` | Normal | Put repository hunks in quickfix |
   | `\gr` | Normal, Visual | Reset current hunk or selected range |
   | `\gs` | Normal, Visual | Stage/unstage current hunk or selected range |
   | `\gu` | Normal | Undo the most recently staged hunk |

   Use explicit Visual line bounds for stage/reset as in the installed upstream example. Do not add `\gR`,
   `\gh`, `\gi`, `\gS`, or any `\gt...` display-toggle mappings.
3. Implement `\gb` as a true toggle:
   - Scan `vim.api.nvim_tabpage_list_wins(0)` for a window whose buffer has `filetype == 'gitsigns-blame'`.
   - If found, close that window with `vim.api.nvim_win_close(win, false)` and return.
   - Otherwise call `require('gitsigns').blame()`.
   - Reuse the callback from the Git source-buffer mapping and a `FileType gitsigns-blame` buffer-local mapping so
     the same key closes the drawer from either pane.
4. After each Gitsigns or blame-buffer mapping set is created, call `MiniClue.ensure_buf_triggers(bufnr)` if Mini
   Clue has already been initialized. This ordering is mandatory because Mini Clue triggers are buffer-local and must
   be the most recently installed mappings.
5. Run focused headless tests using a temporary Git fixture:
   - A tracked source buffer exposes all twelve selected actions and a non-Git buffer exposes none.
   - The source-buffer `\g` clue lists the selected leaves and does not list omitted actions.
   - Next/previous hunk, popup preview, diff, stage/reset/undo, blame-line, and both quickfix scopes invoke their
     intended public APIs; worktree/index mutations are restored within the disposable fixture.
   - Invoke `\gb`, wait for the drawer, focus the source, invoke it again, and assert the drawer closes and source
     `scrollbind`, `wrap`, and `foldenable` are restored.
   - Open blame again, focus its drawer, and prove both `\gb` and `\bd` close it without `E1513`.
6. Record exact results and commit the ExecPlan with `.config/nvim/init.lua` as a local milestone commit such as
   `Add contextual Gitsigns actions`.

Expected result: Git actions appear only where meaningful, Mini Clue exposes one focused `\g` vocabulary, and the
blame drawer closes from either pane with either its own toggle or the universal buffer-close action.

Recovery: if Gitsigns attaches before Mini Clue setup, allow the later global setup to create initial triggers and keep
the guarded ensure call for subsequent buffers. If drawer detection becomes ambiguous, restrict it to current-tab
windows with exactly the verified `gitsigns-blame` filetype. Revert the milestone commit rather than making the
approved Git group global.

### Milestone 4: Contextual NvimTree mapping replacement

Affected file and interfaces:

- `.config/nvim/init.lua`: NvimTree `on_attach(bufnr)` and its buffer-local Mini Clue configuration.
- NvimTree public node-open, filesystem, root, search, Git navigation, and diagnostic navigation APIs.
- Mini Clue's buffer-local `vim.b[bufnr].miniclue_config` and `ensure_buf_triggers(bufnr)`.

Steps:

1. Add a custom NvimTree `on_attach(bufnr)` and pass it to the existing setup. Never call
   `api.map.on_attach.default(bufnr)`; the explicit goal is zero inherited NvimTree mappings.
2. Use one inline local mapping closure inside `on_attach` to apply
   `{ buffer = bufnr, silent = true, desc = 'Explorer: ...' }`. Install the selected direct actions:

   | Mapping | Modes | NvimTree action |
   | --- | --- | --- |
   | `<CR>` / `<2-LeftMouse>` | Normal | Open file or toggle directory |
   | `\a` | Normal | Create file or directory |
   | `\d` | Normal, Visual | Delete selected node(s), with confirmation |
   | `\h` | Normal | Set selected directory or file parent as tree root |
   | `\i` | Normal | Show node information |
   | `\m` | Normal | Move by editing the absolute path via `api.fs.rename_full()` |
   | `\r` | Normal | Rename node by name |
   | `\R` | Normal | Refresh tree |
   | `\s` | Normal | Open the node-search dialogue |
   | `\u` | Normal | Move tree root to its parent |

3. Install the contextual subgroups:

   | Group | Mapping | NvimTree action |
   | --- | --- | --- |
   | Open | `\oh` | Open in horizontal split |
   | Open | `\op` | Open preview |
   | Open | `\ot` | Open in tab |
   | Open | `\ov` | Open in vertical split |
   | Clipboard | `\ya` | Copy absolute path to system clipboard |
   | Clipboard | `\yc` | Copy node(s) to NvimTree clipboard |
   | Clipboard | `\yf` | Copy filename to system clipboard |
   | Clipboard | `\yp` | Paste copied/cut nodes |
   | Clipboard | `\yr` | Copy tree-root-relative path to system clipboard |
   | Clipboard | `\yx` | Cut node(s) to NvimTree clipboard |
   | Git | `\gj` / `\gk` | Next/previous Git-status node |
   | Cursor | `ge` / `gE` | Next/previous diagnostic node |

   Use Normal and Visual modes for `\yc`, `\d`, and `\yx`; use Normal mode for the others. Do not add
   basename-only copy, `\oe`, trash, bookmarks, filters, system-open, arbitrary command, or expand-all mappings.
4. Set buffer-local group clues `<Leader>o = +Open` and `<Leader>y = +Clipboard` through
   `vim.b[bufnr].miniclue_config.clues`. Global `+Git actions` and the root `g` trigger remain applicable.
   Call `MiniClue.ensure_buf_triggers(bufnr)` after every NvimTree mapping and local clue is installed.
5. Keep global `\pe` as the sole Explorer toggle/close action. Do not add NvimTree `q`, `\q`, or another close
   mapping. Keep `\c` Comment and `\x` Save-all-and-quit unshadowed; only NvimTree `\s` contextually overrides
   global Save.
6. Validate through NvimTree's effective-map API and a real opened Explorer:
   - `api.map.keymap.current()` contains every selected mode/key/description and none of representative defaults
     `a`, `d`, `r`, `q`, `S`, `g?`, or `<C-v>`.
   - Mini Clue in the Explorer shows direct actions, `+Open`, `+Clipboard`, contextual Git navigation, and
     diagnostic navigation without losing the leader/Space/`g` triggers.
   - In a disposable filesystem fixture, create, rename, full-path move, delete, copy/cut/paste, path copy, search,
     root changes, refresh, and each open target behave as described. Do not delete or move repository files.
   - Double left click and `<CR>` open files/toggle directories; `\pe` closes and reopens Explorer.
   - Opening a normal buffer restores the global meanings of `\s`, `ge`/`gE`, and `\gj`/`\gk`.
7. Record exact results and commit the ExecPlan with `.config/nvim/init.lua` as a local milestone commit such as
   `Replace NvimTree default mappings`.

Expected result: Explorer exposes only the approved contextual vocabulary, all operations are described by Mini Clue,
and leaving the Explorer restores the global/source-buffer meanings without leaked mappings.

Recovery: if a NvimTree operation requires a missing mapping, add it only after confirming the public API and obtaining
user direction; do not restore the entire default set. If a trigger disappears, verify `ensure_buf_triggers(bufnr)`
runs last. If full-path rename is unsuitable as Move, stop and report the API limitation instead of inventing direct
filesystem mutation outside NvimTree.

### Milestone 5: Replace Mini Tabline with Bufferline

Affected file and interfaces:

- `.config/nvim/init.lua`: global mouse-movement option, `vim.pack.add()` plugin list, Gruvbox overrides, tabline
  setup, existing `jdt_info()` formatter, MiniBufremove, Mini Icons' devicons mock, and NvimTree sidebar integration.
- Bufferline's `setup({ options = ... })`, mouse-close callbacks, hover events, name formatter, modified marker, and
  sidebar-offset configuration.

Steps:

1. Add `https://github.com/akinsho/bufferline.nvim` to the alphabetically ordered `vim.pack.add()` list. This is the
   only new dependency; do not add `nvim-web-devicons` because the existing `MiniIcons.mock_nvim_web_devicons()`
   supplies the API Bufferline consumes.
2. Set `vim.o.mousemoveevent = true` with the other global options. The existing `vim.o.mouse = 'a'` remains in place;
   both are required for the requested hover behavior.
3. Remove the `require('mini.tabline').setup(...)` block and all seven `MiniTabline*` Gruvbox highlight overrides.
   Retain the Mini.nvim plugin and every other configured Mini module.
4. Configure Bufferline in the existing `-- Tabline` location with this exact behavior:

   ```lua
   require('bufferline').setup({
       options = {
           close_command = function(bufnr) MiniBufremove.delete(bufnr) end,
           diagnostics = false,
           hover = { enabled = true, delay = 200, reveal = { 'close' } },
           modified_icon = '●',
           name_formatter = function(buf) local info = jdt_info(buf.path); return info and info.filename end,
           offsets = {
               { filetype = 'NvimTree', separator = true },
           },
           right_mouse_command = function(bufnr) MiniBufremove.delete(bufnr) end,
           show_close_icon = false,
       },
   })
   ```

   Keep the offset area blank because NvimTree already has an `Explorer` winbar. Its width must be derived from the
   actual sidebar window, currently configured as 45 columns.
5. Omit Bufferline settings that only repeat the desired defaults: buffer mode, default style preset, thin
   separators, active-buffer indicator, file icons, always-visible row, and buffer-ID sorting. Do not add Bufferline
   mappings or change the approved `\b` mapping family. The stable default order deliberately keeps displayed order
   aligned with native `:bnext` and `:bprevious`.
6. Validate once after the related edits:
   - `nvim --headless -u /workspace/.config/nvim/init.lua '+qa'` exits zero and Bufferline owns the `tabline` option.
   - Static inspection finds one Bufferline plugin entry and setup, no Mini Tabline setup or `MiniTabline*` highlight,
     no new keymap, and no standalone devicons plugin.
   - Effective Bufferline options report `diagnostics = false`, hover close reveal at 200 ms, the `●` modified icon,
     safe function callbacks for close-click and right-click, hidden global close icon, and default buffer-ID sort.
   - A scratch modified buffer renders `●` without any LSP count or severity marker. A close callback against an
     unsaved scratch buffer requests confirmation and does not silently destroy it.
   - The existing Mini Icons mock returns an icon and color through `require('nvim-web-devicons')` before Bufferline
     renders; no new icon package is present.
   - A fake `jdt://contents/...` buffer renders the short class filename instead of its virtual URI.
   - Opening the real NvimTree produces a left offset equal to its 45-column live width; closing NvimTree returns the
     offset to zero.
   - In an interactive Neovim UI, an inactive unmodified buffer reveals its close icon after hover, the current
     unmodified buffer retains its close icon, and a modified buffer retains its modified marker. Confirm that clicking
     close or right-clicking a tab invokes safe MiniBufremove behavior.
7. Record exact results and commit the ExecPlan with `.config/nvim/init.lua` as a local milestone commit such as
   `Replace Mini Tabline with Bufferline`.

Expected result: Neovim presents a default-styled, VS Code-like row of buffers whose tabs start after the NvimTree
sidebar, expose close controls through hover and mouse actions, visibly mark unsaved files, retain stable navigation
order and JDT names, and contain no LSP diagnostics or new keyboard interface.

Recovery: if Bufferline cannot load or render with the Mini Icons mock, restore the removed Mini Tabline setup and
Gruvbox overrides, remove Bufferline and `mousemoveevent`, and revert the milestone commit. If only the interactive
hover check fails, first confirm the terminal forwards mouse-motion events before altering the approved configuration.

### Milestone 6: Final focused validation and handoff

Affected files:

- `DEV_ENV_IMPROVEMENTS_EXECPLAN.md` and all task files changed by prior milestones; no exploratory fixture should be
  committed.

Steps:

1. Reread the entire ExecPlan and inspect `git status --short`. Preserve unrelated user work.
2. Run each focused check once after all related edits:
   - `git diff --check`.
   - `bash -n docker/.bashrc`.
   - `npm --userconfig /workspace/.npmrc config get min-release-age` prints `3`.
   - `rg -n 'gcheckout' docker/.bashrc .zshrc` returns no matches.
   - A static apt-block check reports one occurrence each of `npm`, `python3-venv`, and `yarnpkg`.
   - `nvim --headless -u /workspace/.config/nvim/init.lua '+qa'` exits zero.
   - A static/effective map inventory confirms the exact approved global and contextual graph, no removed aliases,
     no NvimTree defaults, no omitted Gitsigns actions, and useful descriptions for every project mapping.
   - One consolidated Neovim scratch run covers Mini Clue roots/context, macro recording, Comment, JSON LSP formatting,
     all panel toggles, ordinary/special `\bd`, blame from both panes, selected Gitsigns actions, and NvimTree
     context isolation.
   - Bufferline is the sole tabline implementation, shows no diagnostics, renders its modified marker and JDT names,
     safely closes buffers through MiniBufremove, and tracks the live NvimTree width with its sidebar offset.
   - Perform the interactive Bufferline hover/click check from Milestone 5 in a terminal that forwards mouse movement.
3. Confirm all exploration scripts and disposable fixtures remain outside the repository and `git status --short`
   contains only intentional task state.
4. Update Progress, Findings and Decisions, and Audit Log with exact final evidence and deferred checks. Create a final
   local commit only if the audit entry covers uncommitted task changes. Never push.
5. Handoff reports local commits, focused validation results, the exploration journal path if it remains available,
   and the environment-limited downstream checks:
   - Run `zsh -n .zshrc` on a host with zsh.
   - Build the development image outside this container, then run `python3 -m venv /tmp/venv-smoke`,
     `npm --version`, and `yarnpkg --version` inside that disposable image.

Expected result: all source-level checks pass, the approved mappings are discoverable only in their intended contexts,
no experimental or unrelated files are committed, and only the genuine Docker/zsh checks remain deferred.

Recovery: fix only the milestone that owns a failed assertion and repeat its focused validation. Revert completed
milestones in reverse order if wholesale removal is required. Do not weaken an expected result to hide an environment
limitation.

### Milestone 7: Bufferline navigation, adaptive UI, and interaction cleanup

Affected file and interfaces:

- `.config/nvim/init.lua`: Bufferline options/highlights, NvimTree startup title, statusline content, terminal state,
  Gitsigns blame formatting, Mini Completion/Mini Keymap, project mappings, and Mini Clue window timing.
- Bufferline's visual sorter and cycle commands, Gruvbox's palette, MiniStatusline sections, Gitsigns
  `blame_formatter`, MiniKeymap's popup-menu steps, and MiniBufremove.

Steps:

1. Change Bufferline to `sort_by = 'insert_after_current'`, the closest available behavior to VS Code opening a new
   editor immediately after the active editor. Traverse that sorted row, rather than numeric buffer IDs:
   - Map Normal `{` to `:BufferLineCyclePrev` and `}` to `:BufferLineCycleNext`. Do not set `nowait`; braces are
     complete mappings and do not conflict with Neovim's longer bracket-prefixed mappings.
   - Change `\bp` and `\bn` to those same previous/next commands so the discoverable noun group agrees with the fast
     keys.
   - Map Normal `|` to the exact same callback as `\bd`; define the callback once because it is reused.
   - Do not add move/reorder mappings. This request is about navigating the VS Code-style order, not manually sorting
     it.
2. Change the NvimTree offset to
   `{ filetype = 'NvimTree', text = 'File Explorer', text_align = 'center', separator = true }`. Remove the separate
   `vim.wo.winbar = '%= Explorer %='` assignment after startup tree opening so only Bufferline owns the title.
3. Add a Bufferline `highlights = function()` callback that reads `require('gruvbox').palette` and
   `vim.o.background`. Bufferline re-evaluates this callback on `ColorScheme`, so the same mapping adapts to both
   variants:

   | Role | Dark | Light |
   | --- | --- | --- |
   | Row fill | `dark0_soft` (`#32302f`) | `light0_soft` (`#f2e5bc`) |
   | Inactive buffer | `dark1` (`#3c3836`) | `light1` (`#ebdbb2`) |
   | Selected buffer | `dark2` (`#504945`) | `light2` (`#d5c4a1`) |
   | Selected text | `light1` (`#ebdbb2`) | `dark1` (`#3c3836`) |
   | Inactive text | `gray` (`#928374`) | `gray` (`#928374`) |
   | Indicator/offset separator | `bright_blue` (`#83a598`) | `faded_blue` (`#076678`) |
   | Modified marker | `bright_orange` (`#fe8019`) | `faded_orange` (`#af3a03`) |

   Apply the state backgrounds consistently to buffer text, separators, close buttons, modified markers, and the
   selected indicator. Preserve the default thin separator/icon style, hover behavior, modified dot, and no-LSP
   diagnostics. Do not introduce black or hard-contrast backgrounds.
4. Preserve the current statusline's structure while replacing its diagnostics and bundled `section_fileinfo()` with
   the approved logical order:
   `mode | branch and Git counts | filename/status %= filetype | LF/CRLF | spaces:N/tabs:N | line:column`.
   - Keep the existing JDT filename handling and append `%m%r` so modified and read-only state remain visible.
   - Keep the existing compact Gitsigns branch/count function.
   - Preserve the current Mini Icons filetype icon beside `vim.bo.filetype`. Render `vim.bo.fileformat` as the clearer
     `LF` for `unix`, `CRLF` for `dos`, or `CR` for `mac`, then keep the existing indentation label and add `%l:%c`.
   - Keep the mode's existing mode-dependent highlight, give the Git block an adaptive Gruvbox blue background, keep
     the filename on a neutral Gruvbox background, and give the right metadata block an adaptive Gruvbox purple
     background. Use bright blue/purple with dark text in dark mode and faded blue/purple with light text in light
     mode.
   - Do not show search count, LSP/diagnostics, buffer size, encoding, raw `[unix]`/`[dos]`, total-line/column counts,
     or add another statusline dependency.
5. Set Gitsigns `blame_formatter` to a function that returns only the first Unicode character of
   `blame_info.author`, highlighted with `context.hash_hl_group`, and returns `false` as its second result to suppress
   repeated summary lines. Render `?` for `Not Committed Yet`; leave the renderer-owned graph and heatmap intact.
6. Remove only `toggle_codex()`, the `\pc` mapping, any live Codex buffer/window state, and the corresponding panel
   expectation. Keep the working generic `toggle_terminal_panel(name, title, command)` helper and the existing
   `toggle_terminal()` wrapper rather than restructuring them merely because they now have one caller. Retain the
   reusable shell-terminal buffer, bottom 16-line split, insert-mode behavior, and Terminal winbar.
7. Change `completeopt` from `menu,menuone,noinsert,fuzzy` to `menu,menuone,noselect,fuzzy`. Use the already installed
   Mini Keymap module to map Insert `<Tab>` with `{ 'pmenu_next' }` and `<S-Tab>` with `{ 'pmenu_prev' }`. When the
   completion popup is visible, the first Tab selects the first entry and further presses cycle; without a popup,
   Tab and Shift-Tab retain their literal fallback. Do not add a completion dependency or change Enter acceptance.
8. Add `window = { delay = 250 }` to Mini Clue. Keep its existing trigger and clue graph unchanged.
9. Validate once after the related edits:
   - Effective Bufferline options report adjacent insertion, and a four-buffer fixture proves `{`/`}` plus
     `\bp`/`\bn` visit the displayed order rather than buffer-ID order. `[`/`]` have no project mapping; `|` and `\bd`
     preserve modified-buffer safety and close representative special panels correctly.
   - A real NvimTree produces a 45-column `File Explorer` offset with no `Explorer` winbar.
   - Snapshot all overridden Bufferline highlight groups in dark and light modes; assert the table above, blue active
     indicator/offset separator, orange modified marker, and no black background. Restore the original background.
   - Statusline snapshots at wide/narrow widths show mode, Git, filename/status, icon/filetype, friendly line ending,
     indentation, and line:column in order. Dark/light highlight snapshots prove the blue Git and purple metadata
     backgrounds have readable contrasting text. Output contains no search count, diagnostics/LSP text, size,
     encoding, raw fileformat name, total-line/column counts, or invalid evaluation marker.
   - A disposable Git fixture confirms every committed author header is one character and an uncommitted line is `?`.
   - Static/effective map checks find no Codex callback, command, state, or `\pc`; the generic panel helper remains
     structurally unchanged and `\pt` still opens, hides, restores, and reuses the shell terminal.
   - A deterministic native completion fixture calls `vim.fn.complete()` with two fixed candidates, then confirms the
     menu initially has no selection, first Tab selects item zero, second Tab selects item one, and Shift-Tab reverses.
     With no popup, Tab inserts ordinary indentation. Do not start an LSP for this mapping-level test; production Mini
     Completion continues to populate the same native popup menu from attached LSP clients.
   - Mini Clue's effective delay is exactly 250 ms and its root/context inventory is otherwise unchanged.
10. Update Progress, Findings and Decisions, and Audit Log with exact results. Stage only this ExecPlan and
    `.config/nvim/init.lua`, then create a local commit such as `Refine Neovim navigation and UI`.

Expected result: Bufferline acts like an ordered editor-tab row and follows the current Gruvbox mode; Explorer has one
title; the statusline and blame drawer are compact; only the useful shell terminal remains; completion responds to Tab;
and project clues appear after 250 ms.

Recovery: if dynamic colors do not refresh, inspect Bufferline's `ColorScheme` callback and effective highlight
function before adding another autocmd. If `{`/`}` do not follow visual order, inspect their effective Bufferline
command before changing timeout settings. If Mini Keymap changes literal Tab fallback, use Mini
Completion's documented `pumvisible()` expression mappings with the same observed behavior.

### Milestone 8: Make native split diffs easy to close and add inline preview

Affected file and interfaces:

- `.config/nvim/init.lua`: one reusable diff-close callback, Gitsigns `\gd`/`\gD`/`\gi`, selected-buffer `\bD`, and
  the shared `\bd`/`|` universal close callback.
- Gitsigns `diffthis()` and `preview_hunk_inline()`, Neovim's `:diffoff!`, window-local `diff` option, and existing
  Fzf Lua selected-buffer split.

Steps:

1. Keep Gitsigns' native `diffthis()` splits and the existing selected-buffer split instead of building a custom
   listed unified-diff buffer or adding a dependency.
2. Add one small callback that closes the active diff layout:
   - Inspect only windows in the current tab whose window-local `diff` option is set.
   - If the focused diff window has a non-empty `buftype`, treat it generically as the comparison/special buffer and
     close the current window. Otherwise, preserve the current normal source window and close the other diff window
     or windows. Do not couple the helper to Gitsigns' current `acwrite`/`nowrite` implementation details or URI.
   - Run `:diffoff!` after closing comparison windows so diff, scroll/cursor binding, wrapping, fold, and related
     options are restored across the current tab.
   - Return whether a diff was closed so callers can toggle without duplicating window logic. Never use `:only`,
     because unrelated editor panels/splits must survive.
3. Change Gitsigns `\gd` and `\gD` to same-key toggles. If a diff is active in the current tab, either mapping closes
   it through the shared callback; otherwise they retain `diffthis()` against the index and `diffthis('~')` against
   the previous commit respectively. Gitsigns already returns focus to the source window, so the opening key remains
   immediately available for closing.
4. Teach the shared universal close callback used by `\bd` and `|` to invoke the diff-close callback first whenever
   the current window participates in a diff. If no diff is active, retain its existing special-window close and
   MiniBufremove behavior. This makes selected-buffer `\bD` and Gitsigns diffs closable from their normal source focus
   without deleting the source buffer.
5. Add buffer-local Gitsigns `\gi = preview_hunk_inline()` with description `Git: preview hunk inline`; retain
   `\gp` as popup preview. The inline preview needs no close mapping because Gitsigns clears it automatically on
   cursor movement, Insert entry, or leaving the buffer. Refresh the buffer's Mini Clue triggers after adding it.
6. Validate in a disposable two-commit Git fixture and ordinary scratch buffers:
   - `\gd` and `\gD` still open the correct index/previous-commit native split, keep source focus, and close on a
     second press without leaving any `diff`, `scrollbind`, `cursorbind`, or altered wrap/fold state.
   - With each Gitsigns split open, `\bd` and `|` close only the comparison window, retain the source buffer and every
     unrelated panel/split, and leave no diff-mode residue. Repeat for selected-buffer `\bD`.
   - Invoking close from a focused non-empty-`buftype` Gitsigns comparison pane closes that pane rather than the
     source, without matching an exact Gitsigns buffer type or name.
   - `\gi` renders added/deleted lines inline for the current hunk and clears on CursorMoved, InsertEnter, and
     BufLeave; `\gp` remains the popup preview.
   - The Gitsigns Mini Clue inventory contains the new `\gi` leaf and every previously approved action only.
7. Update Progress, Findings and Decisions, and Audit Log with exact results. Stage only this ExecPlan and
   `.config/nvim/init.lua`, then create a local commit such as `Simplify Neovim diff handling`.

Expected result: full Git and selected-buffer comparisons retain Neovim's familiar synchronized split but close with
the opening Gitsigns key or universal close action, while `\gi` supplies a zero-layout-change preview for routine hunk
inspection.

Recovery: if Gitsigns changes its comparison-buffer type, identify it from the verified current-tab diff windows and
buffer name before widening the close rule. If complete option restoration fails, keep the comparison-window close
and diagnose `:diffoff!` state in the disposable fixture rather than adding manual option resets.

### Milestone 9: Follow-up regression validation and handoff

Affected files:

- `DEV_ENV_IMPROVEMENTS_EXECPLAN.md` and `.config/nvim/init.lua`; no exploratory fixture is committed.

Steps:

1. Reread this complete plan and inspect `git status --short`; preserve unrelated work.
2. Run `git diff --check`, headless Neovim startup, and the focused Milestone 7 and 8 fixtures once against the final
   committed configuration. Rerun the earlier global/Gitsigns/NvimTree/Bufferline integration fixtures because the
   same mapping, panel, statusline, and tabline surfaces changed; do not rerun unrelated container tests.
3. Confirm `/tmp/dev-env-followup-exploration.VCimnc` and all disposable Git/filesystem fixtures remain outside the
   repository. Record any remaining physical UI checks for interactive dark/light appearance and mouse hover/close.
4. Update Progress, Findings and Decisions, and Audit Log with exact results, then commit only the ExecPlan if the
   validation record is the sole task-related change. Never push.

Expected result: startup and all touched integration behavior pass from a clean tree; the handoff names local commits,
the journal, exact automated results, and only genuinely interactive checks.

Recovery: correct only the milestone owning a failure and repeat its focused checks. Use `git revert` on the relevant
local milestone commit instead of resetting the branch or disturbing unrelated user work.

## Progress

- [x] Inspected the repository, installed tools/plugins, aliases, apt list, npm configuration, LSP behavior, and all
  project/plugin keymaps relevant to the task.
- [x] Researched official npm, Debian, Neovim, nvim-lspconfig, Fzf Lua, Gitsigns, Aerial, Mini Clue, NvimTree, and
  Bufferline documentation/source at the installed or selected revisions.
- [x] Tested JSON formatting, blame drawer failure/repairs, Aerial toggling, Mini Clue roots/context, Fzf provider
  availability, Gitsigns attachment isolation, and complete replacement of NvimTree defaults in temporary fixtures.
- [x] Explored native-menu context and nested TUI behavior, reverted the demo, and dropped menu customization.
- [x] Cataloged the old keymaps and selected the three-root/noun-group architecture, flat Space picker layer,
  `<Space>g` Git search, contextual NvimTree layout, and balanced trim.
- [x] Prototyped Bufferline with the Mini Icons devicons mock, safe MiniBufremove callbacks, no diagnostics, hover
  configuration, and the real 45-column NvimTree offset; selected the simple stable-order draft.
- [x] Revised this self-contained ExecPlan with the selected graph and began implementation from a clean worktree.
- [x] Milestone 1: updated container packages, npm policy, and both alias surfaces; focused source checks pass.
- [x] Milestone 2: implemented and validated the global keymap graph, panels, JSON format mapping, and Mini Clue.
- [x] Milestone 3: implemented and validated contextual Gitsigns actions and blame closing.
- [x] Milestone 4: replaced and validated NvimTree's buffer-local mappings.
- [x] Milestone 5: replaced Mini Tabline with Bufferline and passed all headless/static UI-state checks; physical
  hover/click behavior remains deferred to an interactive terminal.
- [x] Milestone 6: consolidated source/static/headless validation passed; downstream Docker, zsh, and physical
  terminal mouse checks are documented for handoff.
- [x] Explored the follow-up Bufferline order/highlight APIs, Mini Statusline/Completion/Keymap behavior, Gitsigns
  blame/diff APIs, native diff cleanup, and a listed unified-diff prototype; rejected the prototype as needless
  complexity and selected toggleable native splits.
- [x] Approved direct brace maps, minimal terminal cleanup, deterministic native completion validation, and
  generic special-buffer diff detection to keep the implementation small and decoupled.
- [x] Milestone 7: refined and validated Bufferline navigation/theme/title, statusline, blame, terminal, completion,
  and clue timing.
- [x] Milestone 8: made native split diffs easy to close and added inline hunk preview; focused Git, selected-buffer,
  option-restoration, context, and preview checks pass.
- [x] Milestone 9: reran focused follow-up and touched-surface regressions from the committed configuration; all
  automated checks pass and all disposable mutations are restored.
- [x] Corrected fast Bufferline navigation to `{`/`}`/`|`, removed the project `[`/`]` mappings and `nowait`, and
  reran focused navigation and global-map checks.

Exact next action: none. Implementation and automated validation are complete; only the documented host/image and
physical terminal UI checks remain downstream.

## Findings and Decisions

### Verified facts and evidence

- Milestone 1 validation passed on 2026-09-11: npm reports `min-release-age` as `3`, Bash syntax is valid, the first
  apt block contains exactly one each of `npm`, `python3-venv`, and `yarnpkg` in that order, the two shell surfaces
  contain no `gcheckout`, and `git diff --check` is clean. Zsh syntax and the image build remain deferred as planned.
- The original repository-wide `gcheckout` validation was self-referential because this ExecPlan documents the
  removed alias. The executable check now targets `docker/.bashrc` and `.zshrc`, which are the complete alias and
  guidance surfaces in scope.
- Milestone 2's headless behavioral fixture passed on 2026-09-11. It verified the literal backslash leaders, all
  approved `g`, Space, direct-action, buffer, panel, and quickfix mappings and descriptions; restored macro recording;
  normal and Visual comments; ordinary and special-buffer closing; real Codex, Explorer, Aerial, terminal, and
  Quicker open/close cycles; source focus for Aerial; and all selected Fzf provider functions.
- In the same fixture, `jsonls` attached to a real JSON file with formatting capability and `\f` reformatted compact
  JSON to the expected four-space indentation. No JSON-specific formatter or extra LSP setting was added.
- Mini Clue creates triggers from `BufWinEnter`, `LspAttach`, and selected filetype events, all of which can precede
  setup for the startup buffer. Calling `MiniClue.ensure_buf_triggers()` once immediately after setup makes all six
  project root triggers available in the initial buffer; the fixture confirmed they are buffer-local.
- Neovim 0.12 itself supplies `[q` and `]q` with `:cprevious` and `:cnext` descriptions. The former project mappings
  are removed from `init.lua`; the built-in mappings remain intentionally because default-key removal is outside the
  approved project-map graph.
- Milestone 3 passed a disposable two-commit Git fixture on 2026-09-11. A tracked source buffer exposed exactly the
  twelve approved Normal leaves plus Visual stage/reset, while a non-Git buffer exposed none and every omitted leaf
  remained absent. Mini Clue's leader trigger remained buffer-local after attachment.
- The Git fixture exercised next/previous hunk, popup preview, current-buffer and repository quickfix population,
  index and previous-commit diffs, full line blame, stage, undo-stage, reset, and separate Visual range stage/reset.
  It restored the disposable index and worktree after the checks.
- The blame drawer opened and closed with `\gb` from both source and drawer buffers, and `\bd` closed it as the
  universal special-buffer action. Closing restored the source window's `scrollbind`, `wrap`, and `foldenable`
  values and did not raise `E1513`.
- Gitsigns publishes its initial status dictionary before it invokes `on_attach`; contextual-map tests must wait for
  the actual `\gb` buffer mapping (and hunk counts) rather than treating the first status metadata as full attachment.
- Milestone 4's generated-map and real-buffer checks passed on 2026-09-11. NvimTree exposes exactly the 25 approved
  Normal actions and only delete/copy/cut in Visual mode, has no representative inherited defaults, and receives
  buffer-local leader, literal-Space, and `g` Mini Clue triggers plus Normal Open and Normal/Visual Clipboard clues.
- A disposable filesystem and Git fixture exercised create, rename, full-path move, confirmed delete, copy/cut/paste,
  absolute/filename/relative path copy, search, root-here/root-up, refresh, node info, Git and diagnostic navigation,
  Enter, preview, horizontal/vertical/tab opening, and `\pe` close/reopen. Leaving Explorer restored global Save and
  diagnostic meanings plus the source buffer's contextual Gitsigns navigation.
- The headless environment has no system clipboard provider. The NvimTree fixture supplied a temporary in-process
  provider and verified the exact values sent by all three path-copy actions; production configuration was not
  changed. The double-click map was verified through the effective-map API but real mouse input remains a UI check.
- Milestone 5's static and headless checks passed on 2026-09-11. Bufferline is the sole tabline owner, its effective
  options use ID sorting, no diagnostics, 200 ms close reveal, `●`, safe function callbacks, hidden global close,
  JDT shortening, and one NvimTree separator offset; the milestone added no keymap call or devicons dependency.
- The existing Mini Icons compatibility shim returned both an icon and color through `nvim-web-devicons`. Rendered
  state contained the modified marker and short `Widget.class` JDT name without URI or diagnostic text, while both
  close callbacks preserved deliberately modified buffers instead of forcing deletion.
- Bufferline's raw sidebar offset reports the NvimTree window's live 45-column width and returns to zero when the tree
  closes. Its aggregate `state.left_offset_size` can additionally include Bufferline's own overflow marker in a narrow
  headless screen, so offset validation correctly uses `bufferline.offset.get().left_size` rather than conflating the
  two independent layout components.
- Final consolidated validation passed on 2026-09-11 from a clean worktree. It reran whitespace, Bash, npm policy,
  shell-alias, apt-count, Neovim startup, global map/Mini Clue/macro/Comment/JSON/panel/close, contextual Gitsigns,
  contextual NvimTree, and Bufferline option/render/safety/offset checks against the committed configuration.
- The final run restored both disposable Git/filesystem fixtures and confirmed the repository worktree remained
  clean. All test scripts and fixtures are under `/tmp`; no exploratory artifact is tracked.
- Follow-up exploration on 2026-09-11 confirmed that Bufferline's `insert_after_current` sorter must be paired with
  `BufferLineCycleNext`/`BufferLineCyclePrev`; native `bnext`/`bprevious` continue to follow numeric buffer IDs. The
  offset supports its own text/title and alignment, making the NvimTree-local `Explorer` winbar redundant.
- Bufferline accepts a highlight-producing function and re-resolves it from its `ColorScheme` autocmd. This supports
  exact Gruvbox palette choices that follow runtime dark/light changes without duplicating a theme-change autocmd.
- Mini Statusline's full `section_fileinfo()` always combines filetype, encoding/fileformat, and computed buffer size;
  removing only the KiB/encoding output while retaining useful filetype and line-ending information requires replacing
  that section. Its raw fileformat labels are `unix`, `dos`, and `mac`, corresponding to LF, CRLF, and CR; direct
  statusline items provide low-cost line/column and file flags.
- Mini Completion intentionally does not map Tab. Because Mini Keymap is part of the installed Mini.nvim checkout,
  its documented `pmenu_next`/`pmenu_prev` multistep mappings can provide completion selection with literal-Tab
  fallback and no dependency. Mini Clue's documented default delay is 1000 ms and accepts a direct 250 ms override.
- Gitsigns' side-panel `blame_formatter` accepts a function and can suppress repeated summaries. Its `diffthis()`
  creates a split, returns focus to the source, marks index/revision comparison buffers as `acwrite`/`nowrite`, and
  installs cleanup when the comparison is hidden. Neovim's `:diffoff!` restores diff-related options throughout the
  tab, so a same-key close helper can retain the native diff without custom rendering.
- Gitsigns inline preview covers the current hunk and clears itself on CursorMoved, InsertEnter, or BufLeave, making it
  a useful low-cost companion to the full split. A Neovim 0.12.4 listed unified-diff prototype also passed, but the
  user rejected its Git-base retrieval and lifecycle code as disproportionate complexity.
- Milestone 7 passed focused validation on 2026-09-11. Bufferline uses adjacent insertion; direct `{`/`}` and
  discoverable navigation follow a verified `a, c, b` visual order; and dark/light
  highlight snapshots match every approved layered fill/inactive/selected, blue indicator/offset, and orange modified
  color. A real NvimTree rendered a centered 45-column `File Explorer` offset with an empty window winbar.
- Statusline rendering showed mode, Git, modified filename, icon/filetype, CRLF, indentation, and line:column in order
  with adaptive blue Git and purple metadata backgrounds. It contained no search, diagnostics/LSP, size, encoding, or
  raw fileformat label. Functional and real-drawer blame checks rendered a single Unicode author initial and `?` for
  the uncommitted formatter without a full author name.
- The generic terminal helper remained unchanged while Codex code and `\pc` disappeared; `\pt` opened and reused the
  shell terminal. Mini Clue reported exactly 250 ms. A deterministic `vim.fn.complete()` fixture proved initial
  no-selection, forward/reverse Tab cycling, and ordinary four-space Tab fallback without starting an LSP.
- Milestone 8 passed its disposable two-commit fixture on 2026-09-11. `\gd` compared the worktree to the index and
  `\gD` compared it to the previous commit, both retained source focus, and a second press closed the comparison.
  `\bd` and `|` closed either split from source focus without deleting it; both also closed a focused Gitsigns
  special comparison generically through non-empty `buftype` rather than a plugin buffer name or exact type.
- Every close path retained an unrelated nofile split and restored source `diff`, `scrollbind`, `cursorbind`, `wrap`,
  and `foldenable`. A mocked Fzf selection exercised the real `\bD` action and proved both universal close keys work
  for ordinary selected-buffer comparisons. Inline `\gi` produced Gitsigns preview extmarks/virtual lines and cleared
  on CursorMoved, InsertEnter, and BufLeave; popup `\gp` and the complete thirteen-leaf Mini Clue map inventory remain.
- Milestone 9's committed-config regression run passed on 2026-09-11: whitespace and startup; Milestone 7's
  Bufferline order/colors/title, statusline, terminal, clue, deterministic completion, and real blame; Milestone 8's
  complete diff lifecycle; the global graph, panels, JSON LSP formatting, contextual Gitsigns including Visual
  stage/reset, NvimTree maps and filesystem operations, and Bufferline rendering/safety/live offset.
- Two disposable regression assumptions needed deterministic setup, not production changes. Gitsigns' retained graph
  can prefix a one-character blame author with either `┍` or `╺` depending on worktree state, so the check now asserts
  the semantic one-character suffix. NvimTree Git navigation requires two changed nodes, which the fixture now seeds.
  The Git fixture indexes/worktrees and generated filesystem paths were restored; `/workspace` was clean before this
  final ExecPlan-only audit update.
- Remaining manual checks are limited to appearance and physical input: inspect both Gruvbox modes interactively;
  confirm Bufferline hover, left-click close, and right-click safe close in a terminal forwarding mouse motion; and
  physically exercise NvimTree double-click. The previously documented Docker image smoke and host zsh syntax checks
  also remain unavailable in this container.
- The user corrected the intended fast-key set from `[`/`]`/`|` to `{`/`}`/`|`. The final config maps braces to
  Bufferline's visual previous/next commands without `nowait`, retains `|` as universal close, and leaves square
  brackets unmapped by the project. Focused startup, direct/discoverable visual-order navigation, exact mapping flags,
  global graph, panels, and JSON formatting checks passed after the correction.

- Debian trixie publishes the requested packages: [python3-venv](https://packages.debian.org/trixie/python3-venv),
  [npm](https://packages.debian.org/trixie/npm), and [yarnpkg](https://packages.debian.org/trixie/yarnpkg).
- npm v11 documents `min-release-age` in days and `before` as its absolute-date counterpart:
  [npm configuration](https://docs.npmjs.com/cli/v11/using-npm/config/#min-release-age). Installed npm accepted a
  scratch `min-release-age = 3` and returned `3`.
- The existing JSON LSP defaults execute `vscode-json-language-server --stdio` for JSON/JSONC and advertise a
  formatter: [nvim-lspconfig jsonls](https://github.com/neovim/nvim-lspconfig/blob/85e732c62ac59ab7c12df71ddd020baa87948390/lsp/jsonls.lua#L24-L40).
  A real attached buffer reported formatting support and formatted compact JSON with four-space indentation.
- Fzf Lua's provider catalog includes every selected file, buffer, history, quickfix, help, command, diagnostic, and
  Git picker: [provider catalog](https://github.com/ibhagwan/fzf-lua/blob/05e44d38de0a79c11fba5f7bf8138791b1dbdd1e/README.md#L312-L441).
  Its `global()` picker combines files, buffers, and document/workspace symbols:
  [global defaults](https://github.com/ibhagwan/fzf-lua/blob/05e44d38de0a79c11fba5f7bf8138791b1dbdd1e/lua/fzf-lua/defaults.lua#L542-L606).
  `history()` includes the current session, while `files()` is preferable to VCS-only files because it can include
  untracked non-ignored files.
- Gitsigns' official example supports buffer-local attachment and the selected navigation, stage/reset/undo, preview,
  blame, diff, and quickfix actions:
  [Gitsigns mappings](https://github.com/lewis6991/gitsigns.nvim/blob/5be654f2232c10ddcad19c1607a67b6b4b78fc29/README.md#L336-L403).
  Gitsigns creates blame as a fixed `nofile` split and restores source options on close:
  [blame creation](https://github.com/lewis6991/gitsigns.nvim/blob/5be654f2232c10ddcad19c1607a67b6b4b78fc29/lua/gitsigns/actions/blame.lua#L479-L520),
  [cleanup](https://github.com/lewis6991/gitsigns.nvim/blob/5be654f2232c10ddcad19c1607a67b6b4b78fc29/lua/gitsigns/actions/blame.lua#L647-L657).
- Mini Clue requires opt-in triggers, derives leaf labels from mapping descriptions, supports explicit group clues, and
  requires triggers to be recreated after later buffer-local mappings:
  [trigger caveats](https://github.com/nvim-mini/mini.nvim/blob/9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a/doc/mini-clue.txt#L44-L79),
  [buffer-local configuration](https://github.com/nvim-mini/mini.nvim/blob/9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a/doc/mini-clue.txt#L99-L106), and
  [special buffers](https://github.com/nvim-mini/mini.nvim/blob/9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a/doc/mini-clue.txt#L341-L347).
  Scratch tests proved backslash leader, literal Space, and `g` coexist and that late contextual maps remain
  buffer-local after `ensure_buf_triggers()`.
- NvimTree uses its default attach only when `on_attach` is not a function. A custom callback can install a wholly
  replacement buffer-local map set:
  [mapping configuration](https://github.com/nvim-tree/nvim-tree.lua/blob/b2aadda94b107480c48e548d6db51c6840b7b33c/doc/nvim-tree-lua.txt#L325-L374),
  [default implementation](https://github.com/nvim-tree/nvim-tree.lua/blob/b2aadda94b107480c48e548d6db51c6840b7b33c/lua/nvim-tree/keymap.lua#L5-L120).
  Its filesystem API confirms that `rename_full()` edits the absolute path, whereas `move()` pastes already cut
  nodes: [filesystem API](https://github.com/nvim-tree/nvim-tree.lua/blob/b2aadda94b107480c48e548d6db51c6840b7b33c/doc/nvim-tree-lua.txt#L2415-L2536).
- Aerial's `AerialToggle!` opens/closes while preserving source focus, and the installed command passed a scratch
  toggle test: [Aerial command semantics](https://github.com/stevearc/aerial.nvim/blob/28fe6e822ae344544c379d60fcb13c9519a1f08a/README.md#L209-L218).
- Bufferline defaults to buffer mode, buffer-ID ordering, thin separators, an active-buffer indicator, a `●`
  modified marker, always showing the row, and no diagnostics:
  [Bufferline defaults](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/lua/bufferline/config.lua#L632-L675).
  Its upstream hover configuration requires `mousemoveevent` and can reveal inactive close icons after 200 ms:
  [hover behavior](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/doc/bufferline.txt#L181-L199).
- Bufferline renders a modified marker instead of a close icon for a modified buffer; its default close-click and
  right-click callbacks use forced `bdelete!`, so both must be replaced with MiniBufremove callbacks:
  [suffix rendering](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/lua/bufferline/ui.lua#L263-L331),
  [mouse defaults](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/lua/bufferline/config.lua#L636-L642).
- Bufferline officially supports an NvimTree offset derived from the matching edge window:
  [sidebar offset](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/doc/bufferline.txt#L593-L641).
  A headless prototype with the repository's real NvimTree configuration measured a 45-column left offset. The
  existing Mini Icons mock returned a colored Lua icon through the devicons compatibility API, and MiniBufremove
  preserved a deliberately modified scratch buffer rather than silently forcing deletion.
- Bufferline documents adjacent insertion, offset titles, theme-derived highlights, and visual-order cycle commands:
  [options](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/doc/bufferline.txt#L120-L171),
  [sorted navigation](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/doc/bufferline.txt#L481-L501), and
  [highlights](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/doc/bufferline.txt#L795-L815).
  Its source re-runs a user highlight function on colorscheme changes:
  [dynamic resolution](https://github.com/akinsho/bufferline.nvim/blob/655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3/lua/bufferline/config.lua#L680-L719).
- Mini's official references document the statusline sections, popup-menu Tab mappings, and 1000 ms clue default:
  [statusline sections](https://github.com/nvim-mini/mini.nvim/blob/9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a/doc/mini-statusline.txt#L303-L359),
  [completion mappings](https://github.com/nvim-mini/mini.nvim/blob/9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a/doc/mini-completion.txt#L170-L183),
  [Mini Keymap steps](https://github.com/nvim-mini/mini.nvim/blob/9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a/doc/mini-keymap.txt#L85-L120), and
  [clue window](https://github.com/nvim-mini/mini.nvim/blob/9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a/doc/mini-clue.txt#L496-L505).
- Gitsigns documents its functional blame formatter, split diff, and current-hunk-only inline preview:
  [blame formatter](https://github.com/lewis6991/gitsigns.nvim/blob/5be654f2232c10ddcad19c1607a67b6b4b78fc29/doc/gitsigns.txt#L1070-L1098),
  [split diff](https://github.com/lewis6991/gitsigns.nvim/blob/5be654f2232c10ddcad19c1607a67b6b4b78fc29/doc/gitsigns.txt#L212-L240), and
  [inline preview](https://github.com/lewis6991/gitsigns.nvim/blob/5be654f2232c10ddcad19c1607a67b6b4b78fc29/doc/gitsigns.txt#L370-L379).
  Neovim documents `:diffoff!` as restoring diff-related options across all diff windows in the current tab:
  [diff cleanup](https://neovim.io/doc/user/diff.html#%3Adiffoff).
- Neovim native menus and flat custom entries worked in a terminal, but selecting a nested custom menu reproduced
  `E335: Menu not defined for Normal mode`. A chained `:popup` workaround worked but required a multi-stage design.
  The experimental config was reverted and the user chose Mini Clue instead.

Temporary exploration material is intentionally uncommitted:

- `/tmp/neovim-improvements-explore.Nlutuo/JOURNAL.md`
- `/tmp/native-menu-exploration/JOURNAL.md`
- `/tmp/neovim-keymap-architecture.EpFoTn/JOURNAL.md`
- `/tmp/bufferline-exploration.Ih1aac/JOURNAL.md`
- `/tmp/dev-env-followup-exploration.VCimnc/JOURNAL.md`

### Decisions

- Retain the existing npm package and add only `python3-venv` and `yarnpkg`; never duplicate a requested setting
  merely to make every noun appear in a diff.
- Use npm's supported `min-release-age = 3`.
- Remove every `gcheckout` definition and stale mention.
- Keep the existing `jsonls` configuration; add only the general LSP format mapping.
- Use the selected three-root architecture and balanced trim. Discoverability and stable semantics are more important
  than preserving defaults or minimizing every sequence to two keys.
- Keep the flat Space picker layer despite `global()` overlap because `<Space>f` and `<Space>b` are expected
  mnemonics. Keep rarer unbound providers behind `<Space>a`.
- Distinguish Git selection from Git mutation: `<Space>g...` searches repository objects through Fzf, while
  buffer-local `\g...` performs Gitsigns/NvimTree Git actions.
- Remove the duplicate `\w` family and retain only `<A-h/j/k/l>` for window focus.
- Use direct `\q` toggle plus `<Space>q` selection instead of a Quickfix navigation subgroup.
- Treat NvimTree's current buffer as the implicit Explorer noun, replace all defaults, group only Open and Clipboard
  variants, and restore Mini Clue triggers last.
- Use `rename_full()` for NvimTree `\m`; direct `api.fs.move()` would misleadingly require a prior cut.
- Keep the focused Gitsigns set, add the approved `\gi` inline preview, and continue omitting the high-impact
  whole-buffer reset and lower-value duplicates.
- Implement both blame toggle and universal `\bd`: the former gives same-key behavior from either pane, while the
  latter gives every ordinary/special buffer one canonical close action.
- Replace Mini Tabline with Bufferline while retaining hover, modified marker, safe mouse closing, JDT names, no
  diagnostics, and the Mini Icons shim. The follow-up uses VS Code-like adjacent insertion, visual-order cycle
  commands, literal `{`/`}` navigation without `nowait`, literal `|` close, and a centered `File Explorer` offset
  title.
- Use the soft Gruvbox Bufferline palette recorded in Milestone 7. Keep its indicator and Explorer separator blue,
  modified marker orange, and recompute all state colors for dark/light modes through Bufferline's highlight callback.
- Preserve the current statusline shape with this logical order: mode, Git, filename/status, then filetype, friendly
  LF/CRLF/CR label, indentation, and line:column. Remove search, diagnostics/LSP state, size, and encoding. Use an
  adaptive blue Git background, neutral filename, and adaptive purple metadata background.
- Compact the full blame drawer to a one-character author label and suppress repeated summaries while retaining its
  graph/heatmap.
- Remove only the Codex-specific launcher, mapping, and state; keep the proven generic terminal helper and one shell
  terminal panel under `\pt` without an otherwise unnecessary refactor.
- Use Mini Keymap's popup-menu steps for Tab/Shift-Tab completion navigation, retain literal fallback, and set Mini
  Clue's delay to 250 ms. Validate the mapping deterministically with `vim.fn.complete()` rather than an asynchronous
  LSP fixture; production completion remains LSP-backed.
- Keep native split diffs, make `\gd`/`\gD` same-key toggles, and make universal `\bd`/`|` close the comparison while
  preserving the source and unrelated windows. Distinguish special comparisons only by non-empty `buftype`, finish
  with `:diffoff!`, and add no diff plugin or custom renderer.
- Leave native menus untouched and use Mini Clue as the sole discovery addition.

### Inference and unresolved gaps

- Inference: Debian's `yarnpkg` intentionally exposes the `yarnpkg` executable; no `yarn` alias was requested.
- Inference: contextual NvimTree `\s` is preferable to preserving global Save in an unwritable Explorer buffer; the
  buffer-local description makes the override visible.
- Inference: preserving Aerial source focus matches the other panel toggles and occasional-use workflow.
- Inference: `insert_after_current` is the closest Bufferline-provided equivalent to VS Code's right-of-active editor
  insertion. Pairing it with Bufferline cycle commands removes the former visible-order/native-ID mismatch.
- Inference: keeping the native split plus one close helper is preferable to the prototyped unified patch buffer. It
  preserves Gitsigns' index/revision semantics, avoids Git plumbing and asynchronous lifecycle code, and makes the
  existing layout manageable through same-key and universal close actions.
- Unresolved until external build: the pinned base and live trixie repositories must resolve all three apt packages
  on every target architecture.
- Unresolved until host validation: zsh syntax cannot run here because zsh is absent.
- Unresolved until interactive validation: headless tests cannot generate real terminal mouse movement, so hover
  reveal and click behavior must be confirmed in a UI whose terminal forwards mouse-motion events.
- The native browser-menu/Normal-`gx` collision remains outside scope because menu customization was dropped.

## Audit Log

- 2026-09-11 UTC — Created `DEV_ENV_IMPROVEMENTS_EXECPLAN.md` from clean repository state after local and upstream
  exploration. Recorded all requested package, npm, alias, JSON, blame, Aerial, Mini Clue, and native-menu work;
  resolved the npm key, Aerial mapping, blame close strategy, Mini Clue trigger coverage, native menu catalog, and
  `gx` collision; documented focused validation, exclusions, recovery, deferred checks, and the exact next action.
- 2026-09-11 UTC — Corrected the `PopUp.Search` catalog's `<Leader>s` notation during pre-commit review.
- 2026-09-11 UTC — Removed native right-click customization, its `gx` repair, its former Milestone 4, and all
  associated final validation at the user's direction. Recorded that flat entries worked, nested TUI selection
  reproduced `E335`, and a chained `:popup` worked but was too complex; made Mini Clue the sole discovery interface
  and reverted the uncommitted menu demo.
- 2026-09-11 UTC — Replaced the old Space-leader/panel/Mini-Clue plan with the user-approved three-root architecture,
  flat mnemonic Space picker layer, `<Space>g` Git-search subgroup, balanced noun groups, contextual twelve-action
  Gitsigns layout, and complete buffer-local NvimTree default replacement. Added exact mapping tables, attachment and
  trigger-order requirements, focused validation and recovery, preserved all package/npm/alias/JSON requirements, and
  kept native menus excluded. No implementation or tracked experimental change is included in this revision.
- 2026-09-11 UTC — Added the user-approved Bufferline replacement as Milestone 5 and renumbered final validation to
  Milestone 6. Recorded removal of Mini Tabline and its highlight overrides, reuse of the Mini Icons devicons mock,
  default visuals and stable buffer-ID ordering, explicit no-diagnostics behavior, JDT filename parity, safe
  MiniBufremove-backed mouse closing, hover requirements, a blank live-width NvimTree offset, exact validation and
  recovery, and the prototype evidence in `/tmp/bufferline-exploration.Ih1aac/JOURNAL.md`. Added no implementation or
  Bufferline keymap.
- 2026-09-11 UTC — Completed Milestone 1: added `python3-venv` and `yarnpkg` to the existing apt package list, set
  npm's three-day `min-release-age`, and removed `gcheckout` from both shell surfaces and host guidance. Recorded the
  passing npm, Bash, apt-list, alias, and whitespace checks and retained the planned Docker/zsh deferrals. Corrected
  the self-referential alias validation to inspect the two in-scope shell files instead of this documenting ExecPlan.
- 2026-09-11 UTC — Completed Milestone 2: changed both leaders to backslash; installed the approved cursor, literal
  Space picker, Git-search, direct action, buffer, panel, and quickfix mappings; removed the superseded project maps;
  and configured Mini Clue for only the three project roots and named groups. Added an immediate trigger ensure for
  the initial buffer after discovering setup events can already have passed. Recorded passing effective-map, macro,
  Comment, JSON LSP formatting, universal close, real panel-toggle, Fzf-provider, and Mini Clue checks, including the
  distinction between removed project quickfix maps and Neovim's own `[q`/`]q` defaults.
- 2026-09-11 UTC — Completed Milestone 3: added the shared current-tab blame drawer toggle, attached only the twelve
  approved Gitsigns actions to Git source buffers, attached the same toggle to blame buffers, and refreshed Mini Clue
  triggers after each late buffer-local map set. Recorded passing isolation, effective-map, hunk navigation/preview,
  both quickfix scopes, both diffs, blame-line, Normal and Visual stage/reset, undo-stage, same-key drawer toggle,
  universal drawer close, option restoration, and disposable-repository cleanup checks.
- 2026-09-11 UTC — Completed Milestone 4: replaced all NvimTree defaults with the approved context-as-noun actions,
  Open/Clipboard subgroups, Git/diagnostic navigation, buffer-local clues, and late Mini Clue trigger refresh. Recorded
  passing generated and real effective-map inventories plus disposable create, rename, move, delete, clipboard,
  search, root, refresh, info, navigation, open-target, context restoration, and Explorer toggle checks. Documented
  the test-only clipboard provider and deferred physical double-click input; added no production dependency or map.
- 2026-09-11 UTC — Completed Milestone 5's source, static, and headless work: installed Bufferline as the sole new
  dependency; enabled mouse-move events; removed Mini Tabline and its seven highlights; and configured safe mouse
  closing, no diagnostics, hover reveal, modified marker, JDT names, hidden global close, and NvimTree offset. Recorded
  passing effective-option, render, modified-buffer safety, icon shim, JDT, live-offset, startup, static dependency,
  and no-new-keymap checks. Deferred only physical hover/click behavior to an interactive mouse-capable terminal.
- 2026-09-11 UTC — Completed Milestone 6 after rereading the full living plan from a clean worktree. Reran one
  consolidated validation command covering every source/static check and the global, Gitsigns, NvimTree, Bufferline,
  JSON, Mini Clue, panel, Comment, macro, close, filesystem, and mutation fixtures; all passed, temporary mutations
  were restored, and the repository remained clean. Marked implementation complete and retained only the Docker
  image smoke test, unavailable zsh syntax check, and physical terminal Bufferline mouse check for downstream hosts.
- 2026-09-11 UTC — Added follow-up Milestones 7–9 after inspecting the implemented config, installed plugin source,
  official upstream documentation, and a disposable Neovim 0.12 unified-diff prototype. The draft now specifies
  literal `[`/`]` visual-order navigation and `|` close, adjacent Bufferline insertion, a centered `File Explorer`
  offset, adaptive Gruvbox highlights, a focused statusline without diagnostics or size, one-character blame authors,
  Codex-panel removal, Mini Keymap Tab completion, 250 ms clues, and listed unified-diff buffers replacing all three
  split workflows. Recorded alternatives and the curly-versus-square-bracket interpretation for user iteration; no
  production configuration was changed.
- 2026-09-11 UTC — Incorporated the user's final follow-up design approval without changing production configuration.
  Locked in literal `[`/`]`/`|`, adjacent visual ordering, the Layered Gruvbox Bufferline palette, Explorer title,
  compact blame, Codex removal, Tab completion, and 250 ms clues. Revised the statusline to preserve its current shape
  while removing search and diagnostics/LSP, replacing bundled size/encoding data with icon/filetype and friendly
  LF/CRLF/CR, adding line:column, and assigning blue Git plus purple metadata backgrounds. Rejected the custom listed
  unified-diff milestone as needless complexity; replaced it with native Gitsigns/selected-buffer splits that close
  via same-key `\gd`/`\gD` or universal `\bd`/`|`, clean up with `:diffoff!`, and add `\gi` inline hunk preview.
- 2026-09-11 UTC — Applied the user's four implementation-simplification approvals to the plan only. Required
  `nowait = true` on literal `[`/`]` so longer default bracket prefixes cannot delay tab navigation; limited Codex
  removal to Codex-specific code while preserving the proven generic terminal helper; replaced LSP-driven completion
  validation with deterministic `vim.fn.complete()` candidates while leaving production completion LSP-backed; and
  generalized diff-pane detection to non-empty `buftype` instead of depending on Gitsigns' exact `acwrite`/`nowrite`
  types or URI. No production configuration was changed.
- 2026-09-11 UTC — Completed Milestone 7 in `.config/nvim/init.lua`: installed immediate visual-order Bufferline
  navigation and universal `|` close; adjacent ordering; the centered Explorer title; dark/light Layered Gruvbox
  Bufferline colors; the approved blue/neutral/purple statusline with friendly line endings and cursor position;
  one-character blame headers; Codex-only removal; Mini Keymap Tab selection; and 250 ms Mini Clue. Focused startup,
  static, palette/order/statusline/Explorer/terminal, real blame, and deterministic completion checks all passed.
- 2026-09-11 UTC — Completed Milestone 8 in `.config/nvim/init.lua`: added one generic current-tab diff closer;
  converted `\gd`/`\gD` into same-key native-split toggles; routed `\bd` and `|` through the same cleanup; and added
  buffer-local `\gi` inline hunk preview. A disposable two-commit Git fixture and ordinary selected-buffer fixture
  passed base-selection, source-focus, special-comparison, unrelated-window, complete option-restoration, all close
  paths, inline-preview lifecycle, retained popup preview, contextual-map inventory, startup, and whitespace checks.
- 2026-09-11 UTC — Completed Milestone 9 after rereading the committed plan from a clean tree. The focused follow-up
  and touched global/Gitsigns/NvimTree/Bufferline integration suites all passed, including real JSON formatting,
  panel toggles, dark/light highlight values, blame, deterministic completion, diff closure, inline preview,
  filesystem operations, and Visual Git mutations. Tightened two temporary fixture assumptions without changing
  production code, restored every disposable mutation, recorded only genuine interactive/host deferrals, and left
  this final ExecPlan audit as the sole task-related change for its required local commit.
- 2026-09-11 UTC — Applied the user's navigation-key correction: replaced project `[`/`]` Bufferline navigation with
  `{`/`}`, removed `nowait`, restored square brackets for Neovim's bracket-prefixed commands, and retained `|` close
  plus discoverable `\bp`/`\bn`. Updated the active requirements, validation, progress, findings, and decisions while
  preserving earlier audit entries as history. Whitespace, startup, direct/discoverable visual-order navigation,
  mapping inventory/flags, global panels, and real JSON formatting checks passed.
