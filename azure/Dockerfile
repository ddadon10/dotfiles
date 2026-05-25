FROM debian:sid
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update && apt-get install --yes --no-install-recommends \
    bash-completion \
    bat \
    bind9-dnsutils \
    build-essential \
    ca-certificates \
    curl \
    fd-find \
    fzf \
    git \
    git-delta \
    gnupg \
    gron \
    htop \
    httpie \
    iproute2 \
    jq \
    less \
    locales \
    lsof \
    man-db \
    manpages \
    manpages-dev \
    ncdu \
    nginx \
    procps \
    postgresql-client \
    psmisc \
    python3 \
    python3-pip \
    ripgrep \
    rsync \
    shellcheck \
    strace \
    sudo \
    tmux \
    tree \
    ttyd \
    unzip \
    vim \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | sudo bash

# Install kubectl and kubelogin
RUN az aks install-cli

# Install k9s
RUN <<EOF
    machine="$(uname -m)"
    case "${machine}" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *) exit 1 ;;
    esac
    curl -SsfL "https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_Linux_${arch}.tar.gz" -o k9s.tar.gz
    tar -xzf k9s.tar.gz -C /usr/local/bin k9s
    rm -f k9s.tar.gz
EOF

# Setup .bashrc
RUN cat > /root/.bashrc << 'EOF'
    export LANG=C.UTF-8
    export TERM=xterm-256color
    alias fd='fdfind'
EOF

ENTRYPOINT ["bash", "--login"]
