---
name: add-image
description: Scaffold a new container image in this repo with the required Dockerfile, metadata, and security conventions. Use when asked to "add an image", "add a container", "new image", or to create a new directory under images/.
---

# Add a new container image

Every image lives in `images/<name>/` with exactly two files: `Dockerfile` and `metadata.yaml`. Copy `images/sandbox-agent/` as a template and work through the steps below.

## 1. Gather versions and digests

- Resolve the latest upstream version(s) to pin:

  ```shell
  gh api repos/<owner>/<repo>/releases/latest --jq .tag_name
  ```

- Resolve the base image's multi-arch digest (example for `ubuntu:24.04`):

  ```shell
  token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/ubuntu:pull" | jq -r .token)
  curl -sI -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.index.v1+json" \
    https://registry-1.docker.io/v2/library/ubuntu/manifests/24.04 | grep -i docker-content-digest
  ```

  Prefer an existing base already used in this repo so layers are shared.

## 2. Write the Dockerfile

Required conventions (CI enforces hadolint; reviewers enforce the rest):

- `FROM <base>:<tag>@sha256:<digest>` — always digest-pinned.
- Every downloaded tool version is an `ARG` with a Renovate annotation directly above it:

  ```dockerfile
  # renovate: datasource=github-releases depName=<owner>/<repo>
  ARG TOOL_VERSION=1.2.3
  ```

- `ARG TARGETARCH` plus a `case` mapping for arch-specific artifacts (`amd64`→`x64`/`x86_64` etc.). Never hardcode an architecture.
- `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` before any `RUN` that pipes.
- `apt-get install -y --no-install-recommends` and `rm -rf /var/lib/apt/lists/*` in the same layer.
- Dedicated non-root user with uid/gid `1001`; the Dockerfile ends with `USER <user>`. No sudo, no docker CLI, no init frameworks (s6, supervisord). One process per container, logs to stdout.
- `LABEL org.opencontainers.image.description="..."` (other OCI labels are injected by CI).
- Verify each installed tool inside the same `RUN` layer (e.g. `&& tool --version`) so a broken download fails the build.

## 3. Write metadata.yaml

```yaml
---
name: <name>
description: <one line>
version: 1.0.0
platforms:
  - linux/amd64
  - linux/arm64
test: <command CI runs via `sh -c` inside the built image>
```

- If the image packages a single upstream application, `version` tracks the upstream version and gets the same `# renovate:` annotation as the Dockerfile `ARG` so both bump together. Otherwise start at `1.0.0` and follow the semver rules in [README.md](../../../README.md#versioning-and-releases).
- The `test` command must exercise the main tools and exit non-zero on failure; chain checks with `&&`.

## 4. Validate locally

Use `container` (Apple container), not docker:

```shell
container build -t <name>:local -f images/<name>/Dockerfile images/<name>
container run --rm <name>:local sh -c "<test command from metadata.yaml>"
container run --rm <name>:local whoami   # must NOT print root
```

Run hadolint if available: `hadolint -c .hadolint.yaml images/<name>/Dockerfile`.

## 5. Finish

1. Add a row to the Images table in [README.md](../../../README.md).
2. Commit with a conventional commit, e.g. `feat(<name>): add <name> image`.
3. Open a PR — CI builds both arches on native runners and runs the metadata `test`. Merging to `main` publishes `ghcr.io/cloudsnacks/<name>` with tags `X.Y.Z`, `X.Y`, `X`, `latest`, plus SBOM and provenance attestations.
