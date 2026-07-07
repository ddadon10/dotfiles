# Autocomplete
autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit

# Aliases
alias rm='rm -i'
alias ls='ls -aF'

# Load git-related ssh keys into the default ssh agent
if ! ssh-add -l >/dev/null 2>&1; then
  ssh-add --apple-use-keychain "${HOME}/.ssh/github_ed25519" "${HOME}/.ssh/azure_rsa"
fi

# Git
git() { echo "Git is disabled on the host. Use g to run git in a container" >&2; return 1; }

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
    --env "GIT_USER_NAME=$(/usr/bin/git config --global user.name)" \
    --env "GIT_USER_EMAIL=$(/usr/bin/git config --global user.email)" \
    --env "DEV_WEB_PORT=${dev_web_port}" \
    --publish "127.0.0.1:${dev_web_port}:${dev_web_port}" \
    --mount "type=bind,src=${PWD},dst=/workspace" \
    --mount "type=bind,src=${HOME}/.codex,dst=/root/.codex" \
    --mount "type=bind,src=${HOME}/.config/github-copilot,dst=/root/.config/github-copilot" \
    --workdir /workspace \
    "${DEV_NAME:-ddadon/dev}"
}

# Git Client
g() {
  docker run \
    --rm \
    --interactive \
    --tty \
    --mount "type=bind,src=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock" \
    --mount "type=bind,src=${PWD},dst=/workspace" \
    --workdir /workspace \
    "${GITCLIENT_NAME:-ddadon/gitclient}"
}

# Shell customization
export PS1="%n@mbp %~ %% "
