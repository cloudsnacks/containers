# renovate: datasource=docker depName=python
FROM python:3.14-slim@sha256:0097bb60d0c7a2c6af5a56e747eabc2016218f837f76daa70b9526fb883bc499

# renovate: datasource=github-releases depName=comfyanonymous/ComfyUI
ARG COMFYUI_VERSION=0.34.0
# The three move together: torchaudio is the ceiling (upstream wound it down, so
# the cu130 index stops at 2.11.0 while torch is already at 2.13.0) and letting
# pip resolve freely would downgrade torch to match. Bump all three or none.
# renovate: datasource=pypi depName=torch
ARG TORCH_VERSION=2.11.0
ARG TORCHVISION_VERSION=0.26.0
ARG TORCHAUDIO_VERSION=2.11.0
# CUDA 13 still supports Ampere (sm_86), which is what the RTX 3090 Ti needs.
ARG TORCH_CUDA=cu130

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
