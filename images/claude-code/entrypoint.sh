#!/usr/bin/env bash
set -euo pipefail

workspace="${AGENT_WORKSPACE:-/workspace}"
profile_dir="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    git config --global \
        "url.https://x-access-token:${GITHUB_TOKEN}@github.com/.insteadOf" \
        "https://github.com/"
fi

if [[ -n "${AGENT_PROFILE_REPO:-}" ]]; then
    checkout="$(mktemp -d)"
    git clone --depth 1 ${AGENT_PROFILE_REF:+--branch "${AGENT_PROFILE_REF}"} \
        "${AGENT_PROFILE_REPO}" "${checkout}"
    source="${checkout}${AGENT_PROFILE:+/${AGENT_PROFILE}}"
    if [[ ! -d "${source}" ]]; then
        echo "agent profile not found in repo: ${AGENT_PROFILE:-<root>}" >&2
        exit 1
    fi
    rm -rf "${checkout}/.git"
    mkdir -p "${profile_dir}"
    cp -aT "${source}" "${profile_dir}"
    rm -rf "${checkout}"
fi

mkdir -p "${workspace}"
if [[ -n "${AGENT_REPO:-}" && ! -d "${workspace}/.git" ]]; then
    git clone ${AGENT_REPO_REF:+--branch "${AGENT_REPO_REF}"} "${AGENT_REPO}" "${workspace}"
fi
cd "${workspace}"

if [[ -n "${AGENT_PROMPT:-}" ]]; then
    exec "$@" <<<"${AGENT_PROMPT}"
fi

exec "$@"
