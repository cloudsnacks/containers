FROM ubuntu:26.04@sha256:3595d7fc4286a33fad0fd853a4063e654287a9c3787437d7937c94ca3f7a804e

# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=1.36.2
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client

RUN groupadd --gid 1001 kubectl \
    && useradd --uid 1001 --gid kubectl --create-home --shell /bin/bash kubectl

USER kubectl
WORKDIR /home/kubectl

LABEL org.opencontainers.image.description="Rootless kubectl CLI"

CMD ["kubectl"]
