#!/usr/bin/env bash
set -euo pipefail

docker build --file dev/Dockerfile --tag "${DEV_NAME:-ddadon/dev}" .
docker build --file dev/Git.Dockerfile --tag "${GITCLIENT_NAME:-ddadon/gitclient}" .
