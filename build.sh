#!/usr/bin/env bash
set -euo pipefail

docker tag ddadon/dev ddadon/dev:previous >/dev/null 2>&1 || true
docker build --file docker/Dockerfile --tag ddadon/dev .

docker tag ddadon/gitclient ddadon/gitclient:previous >/dev/null 2>&1 || true
docker build --file docker/Git.Dockerfile --tag ddadon/gitclient .

docker tag ddadon/azureclient ddadon/azureclient:previous >/dev/null 2>&1 || true
docker build --file docker/Azure.Dockerfile --tag ddadon/azureclient .
