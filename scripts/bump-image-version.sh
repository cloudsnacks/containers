#!/usr/bin/env bash
# Bumps the patch version in images/<name>/metadata.yaml. Run by Renovate as a
# post-upgrade task so dependency updates publish a new image tag instead of
# rebuilding over the existing one.
set -euo pipefail

metadata="${1:?usage: bump-image-version.sh images/<name>}/metadata.yaml"
version="$(sed -n 's/^version: //p' "${metadata}")"
IFS=. read -r major minor patch <<<"${version}"
next="${major}.${minor}.$((patch + 1))"

tmp="$(mktemp)"
sed "s/^version: .*/version: ${next}/" "${metadata}" >"${tmp}"
cat "${tmp}" >"${metadata}"
rm -f "${tmp}"
