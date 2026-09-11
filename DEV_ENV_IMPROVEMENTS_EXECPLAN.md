# DEV_ENV_IMPROVEMENTS ExecPlan

## Purpose and Context

This task improves the development image and its Neovim experience without broadening the repository's existing
single-file configuration style. The observable result is:

- The Debian package list retains `npm` and adds `python3-venv` and `yarnpkg`.
- Runtime npm installs reject dependency releases newer than three days through the supported npm setting
  `min-release-age = 3`.
- `gcheckout` is removed from both tracked shell environments and from the host-side guidance text.
- JSON and JSONC continue to use the existing `jsonls` setup, whose formatting capability is verified rather than
  redundantly configured.
- The Gitsigns blame split is a true `<Leader>b` toggle and the existing `|` close action works for fixed special
  panels as well as ordinary buffers.
- Aerial toggles without stealing editor focus through `<Leader>o`.
- `mini.clue` describes every configured multi-key family, including `qq`, while preserving macro recording.

The relevant repository state at plan creation is:

- Branch `20260911-improvement` is clean at commit `9b87bad`.
- `docker/Dockerfile` uses Debian trixie and one alphabetically ordered apt package list. `npm` is already present;
  `python3-venv` and `yarnpkg` are not.
- `.npmrc` is copied to `/root/.npmrc` by the development image.
- `docker/.bashrc` and `.zshrc` both define `gcheckout`; `.zshrc` also names it in the disabled-Git error.
- `.config/nvim/init.lua` installs `mini.nvim`, Aerial, Gitsigns, `nvim-lspconfig`, and the other dependencies needed by
  this work. No new Neovim plugin is required.
- The installed exploration environment has Neovim 0.12.4, npm 11.16.0,
  `vscode-langservers-extracted` 4.10.0, and current repository-managed plugin checkouts.

Assumptions and boundaries:

- The user's phrase "npm min-release-date 3 days" means npm's documented relative-age setting
  `min-release-age = 3`; `min-release-date` is not an npm v11 config key.
- `<Space>B` in the blame request refers to making the existing lowercase `<Leader>b` action reversible. Do not add a
  second uppercase mapping; retain the existing key and change its description to `Toggle blame`.
- JSON formatting already works. Do not add formatter settings, format-on-save, a formatting keymap, or another
  formatter in this task.
- Do not customize Neovim's native menus, add a context-menu plugin, preserve/redirect the original `gx` callback, or
  build a keymap registry for mouse access. Mini Clue is the chosen keymap-discovery interface.
- Docker cannot run in this environment. Source-level validation is required here; a real image build and executable
  smoke test are recorded as downstream validation rather than simulated.
- Do not run `git pull` or `git push`. Stage only the ExecPlan and files named by the current milestone. Every Audit Log
  update must be committed locally together with exactly the task changes it describes.

## Plan of Work

### Milestone 1: Container packages, npm policy, and alias cleanup

Affected files and interfaces:

- `docker/Dockerfile`: the first `apt-get install --yes --no-install-recommends` package list.
- `.npmrc`: npm CLI configuration copied to the image user's home.
- `docker/.bashrc`: development-container aliases.
- `.zshrc`: host-side Git client wrapper aliases and disabled-Git guidance.

Steps:

1. In `docker/Dockerfile`, keep the existing single `npm` entry, add `python3-venv` after `python3-pip`, and add
   `yarnpkg` after `xz-utils`. Do not add duplicate `npm`, a Yarn upstream repository, Corepack configuration, or a
   `yarn` symlink; the request explicitly names Debian's `yarnpkg` package.
2. Add `min-release-age = 3` to `.npmrc`, preserving its current simple `key = value` format. Do not change the
   Dockerfile copy order: the policy is for interactive/runtime npm dependency resolution, not the preceding global
   package installation layers.
3. Delete `alias gcheckout='git checkout'` from `docker/.bashrc`.
4. Delete `alias gcheckout='_gitclient checkout'` from `.zshrc` and remove `gcheckout, ` from the error at `.zshrc:38`
   so the message advertises only commands that still exist.
5. Validate once after the related edits:
   - `npm --userconfig /workspace/.npmrc config get min-release-age` prints `3`.
   - `bash -n docker/.bashrc` exits zero.
   - `rg -n 'gcheckout' . --hidden -g '!/.git/**'` returns no matches.
   - Inspect the Dockerfile list to confirm all three requested package names occur exactly once and ordering remains
     stable. `zsh` is not installed in this container, so record `zsh -n .zshrc` as a downstream host check.
   - Do not run `build.sh`: it invokes forbidden Docker operations and pushes images.
