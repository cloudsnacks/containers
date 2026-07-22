FROM ubuntu:24.04@sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90

# renovate: datasource=node-version depName=node
ARG NODE_VERSION=24.18.0
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.96.0
# renovate: datasource=github-releases depName=astral-sh/uv
ARG UV_VERSION=0.11.31
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        git-lfs \
        gnupg \
        jq \
        less \
        make \
        openssh-client \
        python3 \
        python3-venv \
        ripgrep \
        unzip \
        xz-utils \
        zip \
        zstd \
    && rm -rf /var/lib/apt/lists/*

RUN NODE_ARCH="$(case "${TARGETARCH}" in amd64) echo x64 ;; *) echo "${TARGETARCH}" ;; esac)" \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" \
        | tar -xJ -C /usr/local --strip-components=1 --no-same-owner \
    && node --version

RUN curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz" \
        | tar -xz -C /usr/local/bin --strip-components=2 --no-same-owner "gh_${GH_VERSION}_linux_${TARGETARCH}/bin/gh" \
    && UV_ARCH="$(case "${TARGETARCH}" in amd64) echo x86_64 ;; arm64) echo aarch64 ;; esac)" \
    && curl -fsSL "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${UV_ARCH}-unknown-linux-gnu.tar.gz" \
        | tar -xz -C /usr/local/bin --strip-components=1 --no-same-owner \
    && gh --version \
    && uv --version

RUN groupadd --gid 1001 agent \
    && useradd --uid 1001 --gid agent --create-home --shell /bin/bash agent \
    && mkdir /workspace \
    && chown agent:agent /workspace

ENV NPM_CONFIG_PREFIX=/home/agent/.npm \
    PATH=/home/agent/.npm/bin:/home/agent/.local/bin:${PATH}

USER agent
WORKDIR /workspace

LABEL org.opencontainers.image.description="Rootless base image for sandboxed coding agents"

CMD ["bash"]
