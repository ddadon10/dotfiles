#!/usr/bin/env bash
set -euo pipefail

name="${DEV_NAME:-dev}"

docker build --file dev/Dockerfile --tag "${name}" .
