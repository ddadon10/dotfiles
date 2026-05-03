#!/usr/bin/env bash
set -Eeuo pipefail

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

if [[ "$#" -gt 0 ]]; then
  exec "$@"
fi

mkdir -p /workspace /opt/vscode-user-data /opt/vscode-extensions /opt/vscode-server /opt/vscode-cli
export VSCODE_CLI_DATA_DIR=/opt/vscode-cli

exec code \
  --no-sandbox \
  --user-data-dir /opt/vscode-user-data \
  --extensions-dir /opt/vscode-extensions \
  serve-web \
  --host 0.0.0.0 \
  --port 8000 \
  --without-connection-token \
  --accept-server-license-terms \
  --server-data-dir /opt/vscode-server \
  --disable-telemetry \
  --default-folder /workspace
