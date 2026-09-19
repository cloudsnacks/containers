# excalidraw/excalidraw-mcp publishes neither a container image nor an npm package
# (the @mcp-demos/excalidraw-server name 404s on the registry), so build from the tag.
#
# The build stage is pinned to BUILDPLATFORM: it emits only a bundled JS file and a
# single-file HTML app, both arch-independent, which keeps bun off QEMU for anyone
# cross-building locally. CI builds each arch on a native runner, where this is a
# no-op.
FROM --platform=$BUILDPLATFORM node:24-bookworm-slim@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6 AS build

# renovate: datasource=github-releases depName=excalidraw/excalidraw-mcp
ARG EXCALIDRAW_MCP_VERSION=v0.3.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${EXCALIDRAW_MCP_VERSION}" \
    https://github.com/excalidraw/excalidraw-mcp.git .

# `npm ci` is not usable: the package-lock.json shipped at v0.3.2 is out of sync with
# its package.json (@upstash/redis and friends are missing from it).
#
# The root postinstall (scripts/setup-bun.mjs) links bun out of the @oven/bun-*
# optional dependencies into node_modules/.bin, where the build script picks it up.
RUN npm install --no-audit --no-fund \
    && npm run build \
    && test -f dist/index.js \
    && test -f dist/mcp-app.html

FROM node:24-bookworm-slim@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6

# dist/index.js is a self-contained bundle and reads mcp-app.html from its own
# directory (server.ts DIST_DIR = import.meta.dirname), so dist/ is the whole runtime.
COPY --from=build /src/dist /app/dist

RUN groupadd -g 1001 excalidraw \
    && useradd -u 1001 -g 1001 -M -s /usr/sbin/nologin excalidraw

ENV NODE_ENV=production
ENV PORT=3001

USER excalidraw
EXPOSE 3001

LABEL org.opencontainers.image.description="Excalidraw MCP server rendering hand-drawn diagrams as an interactive MCP App"

CMD ["node", "/app/dist/index.js"]
