FROM debian:sid
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV VSCODE_USER_DATA_DIR=/opt/vscode-user-data
ENV VSCODE_EXTENSIONS_DIR=/opt/vscode-extensions
ENV VSCODE_SERVER_DATA_DIR=/opt/vscode-server
ENV VSCODE_CLI_DATA_DIR=/opt/vscode-cli
ENV PATH="/root/go/bin:${PATH}"

RUN apt-get update && apt-get install --yes --no-install-recommends \
    apt-transport-https \
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
    nodejs \
    npm \
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
    yq \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN <<EOF
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
    install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
    rm /tmp/microsoft.gpg
    cat > /etc/apt/sources.list.d/vscode.sources <<'SOURCES'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64
Signed-By: /usr/share/keyrings/microsoft.gpg
SOURCES
    apt-get update
    apt-get install --yes --no-install-recommends code
    rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
    cluster_version="$(pg_lsclusters --no-header | awk 'NR == 1 { print $1 }')"
    pg_ctlcluster "${cluster_version}" main start
    su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\""
    pg_ctlcluster "${cluster_version}" main stop
EOF

# See: https://github.com/ghostty-org/ghostty/discussions/8268
RUN cp /usr/share/terminfo/g/ghostty /usr/share/terminfo/x/xterm-ghostty

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
        x86_64) arch="linux-x64" ;;
        aarch64) arch="linux-arm64" ;;
        *) exit 1 ;;
    esac
    curl -sSfL -o /usr/local/bin/marksman \
        "https://github.com/artempyanykh/marksman/releases/latest/download/marksman-${arch}"
    chmod +x /usr/local/bin/marksman
EOF

RUN <<EOF
    machine=$(uname -m)
    case "${machine}" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *) exit 1 ;;
    esac
    ver=$(curl -sSf "https://api.github.com/repos/hashicorp/terraform-ls/releases/latest" | jq -r '.tag_name' | sed 's/^v//')
    curl -sSfL -o /tmp/terraform-ls.zip \
        "https://releases.hashicorp.com/terraform-ls/${ver}/terraform-ls_${ver}_linux_${arch}.zip"
    unzip -qo /tmp/terraform-ls.zip -d /usr/local/bin/
    rm /tmp/terraform-ls.zip
EOF

RUN <<EOF
    machine=$(uname -m)
    case "${machine}" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        *) exit 1 ;;
    esac
    curl -sSfL -o /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${arch}/kubectl"
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
RUN npm install -g @openai/codex@0.124.0

RUN mkdir -p \
    "${VSCODE_USER_DATA_DIR}/User" \
    "${VSCODE_EXTENSIONS_DIR}" \
    "${VSCODE_SERVER_DATA_DIR}" \
    "${VSCODE_CLI_DATA_DIR}" \
    /workspace

RUN <<EOF
    for extension in \
        bradlc.vscode-tailwindcss \
        openai.chatgpt \
        eamodio.gitlens \
        esbenp.prettier-vscode \
        golang.Go \
        HashiCorp.HCL \
        JetBrains.jetbrains-ai-assistant \
        ms-azuretools.vscode-containers \
        ms-ossdata.vscode-pgsql \
        r3inbowari.gomodexplorer \
        redhat.vscode-yaml
    do
        code --no-sandbox \
            --user-data-dir "${VSCODE_USER_DATA_DIR}" \
            --extensions-dir "${VSCODE_EXTENSIONS_DIR}" \
            --install-extension "${extension}" \
            --force
    done
EOF

COPY vscode/settings.json /opt/vscode-user-data/User/settings.json
COPY vscode/keybindings.json /opt/vscode-user-data/User/keybindings.json
COPY dev/scratches/ /opt/scratches/
COPY dev/bashrc /root/.bashrc
COPY dev/bash_profile /root/.bash_profile
COPY dev/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY dev/config.toml /etc/codex/config.toml

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
