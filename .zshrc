# Some useful aliases
alias rm="rm -i"
alias ls="ls -F"
alias vrc="vi ~/.zshrc && source ~/.zshrc"

# Set Python3 as default
alias python="python3"
alias pip="pip3"

# Shell customization
export PS1="%n@mbp %~ %% "

# Vim mode
bindkey -v
bindkey ^R history-incremental-search-backward # https://stackoverflow.com/a/58188295/5384400
bindkey ^S history-incremental-search-forward # https://stackoverflow.com/a/58188295/5384400
bindkey -v '^?' backward-delete-char # https://unix.stackexchange.com/a/290403/433799
