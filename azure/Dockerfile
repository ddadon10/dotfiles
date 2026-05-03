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
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install kubectl and kubelogin
RUN az aks install-cli

# Install k9s
RUN curl -SsfL "https://github.com/derailed/k9s/releases/download/v0.50.18/k9s_Linux_arm64.tar.gz" -o k9s.tar.gz && tar -xzf k9s.tar.gz -C /usr/local/bin k9s && rm -f k9s.tar.gz

# Setup .bashrc
RUN cat > /root/.bashrc << 'EOF'
    export LANG=C.UTF-8
    export TERM=xterm-256color
    alias fd='fdfind'
EOF

ENTRYPOINT ["bash", "--login"]
