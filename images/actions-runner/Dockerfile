FROM ubuntu:24.04@sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90

# renovate: datasource=github-releases depName=actions/runner
ARG RUNNER_VERSION=2.337.0
# renovate: datasource=github-releases depName=actions/runner-container-hooks
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.8.1
# renovate: datasource=docker depName=docker versioning=docker
ARG DOCKER_VERSION=29.6.1
# renovate: datasource=github-releases depName=docker/buildx
ARG BUILDX_VERSION=0.35.0
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# LANG: the base image leaves the locale unset, which makes tmux mangle
# non-ASCII pane titles that some workflows key their status discovery on.
ENV DEBIAN_FRONTEND=noninteractive \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1 \
    LANG=C.UTF-8

# libatomic1: the Node that actions/setup-node installs links libatomic.so.1
# tmux: workflows that drive a real tmux session
#
# The lib*/fonts-* block is headless Chromium's runtime for Playwright suites:
# `playwright install --with-deps` escalates to root for these and this image
# is rootless (su: Authentication failure), so they are baked in instead and
# workflows run plain `playwright install chromium`. List taken from
# Playwright 1.62.0 nativeDeps ubuntu24.04 (same set on arm64), minus xvfb and
# the xfonts-* server fonts that only headed X11 mode needs. The fonts stay:
# screenshot suites need emoji and CJK fallbacks to render, not tofu boxes.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        fonts-freefont-ttf \
        fonts-ipafont-gothic \
        fonts-liberation \
        fonts-noto-color-emoji \
        fonts-tlwg-loma-otf \
        fonts-unifont \
        fonts-wqy-zenhei \
        git \
        git-lfs \
        jq \
        libasound2t64 \
        libatk-bridge2.0-0t64 \
        libatk1.0-0t64 \
        libatomic1 \
        libatspi2.0-0t64 \
        libcairo2 \
        libcups2t64 \
        libdbus-1-3 \
        libdrm2 \
        libfontconfig1 \
        libfreetype6 \
        libgbm1 \
        libglib2.0-0t64 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libx11-6 \
        libxcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        tmux \
        unzip \
        zstd \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1001 runner \
    && useradd --uid 1001 --gid runner --create-home --shell /bin/bash runner

WORKDIR /home/runner

RUN RUNNER_ARCH="$(case "${TARGETARCH}" in amd64) echo x64 ;; *) echo "${TARGETARCH}" ;; esac)" \
    && curl -fsSL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
        | tar -xz \
    && ./bin/installdependencies.sh \
    && curl -fsSL -o /tmp/hooks.zip "https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip" \
    && unzip -q /tmp/hooks.zip -d ./k8s \
    && rm /tmp/hooks.zip \
    && rm -rf /var/lib/apt/lists/* \
    && chown -R runner:runner /home/runner

# docker CLI + buildx only — no daemon. Workflows on these runners build against
# the dind sidecar ARC injects in containerMode: dind, whose socket is already
# shared into this container, so shipping the client crosses no new trust
# boundary. gid 123 is what ARC's chart passes to the sidecar's dockerd as
# --group, so the socket is group-owned by it; upstream's runner image uses the
# same gid (the docker:dind image's own docker group is 2375, and unused here).
RUN DOCKER_ARCH="$(case "${TARGETARCH}" in amd64) echo x86_64 ;; arm64) echo aarch64 ;; *) echo "${TARGETARCH}" ;; esac)" \
    && curl -fsSL -o /tmp/docker.tgz "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz" \
    && tar -xzf /tmp/docker.tgz -C /tmp \
    && install -o root -g root -m 0755 /tmp/docker/docker /usr/bin/docker \
    && rm -rf /tmp/docker /tmp/docker.tgz \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -fsSL -o /usr/local/lib/docker/cli-plugins/docker-buildx \
        "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-${TARGETARCH}" \
    && chmod 0755 /usr/local/lib/docker/cli-plugins/docker-buildx \
    && groupadd --gid 123 docker \
    && usermod --append --groups docker runner \
    && docker --version \
    && docker buildx version

# Workflow tooling that GitHub's own hosted images ship and Ubuntu does not
# usefully package — there is no gh in the archive at all, and its `yq` is the
# unrelated Python jq-wrapper with different syntax. Without them here every
# workflow that opens a PR or patches a manifest curls its own copy into
# RUNNER_TEMP, which is the per-repo drift this image exists to absorb.
#
# The list lives in mise.toml, one line per tool, so growing it costs no
# Dockerfile. Renovate's native mise manager reads that file, which is why
# those entries carry no `# renovate:` annotation. mise itself is fetched as a
# pinned release binary rather than through the unpinned mise.run installer.
# renovate: datasource=github-releases depName=jdx/mise
ARG MISE_VERSION=2026.7.17
# Data dir stays root-owned and read-only to the runner user; the cache is the
# only path mise writes to at runtime, so it points somewhere world-writable.
ENV MISE_DATA_DIR=/opt/mise \
    MISE_CONFIG_DIR=/opt/mise \
    MISE_CACHE_DIR=/tmp/mise-cache \
    PATH=/opt/mise/shims:$PATH
COPY mise.toml /opt/mise/config.toml
RUN MISE_ARCH="$(case "${TARGETARCH}" in amd64) echo x64 ;; *) echo "${TARGETARCH}" ;; esac)" \
    && curl -fsSL -o /tmp/mise \
        "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-${MISE_ARCH}" \
    && install -o root -g root -m 0755 /tmp/mise /usr/bin/mise \
    && rm -f /tmp/mise \
    && mise install --yes \
    && mise ls --installed

USER runner

LABEL org.opencontainers.image.description="GitHub Actions runner for Actions Runner Controller, with docker CLI, buildx and a mise-managed CLI toolchain"
