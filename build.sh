#!/usr/bin/env bash
set -euo pipefail

docker build --file dev/Dockerfile --tag "${DEV_NAME:-dev}" .
