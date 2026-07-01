# check=skip=SecretsUsedInArgOrEnv;error=true

FROM debian:stable-slim
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
ENV LANG=C.UTF-8

RUN apt-get update && apt-get install --yes --no-install-recommends \
    bash-completion \
    ca-certificates \
    git \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.ssh
RUN ssh-keyscan github.com ssh.dev.azure.com >> /root/.ssh/known_hosts

RUN cat <<'EOF' > /root/.bashrc
# Aliases
alias grep='grep --color=auto'
alias ls='ls -aF --color=auto'

# Environment
export COLORTERM=truecolor
export LANG=C.UTF-8
export SHELL=/bin/bash
export TERM=xterm-256color

# PS1
ps1_git_orange='\[\033[38;2;240;80;50m\]'
ps1_path_blue='\[\033[38;2;69;133;136m\]'
ps1_arrow_yellow='\[\033[38;2;215;153;33m\]'
ps1_reset_attr='\[\033[0m\]'
ps1_git_icon=$'\ue702'
ps1_arrow_icon=$'\u276F'

PS1="${ps1_git_orange}${ps1_git_icon}${ps1_reset_attr} ${ps1_path_blue}\\w${ps1_reset_attr} ${ps1_arrow_yellow}${ps1_arrow_icon}${ps1_reset_attr} "

# Bash Completion
source /usr/share/bash-completion/bash_completion
EOF

CMD ["/bin/bash"]
