# containers

Monorepo of public container images published to `ghcr.io/cloudsnacks/<app>`. One directory per image under `apps/`, each with a `Dockerfile` and a `metadata.yaml` (name, version, platforms, smoke-test command).

## Conventions

- Images are rootless: create a dedicated user with uid/gid `1001` and end the Dockerfile with `USER`. No sudo, no docker CLI, no init frameworks (s6, supervisord).
- Multi-arch (`linux/amd64` + `linux/arm64`): use `ARG TARGETARCH` to select download artifacts; never hardcode an architecture.
- Pin everything: base images by digest, downloaded tools by version with a `# renovate: datasource=... depName=...` comment directly above the `ARG` (or the `version:` field in metadata.yaml) so Renovate can bump them.
- Every version change ships through the `version` field in `metadata.yaml` — bump it in the same PR as the image change, following the rules in [README.md](README.md#versioning-and-releases). CI tags `X.Y.Z`, `X.Y`, `X`, `latest`.
- Keep each `metadata.yaml` `test` command working — CI runs it via `sh -c` in the freshly built image on every PR.
- Dockerfiles must pass hadolint (config in `.hadolint.yaml`).
- YAML files use the `.yaml` extension.

## Local builds

Use `container` (Apple container), not docker:

```shell
container build -t <app>:local -f apps/<app>/Dockerfile apps/<app>
```

CI (`.github/workflows/build.yaml`) builds changed apps on native amd64/arm64 runners, merges digests into a manifest list, and attaches SBOM + provenance attestations. Third-party actions are pinned to commit SHAs — keep it that way when editing workflows.
