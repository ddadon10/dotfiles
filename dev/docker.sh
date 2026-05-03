#!/usr/bin/env bash
set -euo pipefail

git_name=$(git config --global user.name)
git_email=$(git config --global user.email)
name="${DEV_NAME:-dev}"

mkdir -p "${HOME}/.codex"

docker build --tag "${name}" .

docker_args=(
    --rm
    --interactive
    --tty
    --name "${name}"
    --env "GIT_USER_NAME=${git_name}"
    --env "GIT_USER_EMAIL=${git_email}"
    --publish "127.0.0.1:8000:8000"
    --publish "127.0.0.1:18080:18080"
    --mount "type=bind,src=${PWD%/*},dst=/workspace"
    --mount "type=bind,src=${HOME}/.codex,dst=/root/.codex"
    --workdir /workspace
)
docker run "${docker_args[@]}" "${name}" "$@"
