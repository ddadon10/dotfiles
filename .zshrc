# Some useful aliases
alias n='nvim'
alias vi='nvim'
alias rm='rm -i'
alias dpostgres='docker run --name postgrestmp --interactive --tty --env POSTGRES_PASSWORD=postgres -p 127.0.0.1:5434:5432 --rm postgres:16.7-bookworm '
alias datlas='docker run --interactive --tty --rm --mount type=bind,src="${PWD}",dst=/workspace --mount type=bind,src="${HOME}/.atlas",dst=/root/.atlas --workdir /workspace arigaio/atlas:0.31.0'
alias dgo='docker run --interactive --tty --rm --mount type=bind,src="${PWD}",dst=/workspace --workdir /workspace golang:1.23.6-bookworm go'
alias dnode='docker run --interactive --tty --rm --mount type=bind,src="${PWD}",dst=/workspace --workdir /workspace node:22.14.0-bookworm node'
alias dnpm='docker run --interactive --tty --rm --mount type=bind,src="${PWD}",dst=/workspace --workdir /workspace node:22.14.0-bookworm npm'

# Shell customization
export PS1="%n@mbp %~ %% "

# MacOS Terminal Support 256 Colors
# See: https://github.com/neovim/neovim/issues/28776
export COLORTERM=256 # $ tput colors
