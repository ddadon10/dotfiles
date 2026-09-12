# Docker Image Push Timeout Findings

## Symptom

Pushing `ddadon/dev:current` to Docker Hub intermittently fails while committing a layer:

```text
net/http: timeout awaiting response headers
```

The failure occurs on the final registry `PUT`. Retrying can advance to a different layer, and layers that previously
timed out can subsequently appear as `Layer already exists`. Setting `max-concurrent-uploads` to `1` does not resolve
the problem, so concurrent uploads are not the cause.

This behavior is consistent with the Docker client timing out while waiting for the registry to confirm a completed
large-layer upload.

## Image Evidence

`docker image history` reports these notable uncompressed layers:

- Main Debian package installation: 3.57 GB
- Google Cloud CLI: 721 MB
- Firebase tools: 447 MB
- OpenAI Codex npm package: 434 MB
- lazygit Go installation: 397 MB
- pgweb Go installation: 357 MB
- Language-server npm installation: 211 MB
- Neovim initialization: 101 MB

The running image uses approximately 6.3 GB:

- `/usr`: 5.0 GB
- `/root`: 1.2 GB

Approximately 1 GB under `/root` is disposable package/build cache:

- `/root/.cache/go-build`: 347 MB
- `/root/go/pkg`: 322 MB
- `/root/.npm`: 366 MB

The main apt layer contains several independently large toolchains and applications, including GCC, Chromium, Java,
Go, PostgreSQL, and Node.js.

## Recommended Changes

Apply both changes below; they solve different parts of the problem.

1. Keep build caches out of image layers.
   - Mount `/root/.cache/go-build` and `/root/go/pkg/mod` as BuildKit caches during `go install`.
   - Mount `/root/.npm` as a BuildKit cache during each `npm install -g`.
   - Cache mounts retain reusable build data between builds without committing it to the resulting image.
   - If cache mounts cannot be used, remove each cache in the same `RUN` instruction that creates it. Deleting it in a
     later instruction does not shrink the original layer.

2. Split the 3.57 GB apt installation into logical `RUN` instructions.
   - Separate large stacks such as Chromium, GCC/build tools, Go, Java, PostgreSQL, and Node.js from the smaller CLI
     utilities.
   - Run `apt-get update`, install the corresponding group, and remove `/var/lib/apt/lists/*` within every instruction.
   - This does not substantially reduce the installed package footprint, but it replaces one oversized upload with
     multiple smaller layers.

Using both approaches should reduce the image by roughly 1 GB of cache data and substantially lower its maximum layer
size. The rebuilt image must be inspected again with `docker image history` to verify the resulting layer sizes before
testing another push.
