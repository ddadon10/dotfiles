#!/usr/bin/env bash
set -Eeuo pipefail

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

if [[ "$#" -gt 0 ]]; then
  exec "$@"
fi

user_data_dir="${VSCODE_USER_DATA_DIR:-/opt/vscode-user-data}"
extensions_dir="${VSCODE_EXTENSIONS_DIR:-/opt/vscode-extensions}"
server_data_dir="${VSCODE_SERVER_DATA_DIR:-/opt/vscode-server}"
cli_data_dir="${VSCODE_CLI_DATA_DIR:-/opt/vscode-cli}"

mkdir -p /workspace "$user_data_dir" "$extensions_dir" "$server_data_dir" "$cli_data_dir"
export VSCODE_CLI_DATA_DIR="$cli_data_dir"

exec code \
  --no-sandbox \
  --user-data-dir "$user_data_dir" \
  --extensions-dir "$extensions_dir" \
  serve-web \
  --host 0.0.0.0 \
  --port 8000 \
  --without-connection-token \
  --accept-server-license-terms \
  --server-data-dir "$server_data_dir" \
  --disable-telemetry \
  --default-folder /workspace
