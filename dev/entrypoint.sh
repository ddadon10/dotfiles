#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -n "${GIT_USER_NAME:-}" ]]; then
  git config --global user.name "$GIT_USER_NAME"
fi

if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi

if [[ "$#" -gt 0 ]]; then
  exec "$@"
fi

host="${CODE_HOST:-0.0.0.0}"
port="${CODE_PORT:-8000}"
workspace="${CODE_WORKSPACE:-/workspace}"
user_data_dir="${VSCODE_USER_DATA_DIR:-/opt/vscode-user-data}"
extensions_dir="${VSCODE_EXTENSIONS_DIR:-/opt/vscode-extensions}"
server_data_dir="${VSCODE_SERVER_DATA_DIR:-/opt/vscode-server}"
cli_data_dir="${VSCODE_CLI_DATA_DIR:-/opt/vscode-cli}"

mkdir -p "$workspace" "$user_data_dir" "$extensions_dir" "$server_data_dir" "$cli_data_dir"
export VSCODE_CLI_DATA_DIR="$cli_data_dir"

code_args=(
  --no-sandbox
  --user-data-dir "$user_data_dir"
  --extensions-dir "$extensions_dir"
  serve-web
  --host "$host"
  --port "$port"
  --accept-server-license-terms
  --server-data-dir "$server_data_dir"
  --disable-telemetry
)

if [[ -n "${CODE_CONNECTION_TOKEN:-}" ]]; then
  code_args+=(--connection-token "$CODE_CONNECTION_TOKEN")
else
  code_args+=(--without-connection-token)
fi

code_args+=(--default-folder "$workspace")

exec code "${code_args[@]}"
