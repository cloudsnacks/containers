# renovate: datasource=docker depName=ghcr.io/mealie-recipes/mealie
FROM ghcr.io/mealie-recipes/mealie:v3.30.0@sha256:90f83da6f3ab0a421efc827118a556168573930105f13fa3321768f42163d784

# openai.py is upstream's file plus swibrow/mealie@feat/ai-provider-api-key-file
# (AI provider API keys read from files), until a release includes it. The checksum is upstream's original: when a base image
# bump changes that file, the build fails instead of overwriting the change, and
# openai.py needs rebasing onto the new upstream copy.
ARG UPSTREAM_OPENAI_SHA256=fa9d950b7eeb2e0e47b3f78567fcd26452ade6dd2cbdb6d5e6e45c6106357212

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY openai.py /tmp/openai.py
RUN target="$(python -c 'import importlib.util; print(importlib.util.find_spec("mealie.services.openai.openai").origin)')" \
    && echo "${UPSTREAM_OPENAI_SHA256}  ${target}" | sha256sum -c - \
    && install -m 0644 /tmp/openai.py "${target}" \
    && rm /tmp/openai.py \
    && grep -q API_KEY_FILE_PREFIX "${target}"

# No USER: upstream's entrypoint starts as root and drops to PUID (911) itself.

LABEL org.opencontainers.image.description="Mealie with AI provider API keys readable from files, for rotating credentials such as projected service account tokens"