6. Update Progress, Findings and Decisions, and the Audit Log with exact results; stage only this ExecPlan,
   `docker/Dockerfile`, `.npmrc`, `docker/.bashrc`, and `.zshrc`; create a local milestone commit such as
   `Configure development package tooling` with a body summarizing validation.

Expected result: the next image build requests the three Debian packages once, npm reports a three-day release-age
window, and neither shell advertises or defines `gcheckout`.

Recovery: before the milestone commit, restore individual failed edits with `apply_patch`. After commit, use
`git revert <milestone-commit>` if the whole milestone must be backed out; never reset unrelated user work. If the
external Docker build later reports a missing package, first confirm the pinned Debian base is still trixie and inspect
its configured apt sources before changing package names or adding repositories.

### Milestone 2: Blame/panel closing and Aerial toggle

Affected file and interfaces:

- `.config/nvim/init.lua`: the Normal-mode `|` mapping, `<Leader>b` mapping, and new `<Leader>o` mapping.
- Gitsigns public `blame()` action and its `gitsigns-blame` special buffer.
- Aerial's public `:AerialToggle!` command.

Steps:

1. Change the existing `|` callback in place. When the current buffer has a non-empty `buftype` and the current tab has
   another window, close the current window; otherwise call `MiniBufremove.delete()` as today. Keep it inline because it
   is a one-off action and describe it as `Close buffer or panel`. This handles `winfixbuf` panels without changing
   normal file-buffer semantics or trying to close the last window.
2. Change `<Leader>b` to an inline true toggle:
   - Search `vim.api.nvim_tabpage_list_wins(0)` for a window whose buffer has `filetype == 'gitsigns-blame'`.
   - If found, close that window with `vim.api.nvim_win_close(win, false)` and return. This must work even when the
     source window has focus, which is required by a mouse-menu invocation.
   - If none is found, call `require('gitsigns').blame()`.
   - Set `desc = 'Toggle blame'`.
3. Add `<Leader>o` mapped to `<cmd>AerialToggle!<cr>` with `desc = 'Toggle outline'`. The bang is intentional: opening
   the panel keeps focus in the source editor; Aerial's existing buffer-local `q` remains available when it is focused.
4. Run focused headless tests against tracked `AGENTS.md` and `.config/nvim/init.lua`:
   - Invoke `<Leader>b`; wait for Gitsigns; assert a `gitsigns-blame` window exists. Focus the source, invoke the mapping
     again, and assert the blame window is gone and source `scrollbind`, `wrap`, and `foldenable` are restored.
   - Open blame and invoke `|`; assert it closes without `E1513`. Invoke `|` on an ordinary file buffer and assert
     MiniBufremove behavior is unchanged.
   - Invoke `<Leader>o` twice; after the first invocation assert an `aerial` window exists and the source still has
     focus, and after the second assert it is gone.
5. Record results in the ExecPlan and commit the plan plus `.config/nvim/init.lua` as a local milestone commit such as
   `Make Neovim panels toggleable`.

Expected result: blame can be closed by the same lowercase `<Space>b` used to open it from either pane, `|` is the
universal close action the config already implies, and `<Space>o` toggles Aerial without an extra focus hop.

Recovery: if panel-type detection harms a plugin window, narrow the special case to `vim.bo.winfixbuf` or the verified
panel filetypes and rerun only the close tests. If the blame callback duplicates drawers, ensure the current-tab window
scan occurs before calling Gitsigns. Revert the milestone commit if behavior cannot be made stable without expanding
scope.

### Milestone 3: Mini Clue coverage

Affected file and interfaces:

- `.config/nvim/init.lua`: command-line `<CR>` keymap metadata and a `require('mini.clue').setup()` block after all
  custom keymaps.
- `MiniClue.gen_clues` public generators and Mini Clue trigger mappings.

Steps:

1. Add `desc = 'Accept command and clear search highlight'` to the existing command-line `<CR>` expression mapping so
   every explicit project keymap has useful metadata, even though a single chord has no continuation popup.
2. After all custom mappings, configure Mini Clue with these triggers:
   - `<Leader>` in Normal and Visual modes for every project leader mapping, including the new Aerial toggle.
   - `[` and `]` in Normal mode for quickfix and built-in bracket families.
   - `g` in Normal and Visual modes for the project's LSP/search mappings and built-ins.
   - `q` in Normal mode so the custom `qq` mapping is discoverable.
   - The official starter triggers for insert completion (`<C-x>`), marks (`'` and backtick), registers (`"` and
     `<C-r>`), window commands (`<C-w>`), and `z` commands.
