FROM debian:sid
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.nvm/versions/node/v24.15.0/bin:/root/go/bin:${PATH}"

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
    nginx \
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
    unzip \
    vim \
    xz-utils \
    yq \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN <<EOF
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    install -D -o root -g root -m 644 microsoft.gpg /etc/apt/keyrings/microsoft-archive-keyring.gpg
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
    apt-get update
    apt-get install --yes --no-install-recommends code
    rm microsoft.gpg
    rm -rf /var/lib/apt/lists/*
EOF

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
    nvm install 24.15.0
    node -v
    npm -v
EOF

RUN npm install -g typescript

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

RUN go install github.com/sosedoff/pgweb@latest

RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    ln -sf /usr/bin/batcat /usr/local/bin/bat

RUN echo 'export PATH="$HOME/.local/bin:$PATH"' > /etc/profile.d/local_bin_path.sh
RUN npm install -g @openai/codex@0.133.0

RUN mkdir -p \
    /opt/vscode-server/data/Machine \
    /opt/vscode-server/data/User \
    /opt/vscode-server/extensions \
    /opt/vscode-cli \
    /workspace

RUN <<EOF
    export VSCODE_CLI_DATA_DIR=/opt/vscode-cli
    code serve-web \
        --host 127.0.0.1 \
        --port 8123 \
        --without-connection-token \
        --accept-server-license-terms \
        --server-data-dir /opt/vscode-server \
        --disable-telemetry \
        --default-folder /workspace &
    pid="$!"
    trap 'kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true' EXIT
    for i in {1..180}; do
        if curl -fsSL http://127.0.0.1:8123/ | rg -q 'vscode-workbench-web-configuration'; then
            exit 0
        fi
        sleep 1
    done
    echo "Timed out waiting for VS Code web UI after ${i} attempts" >&2
    exit 1
EOF

RUN <<EOF
    for extension in \
        bradlc.vscode-tailwindcss \
        eamodio.gitlens \
        esbenp.prettier-vscode \
        golang.Go \
        HashiCorp.HCL \
        ms-azuretools.vscode-containers \
        ms-ossdata.vscode-pgsql \
        PKief.material-icon-theme \
        r3inbowari.gomodexplorer \
        redhat.vscode-yaml \
        vscodevim.vim
    do
        code \
            --user-data-dir /opt/vscode-server/data \
            --extensions-dir /opt/vscode-server/extensions \
            --install-extension "${extension}" \
            --force
    done
EOF

COPY AGENTS.md /root/AGENTS.md
COPY .vimrc /root/.vimrc
COPY dev/bashrc /root/.bashrc
RUN echo 'source /root/.bashrc' > /root/.bash_profile
COPY dev/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
