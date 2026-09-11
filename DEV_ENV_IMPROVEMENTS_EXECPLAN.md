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
- Panels use `\p`: Codex, Explorer, Aerial outline, and terminal. Quickfix uses direct `\q` for toggling and
  `<Space>q` for selecting entries.
- NvimTree has no inherited plugin defaults. Its buffer-local mappings treat the selected Explorer node as the noun
  and expose mnemonic actions and small Open/Clipboard groups through Mini Clue.
- Mini Clue describes the project-owned `g`, literal-Space, and backslash families, including mappings added later by
  Gitsigns and NvimTree attachment.
- Bufferline replaces Mini Tabline with a default-styled, stable-order buffer row, a modified marker, hover-revealed
  close controls, safe MiniBufremove-backed mouse closing, and an offset matching the NvimTree sidebar. It displays no
  LSP diagnostics and adds no keymaps.
- Neovim's native right-click menu is not customized.

Relevant repository state:

- Branch `20260911-improvement` is clean at commit `441c0ae` before this plan revision.
- `docker/Dockerfile` uses Debian trixie and one alphabetically ordered apt package list. `npm` is already present;
  `python3-venv` and `yarnpkg` are not.
- `.npmrc` is copied to `/root/.npmrc` by the development image.
- `docker/.bashrc` and `.zshrc` both define `gcheckout`; `.zshrc` also names it in the disabled-Git error.
- Neovim configuration remains a single tracked file, `.config/nvim/init.lua`. It installs Fzf Lua, Gitsigns,
  Mini.nvim, NvimTree, Aerial, Quicker, and the LSP dependencies required here. Mini Tabline supplies the current
  buffer row; Bufferline is not installed and will be the only new plugin.
- `vim.g.mapleader` and `vim.g.maplocalleader` are currently Space. There are 46 explicit project mappings, the
  general actions are mixed into the Space prefix, Gitsigns has no `on_attach` maps, NvimTree inherits more than 50
  plugin defaults, Mini Clue is not configured, and Aerial has no project toggle.
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
- Remove the redundant project mappings `qq`, `[q`, `]q`, `+`, `{`, `|`, and `}` after their replacements
  are installed and tested. This restores ordinary macro recording and avoids competing action homes.
- Keep direct global `\c` Comment and `\x` Save-all-and-quit stable inside NvimTree. NvimTree clipboard actions
  therefore live under `\y`. Contextual NvimTree `\s` intentionally shadows Save because the Explorer scratch
  buffer cannot meaningfully be written.
- Do not map Gitsigns whole-buffer reset, inline hunk preview, hunk selection, stage-buffer, or display toggles. The
  balanced trim deliberately exposes only the selected twelve Gitsigns actions.
- JSON formatting already works. Do not add `provideFormatter`, format-on-save, SchemaStore, or another formatter;
  the new `\f` mapping calls `vim.lsp.buf.format()` for any attached formatter.
- Bufferline must retain its default buffer-ID ordering so its displayed order agrees with the planned native
  `\bn`/`\bp` actions. Do not add Bufferline keymaps, LSP diagnostics, custom style presets, custom highlight groups,
  or a separate devicons plugin. Keep the existing Mini Icons devicons mock and JDT virtual-buffer filename behavior.
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

Exact next action: no repository implementation remains. On capable hosts, run `zsh -n .zshrc`, build and smoke-test
the image, and confirm Bufferline hover/click behavior in a terminal that forwards mouse motion.

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
- Neovim native menus and flat custom entries worked in a terminal, but selecting a nested custom menu reproduced
  `E335: Menu not defined for Normal mode`. A chained `:popup` workaround worked but required a multi-stage design.
  The experimental config was reverted and the user chose Mini Clue instead.

Temporary exploration material is intentionally uncommitted:

- `/tmp/neovim-improvements-explore.Nlutuo/JOURNAL.md`
- `/tmp/native-menu-exploration/JOURNAL.md`
- `/tmp/neovim-keymap-architecture.EpFoTn/JOURNAL.md`
- `/tmp/bufferline-exploration.Ih1aac/JOURNAL.md`

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
- Keep the focused twelve-action Gitsigns set and omit the high-impact whole-buffer reset and lower-value duplicates.
- Implement both blame toggle and universal `\bd`: the former gives same-key behavior from either pane, while the
  latter gives every ordinary/special buffer one canonical close action.
- Replace Mini Tabline with Bufferline using its default visuals and buffer-ID ordering. Enable only the requested
  hover, modified marker, safe mouse closing, JDT name formatter, and blank NvimTree offset; explicitly disable
  diagnostics, hide the redundant global close icon, and add no Bufferline keymaps or devicons dependency.
- Leave native menus untouched and use Mini Clue as the sole discovery addition.

### Inference and unresolved gaps

- Inference: Debian's `yarnpkg` intentionally exposes the `yarnpkg` executable; no `yarn` alias was requested.
- Inference: contextual NvimTree `\s` is preferable to preserving global Save in an unwritable Explorer buffer; the
  buffer-local description makes the override visible.
- Inference: preserving Aerial source focus matches the other panel toggles and occasional-use workflow.
- Inference: default buffer-ID order is preferable to `insert_after_current` here because it keeps the visual row
  consistent with the already approved native `\bn`/`\bp` actions without adding Bufferline-specific mappings.
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
