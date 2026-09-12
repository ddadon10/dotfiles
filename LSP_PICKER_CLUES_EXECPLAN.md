# LSP Picker and Clue Cleanup

## Purpose and Context

The goal is to make LSP discovery consistent without changing the meaning of the existing `g` layer:

- `g` remains the cursor-dependent movement/action root. In particular, `gt` remains mapped to the existing fzf-lua
  type-definition action and is not moved, removed, or repurposed.
- `<Space>` remains the picker root. A new `<Space>l` group will contain only fzf-lua LSP pickers; invoking one of
  these mappings must open a picker even when the LSP returns a single result.
- MiniClue should show useful descriptions instead of raw or blank runtime mapping text. Keep the behavior of `gO`,
  `g%`, and Neovim's `gr` mappings, but label them as `Document symbols`, `Previous matching group`, and `+LSP`.
- Existing cursor actions, Git pickers, general pickers, panel mappings, and buffer-local clue behavior remain unchanged.

The only implementation file is `.config/nvim/init.lua`. At plan creation, the branch is
`20260911-improvement` at `4157fae`, the worktree is clean, MiniClue is configured with `g`, `<Space>`, and
`<Leader>` triggers, and the installed fzf-lua exposes all pickers named below. MiniClue has no exclusion/filter API
for individual mappings: it discovers every mapping below a trigger. Description overrides preserve the requested
behavior without adding a private MiniClue patch.

## Plan of Work

### Milestone 1: Add the LSP picker namespace

Edit the global picker mappings in `.config/nvim/init.lua` to add the following Normal-mode mappings. Every mapping
must have the listed capitalized description so MiniClue can display it directly.

| Mapping | fzf-lua function | Description |
|---|---|---|
| `<Space>la` | `lsp_finder` | `All locations` |
| `<Space>ld` | `lsp_definitions` | `Definitions` |
| `<Space>lD` | `lsp_declarations` | `Declarations` |
| `<Space>li` | `lsp_implementations` | `Implementations` |
| `<Space>lr` | `lsp_references` | `References` |
| `<Space>lt` | `lsp_typedefs` | `Type definitions` |
| `<Space>ls` | `lsp_document_symbols` | `Document symbols` |
| `<Space>lw` | `lsp_live_workspace_symbols` | `Workspace symbols` |
| `<Space>lI` | `lsp_incoming_calls` | `Incoming calls` |
| `<Space>lO` | `lsp_outgoing_calls` | `Outgoing calls` |

For location-oriented pickers, reuse `lsp_opts(title, false)`. Passing `false` as `jump1` is required here: unlike a
`g` action, a `<Space>l` mapping is explicitly a picker and must not jump directly when there is one result. Reusing
`lsp_opts` also retains the existing JDT URI presentation and Kotlin-generated-result filtering. Use ordinary fzf-lua
options with an explicit title for document and workspace symbol pickers, whose entries should retain fzf-lua's native
symbol formatting.

Do not add diagnostics or code actions to this group. They already have coherent homes at `<Space>d` and `ga`. Do not
add both live and non-live workspace-symbol pickers; the live picker is the more useful interactive form and avoids a
duplicate choice. Do not add subtype/supertype pickers until there is an expressed need for those niche operations.

Validation for this milestone:

- Start Neovim headlessly with the real configuration and inspect `maparg()` for all ten mappings.
- Confirm every mapping is Normal-mode, has the exact description above, and invokes the intended fzf-lua function.
- Stub or instrument fzf-lua in a focused test to verify location mappings receive `jump1 = false`; do not require a
  live language server merely to validate mapping construction.
- In an attached LSP buffer, invoke at least document symbols, live workspace symbols, definitions, and references and
  confirm that each opens a picker.

Recovery: remove only the ten `<Space>l...` mappings. No plugin or package change is involved.

### Milestone 2: Make the picker group discoverable

Add `{ mode = 'n', keys = '<Space>l', desc = '+LSP' }` to the existing MiniClue `clues` list. Do not make `<Space>l`
itself executable; it is a namespace whose children are all pickers. Keep the existing `<Space>` trigger and the
250 ms clue delay unchanged.

Validation for this milestone:

- Query the `<Space>` clue window and confirm `l` is shown as `+LSP`.
- Query `<Space>l` and confirm all ten picker entries appear with their capitalized descriptions.
- Confirm no direct `<Space>l` mapping exists and waiting at the prefix cannot unexpectedly execute a picker.

Recovery: remove the single `<Space>l` group clue; the mappings can remain functional without the group label.

### Milestone 3: Clarify the existing `g` clues without changing behavior

Keep the existing `gt` mapping exactly as it is: it continues calling fzf-lua's `lsp_typedefs` picker with the
existing `lsp_opts('Type Definitions')` options and remains described as `Go to type definition`. It is part of the
cursor-dependent action layer, not the picker layer.

Add `{ mode = 'n', keys = 'gr', desc = '+LSP' }` to MiniClue's configured clues. `gr` is a prefix with descendant
mappings rather than an exact mapping, so a group clue is the supported way to name it.

Use `MiniClue.set_mapping_desc()` to update, without replacing, these existing Normal-mode mappings:

