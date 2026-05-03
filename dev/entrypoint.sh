#!/usr/bin/env bash
set -Eeuo pipefail

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

if [[ "$#" -gt 0 ]]; then
  exec "$@"
fi

mkdir -p /workspace /opt/vscode-server/data/User /opt/vscode-server/extensions /opt/vscode-cli
export VSCODE_CLI_DATA_DIR=/opt/vscode-cli

exec code \
  serve-web \
  --host 0.0.0.0 \
  --port 8080 \
  --commit-id "$(< /opt/vscode-cli/serve-web/commit-id)" \
  --without-connection-token \
  --accept-server-license-terms \
  --server-data-dir /opt/vscode-server \
  --disable-telemetry \
  --default-folder /workspace
