# Some useful aliases
alias rm='rm -i'
alias ls='ls -aF'
alias dev='docker run \
  --rm \
  --interactive \
  --tty \
  --mount type=bind,src="${PWD}",dst=/workspace \
  --mount type=bind,src="${HOME}/.claude",dst=/root/.claude \
  --mount type=bind,src="${HOME}/.config/github-copilot",dst=/root/.config/github-copilot \
  --workdir /workspace \
  dev'

# Shell customization
export PS1="%n@mbp %~ %% "

# Java
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"

# Azure
alias azuredev='docker run \
  --rm \
  --interactive \
  --tty \
  --mount type=bind,src=${HOME}/.azure,dst=/root/.azure \
  --mount type=bind,src=${HOME}/.kube,dst=/root/.kube \
  azuredev'


# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/david/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Kubectl completion
source <(kubectl completion zsh)
