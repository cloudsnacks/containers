FROM ghcr.io/cloudsnacks/sandbox-agent:1.0.1@sha256:f1f3305c68c59fa29f604f43ac4e63463c087632ab3338cd959525887a38b3cd

# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.220

USER root

RUN NPM_CONFIG_PREFIX=/usr/local npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    && npm cache clean --force \
    && claude --version

COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint

USER agent

ENV AGENT_WORKSPACE=/workspace \
    CLAUDE_CONFIG_DIR=/home/agent/.claude

WORKDIR /workspace

LABEL org.opencontainers.image.description="Headless Claude Code agent with git-repo and agent-profile bootstrap"

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["claude", "-p"]
