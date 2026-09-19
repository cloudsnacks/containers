# renovate: datasource=docker depName=ghcr.io/astral-sh/uv
FROM ghcr.io/astral-sh/uv:0.12.3@sha256:2d890623d310b57771ce840f0da5eed5fc6d657da05ffaa45d82797b53fa3abc AS uv

# renovate: datasource=docker depName=ghcr.io/berriai/litellm-non_root
FROM ghcr.io/berriai/litellm-non_root:v1.101.0@sha256:633ae8495a5146fef15298a9d4eadb7ff2634b2218274c2666d2d77d11ace30b

# renovate: datasource=pypi depName=mlflow
ARG MLFLOW_VERSION=3.15.1

USER root

# Upstream's uv-managed /app/.venv ships no pip, so mlflow (needed for
# litellm_settings.success_callback/failure_callback: ["mlflow"]) is added
# with uv directly against that venv's interpreter. Re-chmod afterwards:
# the base image keeps /app/.venv world-readable so it works under any
# runAsUser, and installing as root would otherwise leave the new files
# owner-only.
COPY --from=uv /uv /usr/local/bin/uv
RUN uv pip install --python /app/.venv/bin/python3 "mlflow==${MLFLOW_VERSION}" \
    && rm /usr/local/bin/uv \
    && chmod -R o+rX /app/.venv \
    && /app/.venv/bin/python3 -c "import mlflow; print(mlflow.__version__)"

USER 65534

LABEL org.opencontainers.image.description="LiteLLM proxy (non_root), our canonical build with mlflow added for the built-in mlflow logging callback"
