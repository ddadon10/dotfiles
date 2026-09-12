# Purpose and Context

Reduce `ddadon/dev:current` by preventing disposable npm and Go build caches from being committed to image layers in
`docker/Dockerfile`. The current image is approximately 6.3 GB and contains about 1 GB of cache data under `/root`:

- `/root/.npm`: 366 MB
- `/root/.cache/go-build`: 347 MB
- `/root/go/pkg`: 322 MB, primarily the Go module cache

The observable result is a rebuilt image that still contains and can run all globally installed npm and Go tools, but
does not contain meaningful data in those three cache locations. The corresponding npm and Go layers should be
smaller in `docker image history`. This plan does not split the 3.57 GB apt layer; that is an independent follow-up.

Assumptions:

- Builds use BuildKit, as shown by the existing build history and heredoc Dockerfile instructions.
- BuildKit cache mounts may persist package data between builds but do not commit mounted data to the image layer.
- `ddadon/dev:current` remains the local image tag used by `build.sh`.
- Existing untracked debugging outputs and `DOCKER_IMAGE_DEBUGGING.md` are user/task evidence and must not be altered
  or included in an unrelated commit.

# Plan of Work

## Milestone 1: Keep npm cache out of npm installation layers

Affected file and interface: `docker/Dockerfile`; every `RUN npm install -g ...` instruction.

- Retain the existing build check directive without adding a Dockerfile syntax directive; the current Docker Desktop
  frontend already supports cache mounts.
- Add `--mount=type=cache,target=/root/.npm` to each global npm installation instruction:
  - TypeScript
  - language servers
  - Firebase tools
  - ccusage
  - OpenAI Codex
- Keep the installations as separate layers. Combining them would create another unnecessarily large layer.
- Do not add `npm cache clean --force`: the mounted cache is excluded from the layer already, and retaining it in the
  BuildKit cache improves later build performance.

Validation:

- Build the image successfully with `docker build --file docker/Dockerfile --tag ddadon/dev:current .`.
- Run `typescript-language-server --version`, `firebase --version`, `ccusage --version`, and `codex --version` in a
  temporary container. Expected result: every executable starts successfully.
- Run `du -sh /root/.npm` in a temporary container. Expected result: the directory is absent or effectively empty.

Recovery: remove the npm `--mount` options if the builder reports that RUN mounts are unsupported. The fallback is to
append `npm cache clean --force` to each corresponding `RUN`, never as a later standalone instruction.

## Milestone 2: Keep Go caches out of Go installation layers

Affected file and interface: `docker/Dockerfile`; the lazygit and pgweb `go install` instructions.

- Add both cache mounts to each Go installation instruction:
  - `--mount=type=cache,target=/root/.cache/go-build`
  - `--mount=type=cache,target=/root/go/pkg/mod`
- Keep the executable destination unchanged at `/root/go/bin`, which is already on `PATH` through the Dockerfile's
  `ARG PATH`. Only cache directories are mounted; installed binaries remain in the image.
- Keep lazygit and pgweb in separate instructions so each executable remains independently cacheable and neither
  produces one combined upload layer.

Validation:

- Run `lazygit --version` and `pgweb --version` in a temporary container. Expected result: both executables start
  successfully.
- Inspect `/root/.cache/go-build` and `/root/go/pkg` in a temporary container. Expected result: the build cache and
  module cache are absent or effectively empty, while `/root/go/bin/lazygit` and `/root/go/bin/pgweb` exist.

Recovery: remove the Go `--mount` options if unsupported. The fallback is to append
`go clean -cache -modcache` to each corresponding `RUN`; cleanup must occur in the same instruction that creates the
cache.

## Milestone 3: Verify image and layer reduction

Affected interfaces: the local `ddadon/dev:current` image and Docker CLI inspection output.

- Capture `docker image history ddadon/dev:current` after the rebuild.
- Compare npm and Go layer sizes with the recorded baseline: Codex 434 MB, Firebase 447 MB, lazygit 397 MB, pgweb
  357 MB, language servers 211 MB, ccusage 7.17 MB, and TypeScript 60.5 MB.
- Measure the rebuilt filesystem with `du -x -h --max-depth=1 /` and the cache paths from a temporary container.
- Expected result: roughly 1 GB less cache data in the final filesystem. Exact layer savings may differ because image
  history reports uncompressed changes and package versions can change.
- Do not push during this cache-only milestone. The later apt-layer work must address the remaining 3.57 GB layer
  before using a registry push as the final timeout test.

Recovery: retain the previously built/tagged image until validation passes. If a tool is missing, compare the affected
instruction with the prior Dockerfile and revert only its cache mount before rebuilding.

# Progress

- [x] Record the cache-size baseline and identify the affected Dockerfile instructions.
- [x] Add npm cache mounts to all global npm installations.
- [x] Add Go build and module cache mounts to both Go installations.
- [ ] Build and run focused executable/cache validation.
- [ ] Record post-build image and layer sizes.
- [ ] Exact next action: build `ddadon/dev:current` on the Docker-capable macOS host.

# Findings and Decisions

- Verified: `/root/.npm`, `/root/.cache/go-build`, and `/root/go/pkg` account for approximately 1 GB in the current
  image.
- Verified: deleting these directories in a later `RUN` would not shrink the layers that introduced them.
- Decision: use BuildKit cache mounts as the primary solution because they exclude cache contents from image layers
  while preserving reusable cache data for subsequent builds.
- Decision: keep existing install instructions separate to avoid trading cache removal for larger combined layers.
- Decision: defer apt-layer splitting so cache removal can be implemented and measured independently.
- Decision: do not add `# syntax=docker/dockerfile:1`; it repeats current Docker Desktop behavior and is unnecessary
  for this repository's existing BuildKit frontend.
- Validation: static checks confirmed all five npm installs have an npm cache mount, both Go installs have build and
  module cache mounts, and `git diff --check` passes.
- Unresolved until the macOS build: exact image-size reduction and whether every tool's version command exits cleanly.

# Audit Log

- 2026-09-12: Created the cache-only implementation plan from the measured image baseline. No implementation files
  were changed.
- 2026-09-12: Corrected the Go fallback recovery wording so the cleanup requirement is unambiguous.
- 2026-09-12: Added the Dockerfile syntax directive, npm cache mounts to five npm installations, and Go build/module
  cache mounts to both Go installations. Static validation passed; Docker build validation remains pending because
  Docker is unavailable in the workspace container.
- 2026-09-12: Removed the explicit Dockerfile syntax directive at the user's request because the current frontend
  already supports cache mounts; retained all npm and Go cache mounts.
