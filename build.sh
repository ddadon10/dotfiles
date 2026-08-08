#!/usr/bin/env bash
set -euo pipefail

docker build --file docker/Dockerfile --tag "${DEV_NAME:-ddadon/dev}" .
container build --file docker/Git.Dockerfile --tag "${GITCLIENT_NAME:-ddadon/gitclient}" .
container build --file docker/Azure.Dockerfile --tag "${AZURECLIENT_NAME:-ddadon/azureclient}" .
