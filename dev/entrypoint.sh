#!/usr/bin/env bash
set -Eeuo pipefail

git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

export VSCODE_CLI_DATA_DIR=/opt/vscode-cli
export PROMPT_DIRTRIM=2
export PS1='\u@\dev:\w\$ '

code \
  serve-web \
  --host 0.0.0.0 \
  --port 8080 \
  --without-connection-token \
  --accept-server-license-terms \
  --server-data-dir /opt/vscode-server \
  --disable-telemetry
