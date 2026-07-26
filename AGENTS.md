# containers

Monorepo of public container images published to `ghcr.io/cloudsnacks/<name>`. One directory per image under `images/`, each with a `Dockerfile` and a `metadata.yaml` (name, version, platforms, smoke-test command). When adding a new image, use the `add-image` skill (`.agents/skills/add-image/SKILL.md`).

## Conventions

- Images are rootless: create a dedicated user with uid/gid `1001` and end the Dockerfile with `USER`. No sudo, no init frameworks (s6, supervisord).
- No docker CLI, **except** CI-runner images (`actions-runner`), where workflows build images against the dind sidecar the orchestrator injects. That sidecar's socket is already shared into the container, so the client binary crosses no trust boundary the runner doesn't already have. This is not a licence to add docker anywhere else.
- Multi-arch (`linux/amd64` + `linux/arm64`): use `ARG TARGETARCH` to select download artifacts; never hardcode an architecture.
- Pin everything: base images by digest, downloaded tools by version with a `# renovate: datasource=... depName=...` comment directly above the `ARG` (or the `version:` field in metadata.yaml) so Renovate can bump them.
- Every version change ships through the `version` field in `metadata.yaml` — bump it in the same PR as the image change, following the rules in [README.md](README.md#versioning-and-releases). CI tags `X.Y.Z`, `X.Y`, `X`, `latest`.
- Keep each `metadata.yaml` `test` command working — CI runs it via `sh -c` in the freshly built image on every PR.
- Dockerfiles must pass hadolint (config in `.hadolint.yaml`).
- YAML files use the `.yaml` extension.

## Local builds

Use `container` (Apple container), not docker:

```shell
container build -t <name>:local -f images/<name>/Dockerfile images/<name>
```

CI (`.github/workflows/build.yaml`) builds changed images on native amd64/arm64 runners, merges digests into a manifest list, and attaches SBOM + provenance attestations. Third-party actions are pinned to commit SHAs — keep it that way when editing workflows.
