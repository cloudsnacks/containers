FROM node:24-alpine@sha256:a0b9bf06e4e6193cf7a0f58816cc935ff8c2a908f81e6f1a95432d679c54fbfd

# renovate: datasource=npm depName=@infisical/mcp
ARG INFISICAL_MCP_VERSION=0.0.23

RUN npm install -g "@infisical/mcp@${INFISICAL_MCP_VERSION}" \
    && npm cache clean --force \
    && node --check /usr/local/lib/node_modules/@infisical/mcp/dist/index.js

RUN addgroup -g 1001 infisical \
    && adduser -D -u 1001 -G infisical infisical

USER infisical

LABEL org.opencontainers.image.description="Infisical MCP server (secrets management over MCP)"

ENTRYPOINT ["node", "/usr/local/lib/node_modules/@infisical/mcp/dist/index.js"]
