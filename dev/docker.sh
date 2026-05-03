#!/usr/bin/env bash
set -euo pipefail

git_name=$(git config --global user.name 2>/dev/null || true)
git_email=$(git config --global user.email 2>/dev/null || true)

mkdir -p "${HOME}/.codex"

if ! docker image inspect dev >/dev/null 2>&1; then
    docker build --file dev/Dockerfile --tag dev .
fi

docker_args=(
    --rm
    --interactive
    --tty
    --env "GIT_USER_NAME=${git_name}"
    --env "GIT_USER_EMAIL=${git_email}"
    --env "CODE_HOST=0.0.0.0"
    --env "CODE_PORT=8000"
    --env "CODE_WORKSPACE=/workspace"
    --publish "127.0.0.1:8000:8000"
    --mount type=bind,src="${PWD}",dst=/workspace
    --mount type=bind,src="${HOME}/.codex",dst=/root/.codex
    --workdir /workspace
  )
docker run "${docker_args[@]}" dev "$@"
