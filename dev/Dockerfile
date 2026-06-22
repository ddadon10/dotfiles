FROM debian:sid
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=24.15.0
ARG PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin:/root/go/bin:${PATH}"

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
    golang \
    gopls \
    gron \
    htop \
    httpie \
    iproute2 \
    jq \
    less \
    libsimdjson33 \
    locales \
    lsof \
    man-db \
    manpages \
    manpages-dev \
    ncdu \
    ncurses-term \
    neovim \
    openjdk-21-jdk-headless \
    procps \
    postgresql \
    psmisc \
    python3 \
    python3-pip \
    ripgrep \
    rsync \
    shellcheck \
    strace \
    sudo \
    tree \
    tree-sitter-cli \
    unzip \
    vim \
    xz-utils \
    yq \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN <<EOF
    cluster_version="$(pg_lsclusters --no-header | grep -o '^[^ ]*')"
    pg_ctlcluster "${cluster_version}" main start
    su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\""
    pg_ctlcluster "${cluster_version}" main stop
EOF

# See: https://github.com/ghostty-org/ghostty/discussions/8268
RUN cp /usr/share/terminfo/g/ghostty /usr/share/terminfo/x/xterm-ghostty

RUN <<EOF
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    . /root/.nvm/nvm.sh
    nvm install ${NODE_VERSION}
    node -v
    npm -v
EOF

RUN npm install -g typescript

RUN npm install -g \
    @tailwindcss/language-server \
    bash-language-server \
    dockerfile-language-server-nodejs \
    typescript-language-server \
    vscode-langservers-extracted \
    yaml-language-server

RUN <<EOF
    machine=$(uname -m)
    case "${machine}" in
        x86_64) arch="x64" ;;
        aarch64) arch="arm64" ;;
        *) exit 1 ;;
    esac
    ver=$(curl -sSfL "https://api.github.com/repos/LuaLS/lua-language-server/releases/latest" | jq -r '.tag_name')
    mkdir -p /opt/lua-language-server
    curl -sSfL "https://github.com/LuaLS/lua-language-server/releases/download/${ver}/lua-language-server-${ver}-linux-${arch}.tar.gz" | tar -xzf - -C /opt/lua-language-server
    ln -s /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
EOF

RUN <<EOF
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com trixie main" > /etc/apt/sources.list.d/hashicorp.list
    apt-get update
    apt-get install --yes --no-install-recommends terraform-ls
    rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
    machine=$(uname -m)
    case "${machine}" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *) exit 1 ;;
    esac
    curl -sSfL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${arch}/kubectl"
    chmod +x /usr/local/bin/kubectl
EOF

RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

RUN <<EOF
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
    apt-get update
    apt-get install --yes --no-install-recommends google-cloud-cli
    rm -rf /var/lib/apt/lists/*
EOF

RUN npm install -g firebase-tools

RUN go install github.com/jesseduffield/lazygit@latest
RUN go install github.com/sosedoff/pgweb@latest

RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    ln -sf /usr/bin/batcat /usr/local/bin/bat

RUN echo 'export PATH="$HOME/.local/bin:$PATH"' > /etc/profile.d/local_bin_path.sh
RUN echo 'export PATH="$HOME/go/bin:$PATH"' > /etc/profile.d/go_bin_path.sh

RUN npm install -g @openai/codex@0.141.0

COPY .vimrc /root/.vimrc
COPY .config/nvim /root/.config/nvim
RUN nvim --headless "+qa"

COPY <<EOF /usr/local/bin/nvim-editor
#!/usr/bin/env bash
set -euo pipefail
NVIM_QUICK_EDIT=1 exec nvim "\$@"
EOF

RUN chmod +x /usr/local/bin/nvim-editor

RUN mkdir -p /root/.config/lazygit
COPY <<EOF /root/.config/lazygit/config.yml
gui:
  showCommandLog: false
  showRandomTip: false

git:
  autoFetch: false
  autoForwardBranches: none
  fetchAll: false
  pagers:
    - pager: delta --dark --paging=never

update:
  method: never

disableStartupPopups: true
notARepository: quit
EOF

COPY dev/.bashrc /root/.bashrc
RUN echo 'source /root/.bashrc' > /root/.bash_profile

COPY AGENTS.md /root/AGENTS.md

CMD ["/bin/bash", "--login"]
