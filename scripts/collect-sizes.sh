#!/usr/bin/env bash
set -euo pipefail

# Collect compressed sizes and layer details for a published image version
# into the size-tracking dataset served by GitHub Pages.
#
# Usage: collect-sizes.sh <image> <version> <data-dir>
#
# Requires: skopeo, jq. Reads images/<image>/metadata.yaml for the
# description when run from the repo root and yq is available.

image="$1"
version="$2"
data_dir="$3"
owner="${GITHUB_REPOSITORY_OWNER:-cloudsnacks}"
ref="ghcr.io/${owner}/${image}"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

skopeo inspect --raw "docker://${ref}:${version}" >"${tmp}/index.json"
index_digest="$(skopeo manifest-digest "${tmp}/index.json")"

platforms="{}"
while read -r platform digest; do
  skopeo inspect --raw "docker://${ref}@${digest}" >"${tmp}/manifest.json"
  skopeo inspect --config "docker://${ref}@${digest}" >"${tmp}/config.json"
  entry="$(jq -n \
    --arg digest "${digest}" \
    --slurpfile manifest "${tmp}/manifest.json" \
    --slurpfile config "${tmp}/config.json" '
    ($config[0].history // [] | map(select(.empty_layer | not) | (.created_by // ""))) as $cmds |
    {
      digest: $digest,
      size: ([$manifest[0].layers[].size] | add),
      layers: [$manifest[0].layers | to_entries[] |
        {digest: .value.digest, size: .value.size, command: ($cmds[.key] // "")}]
    }')"
  platforms="$(jq -n --argjson acc "${platforms}" --arg platform "${platform}" \
    --argjson entry "${entry}" '$acc + {($platform): $entry}')"
done < <(jq -r '.manifests[]
  | select(.platform.os != "unknown")
  | .platform.os + "/" + .platform.architecture + " " + .digest' "${tmp}/index.json")

description=""
if command -v yq >/dev/null && [[ -f "images/${image}/metadata.yaml" ]]; then
  description="$(yq '.description // ""' "images/${image}/metadata.yaml")"
fi

record="$(jq -n \
  --arg version "${version}" \
  --arg digest "${index_digest}" \
  --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson platforms "${platforms}" \
  '{version: $version, digest: $digest, collectedAt: $date, platforms: $platforms}')"

mkdir -p "${data_dir}"
file="${data_dir}/${image}.json"
if [[ ! -f "${file}" ]]; then
  jq -n --arg name "${image}" '{name: $name, history: []}' >"${file}"
fi

jq --argjson rec "${record}" --arg description "${description}" '
  .description = (if $description != "" then $description else (.description // "") end)
  | .history = ([.history[] | select(.version != $rec.version)] + [$rec])
' "${file}" >"${file}.tmp" && mv "${file}.tmp" "${file}"

echo "collected ${image}:${version} (${index_digest})"
