FROM node:24-alpine@sha256:8a32c8cf649a49915a66e81e7a609223c708d0adabf288ee3f4077d765542f85

# renovate: datasource=npm depName=@infisical/mcp
ARG INFISICAL_MCP_VERSION=0.0.23
# The node base image ships an older bundled npm whose own vendored deps carry
# known CVEs; upgrading npm itself is the only way to move them.
# renovate: datasource=npm depName=npm
ARG NPM_VERSION=12.0.1

RUN npm install -g "npm@${NPM_VERSION}" \
    && npm install -g "@infisical/mcp@${INFISICAL_MCP_VERSION}" \
    && npm cache clean --force \
    && node --check /usr/local/lib/node_modules/@infisical/mcp/dist/index.js

RUN addgroup -g 1001 infisical \
    && adduser -D -u 1001 -G infisical infisical

USER infisical

LABEL org.opencontainers.image.description="Infisical MCP server (secrets management over MCP)"

CMD ["node", "/usr/local/lib/node_modules/@infisical/mcp/dist/index.js"]
