FROM ghcr.io/cloudsnacks/sandbox-agent:1.0.0@sha256:35ea6452c36f453785b340b21980ac81641edaffde67b51033159a30bbf9898a

# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.280

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
