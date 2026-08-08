# check=skip=SecretsUsedInArgOrEnv;error=true

FROM debian@sha256:0d97731c59efdde181e19c4a5ec22d16e9eefcb73175598b9b7bae712c7214eb
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
ENV LANG=C.UTF-8
ENV COLORTERM=truecolor
ENV TERM=xterm-256color

RUN apt-get update && apt-get install --yes --no-install-recommends \
    ca-certificates \
    git \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN git config --global push.autoSetupRemote true

RUN mkdir -p /root/.ssh
RUN ssh-keyscan github.com vs-ssh.visualstudio.com >> /root/.ssh/known_hosts

ENTRYPOINT ["/usr/bin/git"]
CMD ["--help"]
