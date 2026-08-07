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
git() { echo "Git is disabled on the host. Use gclone, gfetch, glsremote, gpull, or gpush" >&2; return 1; }

# Dev Env
dev() {
  while :; do
    dev_web_port=$((RANDOM % 16384 + 49152))
    lsof -nP -iTCP:"$dev_web_port" -sTCP:LISTEN >/dev/null 2>&1 || break
  done

  docker run \
    --rm \
    --interactive \
    --tty \
    --detach-keys "ctrl-_" \
    --env "GIT_USER_NAME=$(/usr/bin/git config --global user.name)" \
    --env "GIT_USER_EMAIL=$(/usr/bin/git config --global user.email)" \
    --env "DEV_PROJECT_ROOT=${PWD}" \
    --env "DEV_WEB_PORT=${dev_web_port}" \
    --publish "127.0.0.1:${dev_web_port}:${dev_web_port}" \
    --mount "type=bind,src=${PWD},dst=/workspace" \
    --mount "type=volume,src=dev-codex-home,dst=/root/.codex" \
    --mount "type=volume,src=dev-data,dst=/data" \
    --mount "type=volume,src=dev-maven,dst=/root/.m2" \
    --workdir /workspace \
    "${DEV_NAME:-ddadon/dev}"
}

# Git Client
_gitclient() {
  docker run \
    --rm \
    --interactive \
    --tty \
    --detach-keys "ctrl-_" \
    --mount "type=bind,src=/run/host-services/ssh-auth.sock,target=/run/host-services/ssh-auth.sock" \
    --mount "type=bind,src=${PWD},dst=/workspace" \
    --workdir /workspace \
    "${GITCLIENT_NAME:-ddadon/gitclient}" "$@"
}

alias gclone='_gitclient clone'
alias gfetch='_gitclient fetch'
alias glsremote='_gitclient ls-remote'
alias gpull='_gitclient pull'
alias gpush='_gitclient push'

# Azure Client
azure() {
  docker run \
    --rm \
    --interactive \
    --tty \
    --detach-keys "ctrl-_" \
    --mount "type=bind,src=${PWD},dst=/workspace" \
    --mount "type=volume,src=azureclient-data,dst=/data" \
    --workdir /workspace \
    "${AZURECLIENT_NAME:-ddadon/azureclient}"
}

# Shell customization
export PS1="%n@mbp %~ %% "
