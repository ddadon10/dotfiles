# Some useful aliases
alias rm='rm -i'
alias ls='ls -aF'

# Dev Env

codesrv() {
  docker run \
    --interactive \
    --tty \
    --name codesrv \
    --env "GIT_USER_NAME=$(git config --global user.name)" \
    --env "GIT_USER_EMAIL=$(git config --global user.email)" \
    --publish "127.0.0.1:8080:8080" \
    --publish "127.0.0.1:8081:8081" \
    --mount "type=bind,src=${HOME}/code,dst=/workspace" \
    --mount "type=bind,src=${HOME}/.codex,dst=/root/.codex" \
    --workdir /workspace \
    dev
}

dev() {
  local dev_web_port
  while :; do
    dev_web_port=$((RANDOM % 16384 + 49152))
    lsof -nP -iTCP:"$dev_web_port" -sTCP:LISTEN >/dev/null 2>&1 || break
  done

  echo "DEV_WEB_PORT=${dev_web_port} URL=http://127.0.0.1:${dev_web_port}"

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
    --workdir /workspace \
    --entrypoint /bin/bash \
    dev
}

# Shell customization
export PS1="%n@mbp %~ %% "
