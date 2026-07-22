FROM ubuntu:24.04@sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90

# renovate: datasource=github-releases depName=actions/runner
ARG RUNNER_VERSION=2.336.0
# renovate: datasource=github-releases depName=actions/runner-container-hooks
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.8.1
ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        git-lfs \
        jq \
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

USER runner

LABEL org.opencontainers.image.description="Rootless GitHub Actions runner for Actions Runner Controller"
