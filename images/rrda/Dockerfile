FROM golang:1.27-alpine@sha256:f92b6ef800e499660581efdabdf25d9d817a9d124eaf900924f0504e7e27e12d AS build

# renovate: datasource=github-releases depName=fcambus/rrda
ARG RRDA_VERSION=1.4.1

WORKDIR /src

# Release tarball rather than a git clone, so the build stage needs no apk layer.
RUN wget -q -O rrda.tar.gz "https://github.com/fcambus/rrda/archive/refs/tags/${RRDA_VERSION}.tar.gz" \
    && tar -xzf rrda.tar.gz --strip-components=1 \
    && rm rrda.tar.gz \
    && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/rrda \
    && /out/rrda -version

FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

# rrda speaks plain DNS to its upstream resolver and serves plain HTTP, so it
# needs no CA bundle — busybox alone covers user creation.
RUN addgroup -g 1001 rrda \
    && adduser -u 1001 -G rrda -D -H -s /sbin/nologin rrda

COPY --from=build /out/rrda /usr/local/bin/rrda

USER rrda

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/rrda", "-host", "0.0.0.0"]

LABEL org.opencontainers.image.description="JSON REST API for DNS queries, wrapping a resolver over HTTP"
