# check=error=true

FROM debian:stable-20260713-slim
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8

RUN apt-get update && apt-get install --yes --no-install-recommends \
    bash-completion \
    bind9-dnsutils \
    ca-certificates \
    curl \
    iproute2 \
    jq \
    less \
    openssh-client \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | bash

# Install kubectl and kubelogin
RUN AZURE_CONFIG_DIR=/tmp/azure-cli az aks install-cli && rm -r /tmp/azure-cli

# Install k9s
RUN <<EOF
    case "$(uname -m)" in
        x86_64) arch="amd64" checksum="c3752ad51a5a4015a113819c4eeb6e55a4d0e4b8e652494797532f6fc8161dd7" ;;
        aarch64) arch="arm64" checksum="3ee05c82e5f9198928a4e86133608ba6a2c10a2244d6a7789e820f78319d640c" ;;
        *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac

    curl -fsSLo k9s.tar.gz "https://github.com/derailed/k9s/releases/download/v0.51.0/k9s_Linux_${arch}.tar.gz"
    echo "${checksum}  k9s.tar.gz" | sha256sum --check -
    tar -xzf k9s.tar.gz -C /usr/local/bin k9s
    rm k9s.tar.gz
EOF

RUN kubectl completion bash > /etc/bash_completion.d/kubectl && \
    kubelogin completion bash > /etc/bash_completion.d/kubelogin && \
    k9s completion bash > /etc/bash_completion.d/k9s

RUN mkdir -p /data/.kube /data/state/bash && ln -s /data/.kube /root/.kube

COPY <<'EOF' /root/.bashrc
export AZURE_CONFIG_DIR=/data/config/.azure
export COLORTERM=truecolor
export EDITOR=vim
export SHELL=/bin/bash
export TERM=xterm-256color
export XDG_CACHE_HOME=/data/cache
export XDG_CONFIG_HOME=/data/config
export XDG_DATA_HOME=/data/share
export XDG_STATE_HOME=/data/state

ps1_azure_blue='\[\033[38;2;0;120;212m\]'
ps1_path_blue='\[\033[38;2;69;133;136m\]'
ps1_arrow_yellow='\[\033[38;2;215;153;33m\]'
ps1_reset_attr='\[\033[0m\]'
ps1_azure_icon=$'\U000F0805'
ps1_arrow_icon=$'\u276F'

PS1="${ps1_azure_blue}${ps1_azure_icon}${ps1_reset_attr} ${ps1_path_blue}\\w${ps1_reset_attr} ${ps1_arrow_yellow}${ps1_arrow_icon}${ps1_reset_attr} "
shopt -s histappend
shopt -s extglob
HISTFILE=/data/state/bash/history
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
PROMPT_COMMAND='history -a; history -n'
source /usr/share/bash-completion/bash_completion
EOF

CMD ["/bin/bash"]
