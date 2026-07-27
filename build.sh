#!/usr/bin/env bash
set -euo pipefail

docker build --file docker/Dockerfile --tag "${DEV_NAME:-ddadon/dev}" .
docker build --file docker/Git.Dockerfile --tag "${GITCLIENT_NAME:-ddadon/gitclient}" .
docker build --file docker/Azure.Dockerfile --tag "${AZURE_NAME:-ddadon/azure}" .
