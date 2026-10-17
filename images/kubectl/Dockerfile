FROM ubuntu:26.04@sha256:c098726dd9b9733f3e885f8de0ef375206a311b0a317eadc40d347b1115fb944

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