3. Supply the official generators for square brackets, built-in completion, `g`, marks, registers, windows, and `z`.
   Rely on existing mapping `desc` fields for project actions. Do not duplicate individual clues or configure window
   fields that merely repeat Mini Clue defaults; retain its default one-second display delay.
4. Validate with one focused headless script:
   - `maparg()` reports a buffer-local Mini Clue query mapping for every configured trigger.
   - Custom continuations under leader, `g`, brackets, and `q` retain their expected descriptions.
   - `qa` starts recording macro register `a` and `q` stops it, proving the `q` trigger does not break recording.
   - New buffers and an LSP-attached JSON buffer still receive the trigger mappings after `BufWinEnter`/`LspAttach`.
5. Run `nvim --headless -u /workspace/.config/nvim/init.lua '+qa'` once for startup validation, then record and commit
   the milestone as `Add discoverable Neovim key clues`.

Expected result: pausing after any configured multi-key prefix presents applicable mappings and descriptions; all
single-key mappings remain immediate; macros, LSP attachment, and plugin buffer-local mappings continue to work.

Recovery: if one trigger shadows a later buffer-local plugin mapping, keep the rest of Mini Clue and call
`MiniClue.ensure_buf_triggers()` after that plugin attaches, as upstream recommends. If `q` is problematic despite the
verified test, remove only the `q` trigger and record `qq` as the one unavoidable non-clueable project mapping rather
than remapping the quit action without user direction.

### Milestone 4: Final focused validation and handoff

Affected files:

- `DEV_ENV_IMPROVEMENTS_EXECPLAN.md` and all task files changed by prior milestones; no new test fixtures should be
  committed.

Steps:

1. Reread this entire ExecPlan and inspect `git status --short` before final validation. Preserve unrelated user work.
2. Run each focused check once after all related edits:
   - `git diff --check`.
   - `bash -n docker/.bashrc`.
   - `npm --userconfig /workspace/.npmrc config get min-release-age` -> `3`.
   - `rg -n 'gcheckout' . --hidden -g '!/.git/**'` -> no matches.
   - A static package-list check -> one occurrence each of `npm`, `python3-venv`, and `yarnpkg` in the apt block.
   - `nvim --headless -u /workspace/.config/nvim/init.lua '+qa'` -> exit zero.
   - One consolidated Neovim scratch test covering JSON formatting, blame/open-close, special-buffer `|`, Aerial
     toggling, and Mini Clue trigger metadata/macro recording.
3. Confirm temporary exploration/test files remain outside the repository and `git status --short` contains only
   intentional task state.
4. Update Progress so every completed item is checked, put exact final evidence and the deferred Docker/zsh checks in
   Findings and Decisions, append the Audit Log, and create a final local commit only if this update covers uncommitted
   task changes. Never push.
5. Handoff must report commit(s), focused validation results, the temporary exploration journal path if it still exists,
   and the two environment-limited downstream checks:
   - `zsh -n .zshrc` on a host with zsh.
   - A development-image build outside this container, followed by `python3 -m venv /tmp/venv-smoke`,
     `npm --version`, and `yarnpkg --version` inside that disposable image.

Expected result: all source-level checks pass, no exploratory edit or unrelated file is committed, and only the real
Docker-image/zsh-host checks remain explicitly deferred.

Recovery: if the consolidated test fails, fix only the owning milestone and repeat that focused portion before the
final commit. If a prior milestone must be removed wholesale, use `git revert` in reverse milestone order. Do not hide
an environment limitation by weakening the expected result.

## Progress

- [x] Inspected the repository, installed tools/plugins, existing keymaps, aliases, apt list, and npm configuration.
- [x] Researched official npm, Debian, Neovim, nvim-lspconfig, Gitsigns, Aerial, and Mini Clue documentation/source.
- [x] Tested JSON LSP formatting, blame drawer failure/repairs, Aerial toggles, and Mini Clue triggers/macros.
- [x] Explored native-menu context, TUI right-click behavior, nested-menu limitations, and the `gx` collision; reverted
  the demo and dropped menu customization from scope because Mini Clue is sufficient.
- [x] Confirmed all experiments are outside the repository and task source files match `HEAD` before the plan commit.
- [x] Created this self-contained ExecPlan; implementation has not started.
- [ ] Milestone 1: update container packages, npm policy, and both alias surfaces.
- [ ] Milestone 2: implement and validate blame/panel close behavior and the Aerial mapping.
- [ ] Milestone 3: configure and validate Mini Clue.
- [ ] Milestone 4: run final focused validation and hand off deferred environment checks.

