# Aliases
alias rm='rm -i'
alias ls='ls -aF'

# Dev Env
dev() {
  while :; do
    dev_web_port=$((RANDOM % 16384 + 49152))
    lsof -nP -iTCP:"$dev_web_port" -sTCP:LISTEN >/dev/null 2>&1 || break
  done

  mkdir -p "${HOME}/.codex"
  mkdir -p "${HOME}/.config/github-copilot"

  docker run \
    --rm \
    --interactive \
    --tty \
    --env "GIT_USER_NAME=$(git config --global user.name)" \
    --env "GIT_USER_EMAIL=$(git config --global user.email)" \
    --env "DEV_WEB_PORT=${dev_web_port}" \
    --publish "127.0.0.1:${dev_web_port}:${dev_web_port}" \
    --mount "type=bind,src=${PWD},dst=/workspace" \
    --mount "type=bind,src=${HOME}/.codex,dst=/root/.codex" \
    --mount "type=bind,src=${HOME}/.config/github-copilot,dst=/root/.config/github-copilot" \
    --workdir /workspace \
    "${DEV_NAME:-ddadon/dev}"
}

# Shell customization
export PS1="%n@mbp %~ %% "
