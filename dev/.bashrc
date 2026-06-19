# Aliases
alias cat='bat --plain --paging never'
alias grep='grep --color=auto'
alias ls='ls -aF --color=auto'

# Environment
export CGO_ENABLED=0
export COLORTERM=truecolor
export EDITOR=vim
export IS_SANDBOX=1
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-$(dpkg --print-architecture)"
export LANG=C.UTF-8
export MANPAGER="bat --plain --language man"
export NODE_ENV=production
export TERM=xterm-ghostty

# Git
[ "$(git config --global --get user.name 2>/dev/null || true)" = "$GIT_USER_NAME" ] || git config --global user.name "$GIT_USER_NAME"
[ "$(git config --global --get user.email 2>/dev/null || true)" = "$GIT_USER_EMAIL" ] || git config --global user.email "$GIT_USER_EMAIL"

# Shell Options
shopt -s histappend
shopt -s extglob

# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups

# Clipboard (OSC-52)
pbcopy() {
  local b64
  b64=$(base64 | tr -d '\n')
  printf '\033]52;c;%s\a' "$b64" >/dev/tty
}

# Path
source /root/.nvm/nvm.sh

# Bash Completion
source /usr/share/bash-completion/bash_completion