Exact next action: edit `docker/Dockerfile` to add `python3-venv` and `yarnpkg` in the apt list while retaining the one
existing `npm` entry, then continue Milestone 1 without touching Neovim yet.

## Findings and Decisions

### Verified facts and evidence

- Debian trixie publishes the requested packages: [python3-venv](https://packages.debian.org/trixie/python3-venv),
  [npm](https://packages.debian.org/trixie/npm), and [yarnpkg](https://packages.debian.org/trixie/yarnpkg).
- npm v11 documents `min-release-age` as a number of days and `before` as the absolute-date counterpart:
  [npm config documentation](https://docs.npmjs.com/cli/v11/using-npm/config/#min-release-age). The installed npm
  accepted `min-release-age = 3` from a scratch npmrc and returned `3`.
- The existing JSON LSP defaults run `vscode-json-language-server --stdio` for JSON/JSONC and explicitly advertise a
  formatter: [nvim-lspconfig jsonls at the explored revision](https://github.com/neovim/nvim-lspconfig/blob/85e732c62ac59ab7c12df71ddd020baa87948390/lsp/jsonls.lua#L24-L40).
  A real buffer attached one `jsonls` client, reported formatting support, and formatted compact JSON with four-space
  indentation. This closes the JSON question with no implementation change.
- Gitsigns creates blame as a `nofile`, fixed-buffer split and restores source options on `WinClosed`:
  [blame creation](https://github.com/lewis6991/gitsigns.nvim/blob/5be654f2232c10ddcad19c1607a67b6b4b78fc29/lua/gitsigns/actions/blame.lua#L479-L520) and
  [cleanup](https://github.com/lewis6991/gitsigns.nvim/blob/5be654f2232c10ddcad19c1607a67b6b4b78fc29/lua/gitsigns/actions/blame.lua#L647-L657).
  Tests reproduced `|`'s `E1513` and proved both planned close approaches.
- Aerial documents `AerialToggle!` as open/close while preserving source focus, and the installed command passed an
  open/close test: [Aerial mapping example](https://github.com/stevearc/aerial.nvim/blob/28fe6e822ae344544c379d60fcb13c9519a1f08a/README.md#L126-L137) and
  [command semantics](https://github.com/stevearc/aerial.nvim/blob/28fe6e822ae344544c379d60fcb13c9519a1f08a/README.md#L209-L218).
- Mini Clue is already available through `mini.nvim`. Its official starter covers leader, brackets, completion, `g`,
  marks, registers, windows, and `z`: [Mini Clue starter](https://github.com/nvim-mini/mini.nvim/blob/9d01f392b33fb2ba36fbc87fc0bf4453e63ffb0a/doc/mini-clue.txt#L232-L278).
  The explored setup also made `qq` clueable through a `q` trigger without breaking macro recording.
- Neovim 0.12.4 defaults to `mousemodel=popup_setpos`, creates a native right-click menu, and exposes `MenuPopup` for
  contextual adjustment: [mouse behavior](https://github.com/neovim/neovim/blob/v0.12.4/runtime/doc/options.txt#L4561-L4588),
  [native PopUp](https://github.com/neovim/neovim/blob/v0.12.4/runtime/doc/gui.txt#L730-L752), and
  [MenuPopup](https://github.com/neovim/neovim/blob/v0.12.4/runtime/doc/autocmd.txt#L855-L869).
  PTY tests proved the menu and flat custom entries render in the terminal. Clicking a nested `PopUp.Demo` parent,
  however, reproduced `E335: Menu not defined for Normal mode`; a chained `:popup` opened a second menu successfully
  but required a multi-stage menu architecture.
- Neovim's browser menu recursively invokes `gx`, while this repository changes Normal `gx` to Rename. The collision
  and its dynamic enablement are visible in [Neovim defaults](https://github.com/neovim/neovim/blob/v0.12.4/runtime/lua/vim/_core/defaults.lua#L488-L552).
  Preserving the original callback under `<Plug>` and retargeting the Normal menu opened the URL in a stubbed test and
  did not invoke Rename, but that experimental repair was reverted with the menu demo.

Detailed exploration journals and scratch programs are temporary and intentionally uncommitted:

- `/tmp/neovim-improvements-explore.Nlutuo/JOURNAL.md`
- `/tmp/native-menu-exploration/JOURNAL.md`

### Decisions

- Treat `npm` as already satisfied in the apt list; add only the two missing packages and never duplicate a config
  entry merely to make the diff mention all three nouns.
- Correct the requested npm key to `min-release-age`, with value `3` because the official unit is days.
- Remove every tracked `gcheckout` definition and its stale help text; retaining one would make behavior inconsistent.
- Leave `jsonls` configuration unchanged because the installed default is active and formatting passed. Adding
  `provideFormatter = true` locally would only repeat an upstream default.
- Implement both blame toggle and universal close fixes: the first gives same-key behavior, while the second repairs an
  already-advertised general action that currently crashes on the blame panel.
- Use Mini Clue's full supported starter plus the one project-specific `q` trigger, rather than hand-maintaining every
  leaf as a clue.
- Leave Neovim's native menu untouched and use Mini Clue as the sole keymap-discovery addition. Do not implement the
  tested flat catalog, chained-popup workaround, `MenuPopup` context logic, or `gx` browser-menu repair.

### Requested suggestions considered

#### Aerial toggle keymap

1. `<Leader>o` -> `AerialToggle!` (Recommended)

   Mnemonic for outline, currently free, shown by Mini Clue, and preserves source focus.

2. `<Leader>O` -> `AerialToggle`

   Focuses Aerial immediately for symbol navigation, but requires Shift and is less convenient for a glance-only panel.

3. `<F8>` -> `AerialToggle!`

   A direct function key independent of leader prefixes, but it is less discoverable and cannot benefit from the
   leader clue window.

#### Blame drawer close behavior

1. Same-key toggle plus context-aware `|` (Recommended)

   Reuses the current `<Leader>b`, works from either pane, and makes the existing close action honest.

2. Buffer-local `q` for `gitsigns-blame`

   Matches many plugin panels and Aerial, but only works while the blame pane has focus and adds another convention.

3. Dedicated uppercase `<Leader>B>` close mapping

   Satisfies the literal uppercase spelling, but splits one feature across two keys and does not solve the broken `|`
   action.

#### Right-click customization (dropped)

- A flat native catalog worked with real terminal mouse input but produced a long top-level menu.
- Dot-delimited native submenus are part of Neovim's menu model, but clicking the tested nested parent in the built-in
  TUI produced `E335` instead of descending into it.
- A launcher item using `:popup` successfully opened a second native menu, but the extra staged configuration and
  contextual state handling were disproportionate to the benefit. The user chose Mini Clue instead, so none of these
  approaches belongs in implementation.

### Inference and unresolved gaps

- Inference: adding Debian's `yarnpkg` intentionally exposes the `yarnpkg` executable, not necessarily a `yarn` alias,
  because the request uses the package name and no alias was requested.
- Inference: keeping focus with `AerialToggle!` best matches the existing side-panel toggles and makes mouse invocation
  less disruptive; the alternate focused behavior remains documented above.
- Unresolved until an external build: the pinned base plus live trixie repositories must still resolve all three apt
  packages together on every target architecture. Official package pages verify availability but cannot replace the
  prohibited Docker build.
- Unresolved until host validation: `.zshrc` syntax cannot be executed here because zsh is absent. The edit is a simple
  alias/message deletion, and the exact downstream check is specified.
- The known native browser-menu/Normal-`gx` collision remains outside scope because menu customization was explicitly
  dropped. Mini Clue does not depend on native menu behavior or external UI rendering.

## Audit Log

- 2026-09-11 UTC — Created `DEV_ENV_IMPROVEMENTS_EXECPLAN.md` from clean repository state after local and upstream
  exploration. Recorded all requested package, npm, alias, JSON, blame, Aerial, Mini Clue, and native-menu work;
  resolved the npm key, Aerial mapping, blame close strategy, Mini Clue trigger coverage, native menu catalog, and `gx`
  collision; documented focused validation, expected results, exclusions, recovery, deferred environment checks, and
  the exact next action. No implementation or tracked experimental change is included in this audit entry.
- 2026-09-11 UTC — Corrected the `PopUp.Search` catalog's `<Leader>s` notation during pre-commit review so the plan
  names the existing mapping exactly.
- 2026-09-11 UTC — Removed native right-click customization, its `gx` repair, its former Milestone 4, and all associated
  final validation from the implementation plan at the user's direction. Recorded that flat entries worked, nested
  TUI selection reproduced `E335`, and a chained `:popup` worked but was too complex; made Mini Clue the sole planned
  discovery interface, renumbered final validation to Milestone 4, and reverted the uncommitted menu demo from
  `.config/nvim/init.lua`.
