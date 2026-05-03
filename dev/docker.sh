#!/usr/bin/env bash
set -euo pipefail

git_name=$(git config --global user.name 2>/dev/null || true)
git_email=$(git config --global user.email 2>/dev/null || true)
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "${script_dir}/.." && pwd)
image="${DEV_IMAGE:-dev}"
host="${CODE_HOST:-127.0.0.1}"
host_port="${CODE_PORT:-8000}"
container_port="${CODE_CONTAINER_PORT:-8000}"
workspace="${CODE_WORKSPACE:-${PWD}}"

mkdir -p "${HOME}/.codex"

if [[ "${DEV_SKIP_BUILD:-0}" != "1" ]] && ! docker image inspect "${image}" >/dev/null 2>&1; then
    docker build --file "${repo_root}/dev/Dockerfile" --tag "${image}" "${repo_root}"
fi

docker_args=(
    --rm
    --interactive
    --tty
    --env "GIT_USER_NAME=${git_name}"
    --env "GIT_USER_EMAIL=${git_email}"
    --env "CODE_HOST=0.0.0.0"
    --env "CODE_PORT=${container_port}"
    --env "CODE_WORKSPACE=/workspace"
    --publish "${host}:${host_port}:${container_port}"
    --mount type=bind,src="${workspace}",dst=/workspace
    --mount type=bind,src="${HOME}/.codex",dst=/root/.codex
    --workdir /workspace
  )
docker run "${docker_args[@]}" "${image}" "$@"
