# containers

Public container images for cloud work, built multi-arch and rootless with security-first defaults. Inspired by [home-operations/containers](https://github.com/home-operations/containers).

**[Image size dashboard →](https://cloudsnacks.github.io/containers/)** — per-arch compressed sizes, layer breakdowns, and size history for every image, updated on each release.

## Images

| Image | Description |
|---|---|
| `ghcr.io/cloudsnacks/actions-runner` | Rootless GitHub Actions runner for [Actions Runner Controller](https://github.com/actions/actions-runner-controller), with docker CLI, buildx and a mise-managed CLI toolchain ([`mise.toml`](images/actions-runner/mise.toml)) |
| `ghcr.io/cloudsnacks/claude-code` | Headless Claude Code agent with git-repo and agent-profile bootstrap |
| `ghcr.io/cloudsnacks/dev-desktop` | Arch Linux dev workstation with Hyprland streamed over [Sunshine](https://github.com/LizardByte/Sunshine)/Moonlight, cloud tooling, and AI coding agents (`linux/amd64` only, needs `/dev/dri`) |
| `ghcr.io/cloudsnacks/excalidraw-mcp` | Excalidraw MCP server rendering hand-drawn diagrams as an interactive MCP App |
| `ghcr.io/cloudsnacks/infisical-mcp` | Infisical MCP server (secrets management over MCP) |
| `ghcr.io/cloudsnacks/kubectl` | Rootless kubectl CLI |
| `ghcr.io/cloudsnacks/litellm` | LiteLLM proxy (non_root), our canonical build with mlflow added for the built-in mlflow logging callback |
| `ghcr.io/cloudsnacks/rrda` | JSON REST API for DNS queries, wrapping a resolver over HTTP |
| `ghcr.io/cloudsnacks/sandbox-agent` | Rootless base image for sandboxed coding agents (Node, Python, uv, git, gh, ripgrep) |

## Usage

Pin to a semver tag plus digest so tools like Renovate can track updates reliably:

```yaml
image: ghcr.io/cloudsnacks/actions-runner:2.336.0-1@sha256:<digest>
```

Every image is tagged `X.Y.Z`, `X.Y`, `X`, and `latest`. Images that track an
upstream release may carry a `-<revision>` suffix on the full tag (`2.336.0-1`)
when this repo rebuilds the same upstream version; the rolling `X.Y`, `X`, and
`latest` tags drop it.

### Defaults

- Multi-arch: `linux/amd64` and `linux/arm64`, each built on native runners (no QEMU)
- Rootless: processes run as a dedicated non-root user (uid `1001`), no sudo
- One process per container, logs to stdout, no init frameworks
- No docker CLI, except CI-runner images that build against an injected dind sidecar
- Base images pinned by digest, tool versions pinned and updated by Renovate
- SBOM and SLSA provenance attestations attached to every image
- Every published image re-scanned daily for HIGH/CRITICAL CVEs, reported to GitHub code scanning

### claude-code

The entrypoint bootstraps the sandbox, then execs the container command (default `claude -p`). Everything is optional; with no variables set the agent starts in the empty `/workspace` scratch space.

| Variable | Effect |
|---|---|
| `AGENT_REPO` | Repo cloned into `AGENT_WORKSPACE` (skipped if it already contains `.git`) |
| `AGENT_REPO_REF` | Branch or tag to clone |
| `AGENT_PROFILE_REPO` | Repo of agent profiles, shallow-cloned at startup |
| `AGENT_PROFILE` | Subdirectory of that repo to install; defaults to the repo root |
| `AGENT_PROFILE_REF` | Branch or tag of the profile repo |
| `AGENT_PROMPT` | Prompt piped to the command on stdin; omit to pipe it in yourself |
| `AGENT_WORKSPACE` | Working directory (default `/workspace`) |
| `GITHUB_TOKEN` | Configures git to authenticate `https://github.com/` clones |

The profile's contents are copied into `CLAUDE_CONFIG_DIR` (`/home/agent/.claude`), so a profile directory holds `settings.json`, `agents/`, `skills/`, `CLAUDE.md`, and anything else Claude Code reads from there.

```shell
docker run --rm \
  -e ANTHROPIC_API_KEY \
  -e AGENT_REPO=https://github.com/cloudsnacks/containers.git \
  -e AGENT_PROFILE_REPO=https://github.com/cloudsnacks/agent-profiles.git \
  -e AGENT_PROFILE=reviewer \
  -e AGENT_PROMPT="Summarise the CI workflow" \
  ghcr.io/cloudsnacks/claude-code:latest
```

### Verifying provenance

```shell
gh attestation verify oci://ghcr.io/cloudsnacks/actions-runner:2.336.0 --owner cloudsnacks
```

## Versioning and releases

Each image is versioned independently via the `version` field in its `images/<name>/metadata.yaml`:

- Images that package a single upstream application (e.g. `actions-runner`) track the upstream version, with an optional `-<revision>` suffix for rebuilds that change the image without moving the upstream version.
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

`.github/workflows/scan.yaml` runs daily and scans every published image, one job per image per platform on its native runner, uploading Trivy results to GitHub code scanning. A CVE disclosed after an image ships only surfaces on a re-scan, so this — not the build — is what catches them.

The scan reports rather than gates. Almost everything it finds lives in vendored upstream artefacts (Go binaries, the runner's .NET runtime, npm's own bundled dependencies) where a patched upstream module exists but this repo only consumes a release build, so it cannot act on the fix until upstream rebuilds. Gating merges on that would block PRs on work the repo cannot do. Treat the alerts as a queue: the ones worth acting on are the OS packages a base-image bump fixes, and language deps this repo installs directly.

## Local development

Build with [Apple container](https://github.com/apple/container) (or any BuildKit-compatible builder):

```shell
container build -t sandbox-agent:local -f images/sandbox-agent/Dockerfile images/sandbox-agent
container run --rm sandbox-agent:local node --version
```

## License

[Apache-2.0](LICENSE)