- `gO` -> `Document symbols` (Neovim's `vim.lsp.buf.document_symbol()` mapping).
- `g%` -> `Previous matching group` (Matchit's `<Plug>(MatchitNormalBackward)` mapping).

Matchit loads after `init.lua`, so apply both mapping-description updates from a single one-shot `VimEnter` autocmd
after runtime plugins have loaded. Guard each update by checking that the mapping exists, so startup remains robust if
a runtime mapping is unavailable. `MiniClue.set_mapping_desc()` uses `maparg()` plus `mapset()`, preserving the
original callbacks, right-hand sides, remapping flags, and behavior. Do not delete `gO` or `g%`, do not disable
Matchit, and do not patch MiniClue internals.

Validation for this milestone:

- After `VimEnter`, assert that `gt` still has its original callback and description.
- Assert that `gO` still has a callback and is described as `Document symbols`.
- Assert that `g%` still resolves to `<Plug>(MatchitNormalBackward)` and is described as
  `Previous matching group`.
- Open the `g` clue window and confirm `t`, `O`, `%`, and the `r` group have the intended text with no blank `%` entry
  or raw `vim.lsp.buf.document_symbol()` label.
- Exercise `%` and `g%` in a Matchit-supported file and confirm forward and backward matching still work.

Recovery: remove the `gr` group clue and the one-shot description autocmd. The underlying mappings require no
restoration because `MiniClue.set_mapping_desc()` changes metadata only for the running Neovim instance.

### Milestone 4: Final integration validation

Run one focused validation pass after all edits:

1. Run `git diff --check`.
2. Start Neovim headlessly with `.config/nvim/init.lua` and assert startup has no errors.
3. Inspect all affected mappings and their descriptions after `VimEnter`.
4. Verify MiniClue retains its `g` and `<Space>` triggers and 250 ms delay.
5. Perform a short interactive LSP smoke test for the picker-only behavior and clue presentation.
6. Review the final diff to confirm there are no plugin, statusline, tabline, or unrelated keymap changes.

If a particular LSP server does not implement declarations, calls, or workspace symbols, an empty/unsupported picker
is an expected server capability result rather than a mapping failure. Validate the mapping callback independently and
use supported pickers for the interactive smoke test.

## Progress

- [x] Drafted and reviewed the corrected mapping model against the current configuration and installed plugin APIs.
- [x] Milestone 1: Added the ten picker-only `<Space>l...` mappings.
- [x] Milestone 2: Added the `<Space>l` MiniClue group.
- [x] Milestone 3: Preserved `gt` and customized the `gr`, `gO`, and `g%` clue text.
- [x] Milestone 4: Ran focused headless and interactive validation.

Exact next action: none; implementation and validation are complete, pending user review.

## Findings and Decisions

- Verified: `gt` is currently a custom fzf-lua type-definition mapping with description `Go to type definition`; it
  is not the native tab-page command in this configuration.
- Verified: Neovim currently provides `gO` as a callback to `vim.lsp.buf.document_symbol()` with the raw function name
  as its description.
- Verified: Matchit provides `g%` as `<Plug>(MatchitNormalBackward)` after `init.lua` is sourced and gives it no
  description, which is why MiniClue shows a bare `%` entry.
- Verified: `gr` has no exact mapping; MiniClue derives it as a group from Neovim's descendant LSP mappings.
- Verified: MiniClue merges configured clues with global and buffer-local mappings and provides no supported per-key
  exclusion filter. `MiniClue.set_mapping_desc()` is its public API for relabeling existing mappings.
- Decision: preserve and relabel functional `g` mappings rather than deleting them merely to alter clue presentation.
- Decision: `<Space>l` contains pickers only and forces `jump1 = false`; `g` retains cursor-dependent navigation and
  may intentionally overlap in subject matter.
- Decision: keep the picker set focused. Diagnostics and code actions retain their established keys, live workspace
  symbols replace a redundant pair of workspace-symbol choices, and type-hierarchy pickers are deferred.
- Outcome: all ten `<Space>l...` callbacks call the planned fzf-lua function, supply the expected title, and set
  `jump1 = false`. There is no direct `<Space>l` mapping.
- Outcome: a rendered MiniClue window showed `All locations`, `Declarations`, `Definitions`, `Incoming calls`,
  `Implementations`, `Outgoing calls`, `References`, `Document symbols`, `Type definitions`, and `Workspace symbols`.
- Outcome: the rendered `g` clue window retained `gt` as `Go to type definition` and showed `gO` as
  `Document symbols`, `gr` as `+LSP`, and `g%` as `Previous matching group`.
- Outcome: `gO` retained its callback, `g%` retained `<Plug>(MatchitNormalBackward)`, and an HTML-buffer test confirmed
  `%` and `g%` still navigate forward and backward between matching tags.
- Outcome: an interactive Neovim session loaded with the workspace configuration attached `lua_ls`; `<Space>ls`
  opened a populated fzf-lua document-symbol picker. Headless startup, mapping assertions, MiniClue's 250 ms delay,
  and `git diff --check` also passed.

## Audit Log

- 2026-09-12: Created this ExecPlan after correcting the proposed design: retained `gt` under the cursor-dependent `g`
  root, defined `<Space>l` as a picker-only namespace, and replaced deletion/hiding of useful runtime mappings with
  supported MiniClue description customization. No implementation files were changed.
- 2026-09-12: Implemented all four milestones in `.config/nvim/init.lua`. Added the ten picker-only LSP mappings and
  both group clues, used a guarded one-shot `VimEnter` autocmd to relabel the late runtime mappings without replacing
  them, and completed deterministic, rendered-clue, Matchit, and live `lua_ls`/fzf-lua validation.
