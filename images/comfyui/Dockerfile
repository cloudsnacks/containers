# renovate: datasource=docker depName=python
FROM python:3.14-slim@sha256:a2b82f3c48559aa0a8446d9af49826b6e2b2016f4cd2afabfe6013ec53729170

# renovate: datasource=github-releases depName=comfyanonymous/ComfyUI
ARG COMFYUI_VERSION=0.38.0
# The three move together: torchaudio is the ceiling (upstream wound it down, so
# the cu130 index stops at 2.11.0 while torch is already at 2.13.0) and letting
# pip resolve freely would downgrade torch to match. Bump all three or none.
# renovate: datasource=pypi depName=torch
ARG TORCH_VERSION=2.11.0
ARG TORCHVISION_VERSION=0.26.0
ARG TORCHAUDIO_VERSION=2.11.0
# CUDA 13 still supports Ampere (sm_86), which is what the RTX 3090 Ti needs.
ARG TORCH_CUDA=cu130
# leejet's fork of city96/ComfyUI-GGUF: the upstream node rejects Qwen-Image 2.1
# GGUFs with "Unknown model architecture!". No releases, so pinned to a commit.
ARG COMFYUI_GGUF_COMMIT=373048b8403a7820620065210a691263d4da0a61
# renovate: datasource=pypi depName=gguf
ARG GGUF_VERSION=0.19.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# libgl1/libglib2.0-0: kornia and spandrel pull OpenCV-family wheels that dlopen
# libGL at import time, which ComfyUI does on startup.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/comfyanonymous/ComfyUI/archive/refs/tags/v${COMFYUI_VERSION}.tar.gz" \
        -o /tmp/comfyui.tar.gz \
    && mkdir -p /opt/comfyui \
    && tar -xzf /tmp/comfyui.tar.gz -C /opt/comfyui --strip-components=1 \
    && rm /tmp/comfyui.tar.gz \
    && test -f /opt/comfyui/main.py

# torch first from the CUDA index: requirements.txt lists torch/torchvision/
# torchaudio unpinned, so pip treats them as already satisfied and will not
# pull the default CPU-flavoured wheels from PyPI over the top.
RUN pip install --no-cache-dir --index-url "https://download.pytorch.org/whl/${TORCH_CUDA}" \
        "torch==${TORCH_VERSION}" \
        "torchvision==${TORCHVISION_VERSION}" \
        "torchaudio==${TORCHAUDIO_VERSION}" \
    && pip install --no-cache-dir -r /opt/comfyui/requirements.txt \
    && python -c "import torch, torchvision, torchaudio; print(torch.__version__)"

# Only gguf from the node's requirements.txt: sentencepiece and protobuf are
# marked optional there and only serve its conversion tooling.
RUN mkdir -p /opt/comfyui/custom_nodes/ComfyUI-GGUF \
    && curl -fsSL "https://github.com/leejet/ComfyUI-GGUF/archive/${COMFYUI_GGUF_COMMIT}.tar.gz" \
        | tar -xz -C /opt/comfyui/custom_nodes/ComfyUI-GGUF --strip-components=1 \
    && test -f /opt/comfyui/custom_nodes/ComfyUI-GGUF/__init__.py \
    && pip install --no-cache-dir "gguf==${GGUF_VERSION}"

RUN groupadd -g 1001 comfyui \
    && useradd -u 1001 -g 1001 -m -d /home/comfyui -s /usr/sbin/nologin comfyui \
    && chown -R 1001:1001 /opt/comfyui

WORKDIR /opt/comfyui
USER 1001

LABEL org.opencontainers.image.description="ComfyUI with CUDA-enabled PyTorch, for GPU image and video generation workflows"

# Split so a consumer can override the flags with container args alone: with
# CMD-only and no ENTRYPOINT, Kubernetes args replace the whole command and
# the runtime tries to exec the first flag as the binary.
ENTRYPOINT ["python", "main.py"]
CMD ["--listen", "0.0.0.0", "--port", "8188"]
