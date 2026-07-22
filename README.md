# containers

Public container images for cloud work, built multi-arch and rootless with security-first defaults. Inspired by [home-operations/containers](https://github.com/home-operations/containers).

## Images

| Image | Description |
|---|---|
| `ghcr.io/cloudsnacks/actions-runner` | Rootless GitHub Actions runner for [Actions Runner Controller](https://github.com/actions/actions-runner-controller) |
| `ghcr.io/cloudsnacks/sandbox-agent` | Rootless base image for sandboxed coding agents (Node, Python, uv, git, gh, ripgrep) |

## Usage

Pin to a semver tag plus digest so tools like Renovate can track updates reliably:

```yaml
image: ghcr.io/cloudsnacks/actions-runner:2.336.0@sha256:<digest>
```

Every image is tagged `X.Y.Z`, `X.Y`, `X`, and `latest`.

### Defaults

- Multi-arch: `linux/amd64` and `linux/arm64`, each built on native runners (no QEMU)
- Rootless: processes run as a dedicated non-root user (uid `1001`)
- One process per container, logs to stdout, no init frameworks
- Base images pinned by digest, tool versions pinned and updated by Renovate
- SBOM and SLSA provenance attestations attached to every image

### Verifying provenance

```shell
gh attestation verify oci://ghcr.io/cloudsnacks/actions-runner:2.336.0 --owner cloudsnacks
```

## Versioning and releases

Each image is versioned independently via the `version` field in its `images/<name>/metadata.yaml`:

- Images that package a single upstream application (e.g. `actions-runner`) track the upstream version.
- Images owned by this repo (e.g. `sandbox-agent`) use their own semver: MAJOR for breaking changes (removed tools, changed users/paths), MINOR for additions, PATCH for fixes and rebuilds.

CI builds and tags whatever version the metadata declares — bump it in the same PR as the change.

## Adding an image

1. Create `images/<name>/Dockerfile` and `images/<name>/metadata.yaml` (copy an existing image as a template).
2. Pin the base image by digest and any downloaded tools with a `# renovate:` annotation.
3. Create a non-root user (uid `1001`) and switch to it with `USER`.
4. Add a `test` command to the metadata — CI runs it against the built image on PRs.

## CI

`.github/workflows/build.yaml` builds only images changed in a PR or push:

1. **prepare** — diffs `images/` and emits a build matrix from each image's `metadata.yaml`.
2. **build** — one job per image per platform, on native runners (`ubuntu-latest` for amd64, `ubuntu-24.04-arm` for arm64) with BuildKit and GitHub Actions layer caching. PRs build and smoke-test locally; pushes to `main` push by digest with SBOM and provenance.
3. **merge** — stitches the per-arch digests into one manifest list, applies the semver tags, and attests build provenance.

Trigger a manual build of any (or every) image via *Actions → Build → Run workflow*.

## Local development

Build with [Apple container](https://github.com/apple/container) (or any BuildKit-compatible builder):

```shell
container build -t sandbox-agent:local -f images/sandbox-agent/Dockerfile images/sandbox-agent
container run --rm sandbox-agent:local node --version
```

## License

[Apache-2.0](LICENSE)
