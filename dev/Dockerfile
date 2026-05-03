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
    cluster_version="$(pg_lsclusters --no-header | awk 'NR == 1 { print $1 }')"
    pg_ctlcluster "${cluster_version}" main start
    su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\""
    pg_ctlcluster "${cluster_version}" main stop
EOF

# See: https://github.com/ghostty-org/ghostty/discussions/8268
RUN cp /usr/share/terminfo/g/ghostty /usr/share/terminfo/x/xterm-ghostty

RUN <<EOF
    curl -fsSL -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    . /root/.nvm/nvm.sh
    nvm install 24.15.0
    nvm alias default 24.15.0
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
    trap 'kill "$pid" 2>/dev/null || true' EXIT
    ready=0
    for _ in {1..180}; do
        if curl -fsS http://127.0.0.1:8123/ 2>/dev/null | grep -q 'vscode-workbench-web-configuration'; then
            ready=1
            break
        fi
        sleep 1
    done
    if [[ "$ready" -ne 1 ]]; then
        exit 1
    fi
    kill "$pid"
    wait "$pid" || true
    trap - EXIT
    find /opt/vscode-cli/serve-web -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tail -n 1 > /opt/vscode-cli/serve-web/commit-id
    test -s /opt/vscode-cli/serve-web/commit-id
EOF

COPY vscode-defaults /tmp/vscode-defaults
COPY gopls-proxy /tmp/gopls-proxy

RUN <<EOF
    server_commit="$(< /opt/vscode-cli/serve-web/commit-id)"
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
        redhat.vscode-yaml \
        vscodevim.vim
    do
        "/opt/vscode-cli/serve-web/${server_commit}/bin/code-server" \
            --user-data-dir /opt/vscode-server/data \
            --extensions-dir /opt/vscode-server/extensions \
            --install-extension "${extension}" \
            --force
    done

    package_extension() {
        source_dir="$1"
        name="$2"
        display_name="$3"
        description="$4"
        enabled_api_proposals="${5:-}"
        vsix="/tmp/${name}.vsix"
        work_dir="/tmp/${name}-vsix"

        mkdir -p "${work_dir}/extension"
        cp "${source_dir}/package.json" "${work_dir}/extension/package.json"
        if [[ -f "${source_dir}/extension.js" ]]; then
            cp "${source_dir}/extension.js" "${work_dir}/extension/extension.js"
        fi

        cat > "${work_dir}/extension.vsixmanifest" <<VSIX_MANIFEST
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="${name}" Version="0.0.1" Publisher="local" />
    <DisplayName>${display_name}</DisplayName>
    <Description xml:space="preserve">${description}</Description>
    <Tags>Other</Tags>
    <Categories>Other</Categories>
    <GalleryFlags>Private</GalleryFlags>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.90.0" />
$(if [[ -n "${enabled_api_proposals}" ]]; then echo "      <Property Id=\"Microsoft.VisualStudio.Code.EnabledApiProposals\" Value=\"${enabled_api_proposals}\" />"; fi)
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code" />
  </Installation>
  <Dependencies />
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
  </Assets>
</PackageManifest>
VSIX_MANIFEST

        cat > "${work_dir}/[Content_Types].xml" <<'CONTENT_TYPES'
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="js" ContentType="application/javascript" />
  <Default Extension="json" ContentType="application/json" />
  <Default Extension="vsixmanifest" ContentType="text/xml" />
  <Default Extension="xml" ContentType="text/xml" />
</Types>
CONTENT_TYPES

        (cd "${work_dir}" && zip -qr "${vsix}" .)
        "/opt/vscode-cli/serve-web/${server_commit}/bin/code-server" \
            --user-data-dir /opt/vscode-server/data \
            --extensions-dir /opt/vscode-server/extensions \
            --install-extension "${vsix}" \
            --force

        rm -rf "${work_dir}" "${vsix}"
    }

    package_extension \
        /tmp/vscode-defaults \
        vscode-defaults \
        "VS Code Defaults" \
        "Container defaults that must be available before extension host startup."

    package_extension \
        /tmp/gopls-proxy \
        gopls-proxy \
        "gopls Proxy" \
        "Opens gopls web views through a container-friendly local proxy." \
        externalUriOpener

    rm -rf /tmp/vscode-defaults /tmp/gopls-proxy
EOF

COPY vscode/settings.json /opt/vscode-server/data/User/settings.json
COPY vscode/keybindings.json /opt/vscode-server/data/User/keybindings.json
COPY bashrc /root/.bashrc
COPY bash_profile /root/.bash_profile
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY config.toml /etc/codex/config.toml

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
