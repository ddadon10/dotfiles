FROM debian:sid

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# Install dependencies
RUN apt-get update && apt-get install --yes --no-install-recommends \
    bash-completion \
    bat \
    build-essential \
    bind9-dnsutils \
    ca-certificates \
    curl \
    fd-find \
    fzf \
    git \
    git-delta \
    gnupg \
    golang-1.25 \
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
    nodejs \
    procps \
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
    unzip \
    vim \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Add go to path
RUN echo 'export PATH="/usr/lib/go-1.25/bin/:$PATH"' > /etc/profile.d/golang_path.sh

# Install yq
RUN /usr/lib/go-1.25/bin/go install github.com/mikefarah/yq/v4@latest

# Install Neovim
RUN <<EOF
    name=neovim
    arch=$(uname -m)
    baseurl="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-"
    echo "${name}: installing..."
    if [ "$arch" = "x86_64" ]; then
        arch_suffix="x86_64.tar.gz"
    elif [ "$arch" = "aarch64" ]; then
        arch_suffix="arm64.tar.gz"
    else
        echo "Unsupported architecture: $arch"
        exit 1
    fi
    mkdir -p "/opt/${name}"
    curl -sSfL "${baseurl}${arch_suffix}" | tar -xzf /dev/stdin -C "/opt/${name}" --strip-components=1
    echo 'export PATH="/opt/${name}/bin:$PATH"' > /etc/profile.d/${name}_path.sh
    echo "${name}: installation finished successfully"
EOF

# Install Atlas
RUN <<EOF
    echo "Atlas: Installing..."
    export ATLAS_VERSION=latest
    export CI=true
    curl -sSf https://atlasgo.sh | sh
    echo "Atlas: Installation finished successfully"
EOF

# Install Postgres LSP
RUN <<EOF
    ARCH=$(uname -m)
    echo "Postgres LSP: Installing..."
    POSTGRES_LSP_PATH="/usr/local/bin/postgres-lsp"
    curl -sSfL "https://github.com/supabase-community/postgres-language-server/releases/latest/download/postgrestools_${ARCH}-unknown-linux-gnu" -o ${POSTGRES_LSP_PATH}
    chmod +x ${POSTGRES_LSP_PATH}
    echo "Postgres LSP: Installation finished successfully"
EOF

# Setup NPM
RUN <<EOF
    echo "NPM Setup: Add .npmrc to user directory..."
    echo "ignore-scripts = true" >> "$HOME/.npmrc" 
    echo "save-exact = true" >> "$HOME/.npmrc" 
    echo "engine-strict = true" >> "$HOME/.npmrc" 
    echo "strict-peer-deps = true" >> "$HOME/.npmrc" 
    echo "NPM Setup: .npmrc added to user directory"
EOF

ENTRYPOINT ["/bin/bash", "--login"]
