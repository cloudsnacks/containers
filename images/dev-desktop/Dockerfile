FROM archlinux:base@sha256:63c7b061c0c001cb7ce4f8d11b63d351c23e7f97121bc5c8bd5d9f431e615d7d

# Sunshine ships an official Arch package as a release asset, so no AUR/makepkg is needed.
# renovate: datasource=github-releases depName=LizardByte/Sunshine extractVersion=^v(?<version>.+)$
ARG SUNSHINE_VERSION=2026.914.233613
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.273
# renovate: datasource=npm depName=@openai/codex
ARG CODEX_VERSION=0.154.0
# renovate: datasource=npm depName=@google/gemini-cli
ARG GEMINI_CLI_VERSION=0.60.0
# renovate: datasource=npm depName=opencode-ai
ARG OPENCODE_VERSION=1.18.31
# renovate: datasource=github-releases depName=herdrdev/herdr extractVersion=^v(?<version>.+)$
ARG HERDR_VERSION=0.9.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG=C.UTF-8

# Trim docs/locales before any package lands so every later install stays lean.
# These are [options] directives, so they are inserted into that section rather
# than appended (appending would land them in the last repo section).
# DisableSandbox: pacman 7 drops to the 'alpm' user behind seccomp/Landlock to
# download, which fails under emulated and nested builds. Build-time only.
RUN printf '%s\n' \
        'NoExtract = usr/share/doc/*' \
        'NoExtract = usr/share/man/* !usr/share/man/man1/*' \
        'NoExtract = usr/share/locale/* !usr/share/locale/en*/*' \
        'NoExtract = usr/share/i18n/*' \
        'DisableSandbox' \
        > /tmp/pacman-opts \
    && sed -i '/^\[options\]/r /tmp/pacman-opts' /etc/pacman.conf \
    && rm -f /tmp/pacman-opts

# archlinux:base is rebuilt weekly; refresh the keyring first or signatures fail
# on any package newer than the snapshot.
RUN pacman -Sy --noconfirm archlinux-keyring \
    && pacman -Su --noconfirm \
    && pacman -S --noconfirm --needed \
        gcc make pkgconf \
        git git-lfs github-cli openssh \
        curl wget jq less tree rsync unzip zip which man-db \
        ripgrep fd eza bat fzf zoxide starship tmux zsh neovim htop btop \
        python python-pip uv nodejs npm go rust \
        kubectl helm k9s kubectx stern opentofu terraform aws-cli-v2 azure-cli \
        chezmoi \
        hyprland xdg-desktop-portal xdg-desktop-portal-hyprland xorg-xwayland \
        foot waybar wofi mako \
        pipewire pipewire-pulse wireplumber \
        mesa vulkan-swrast intel-media-driver libva-utils \
        dbus polkit seatd avahi \
        ttf-jetbrains-mono-nerd noto-fonts \
    && pacman -Scc --noconfirm \
    && rm -rf /var/cache/pacman/pkg/* /var/lib/pacman/sync/* \
    && XDG_RUNTIME_DIR=/tmp Hyprland --version \
    && kubectl version --client \
    && terraform version \
    && node --version

# pacman -U pulls the package's dependencies from the repos, so the sync DB that
# the previous layer removed has to be refreshed first.
RUN curl -fsSL -o /tmp/sunshine.pkg.tar.zst \
        "https://github.com/LizardByte/Sunshine/releases/download/v${SUNSHINE_VERSION}/sunshine-${SUNSHINE_VERSION}-1-x86_64.pkg.tar.zst" \
    && pacman -Sy --noconfirm \
    && pacman -U --noconfirm /tmp/sunshine.pkg.tar.zst \
    && rm -f /tmp/sunshine.pkg.tar.zst \
    && pacman -Scc --noconfirm \
    && rm -rf /var/cache/pacman/pkg/* /var/lib/pacman/sync/* \
    && sunshine --version

# claude-code and opencode fetch their platform-native binary in postinstall, which
# recent npm blocks by default; they are opted in explicitly rather than globally.
RUN npm install -g --no-fund --no-audit \
        --allow-scripts=@anthropic-ai/claude-code,opencode-ai \
        "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
        "@openai/codex@${CODEX_VERSION}" \
        "@google/gemini-cli@${GEMINI_CLI_VERSION}" \
        "opencode-ai@${OPENCODE_VERSION}" \
    && npm cache clean --force \
    && claude --version \
    && codex --version \
    && gemini --version \
    && opencode --version

# herdr ships raw per-arch binaries as release assets, not a package repo.
RUN curl -fsSL -o /usr/local/bin/herdr \
        "https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/herdr-linux-x86_64" \
    && chmod 0755 /usr/local/bin/herdr \
    && herdr --version

# video/render gate /dev/dri, input gates /dev/uinput for Moonlight input injection.
RUN groupadd --gid 1001 dev \
    && useradd --uid 1001 --gid dev --create-home --shell /usr/bin/zsh dev \
    && for g in video render input audio seat; do \
        getent group "${g}" > /dev/null || groupadd --system "${g}"; \
       done \
    && usermod -aG video,render,input,audio,seat dev \
    && mkdir -p /workspace /run/user/1001 \
    && chown dev:dev /workspace /run/user/1001 \
    && chmod 700 /run/user/1001

# Hyprland is PID 1 and starts the session via exec-once; no supervisor is used.
# Written to the user's primary config path rather than relying on an /etc/xdg fallback.
# The directory is dev-owned so Hyprland can write state; the config itself only
# needs to be readable.
RUN install -d -o dev -g dev /home/dev/.config /home/dev/.config/hypr \
    && cat > /home/dev/.config/hypr/hyprland.conf <<'EOF'
# Headless session for remote streaming; the output is created at runtime
# because the headless backend starts with zero outputs.
monitor = HEADLESS-1, 1920x1080@60, 0x0, 1

exec-once = hyprctl output create headless HEADLESS-1
exec-once = /usr/bin/wireplumber
exec-once = /usr/bin/sunshine
exec-once = /usr/bin/waybar
exec-once = /usr/bin/mako

input {
    kb_layout = us
    follow_mouse = 1
}

general {
    gaps_in = 4
    gaps_out = 8
    border_size = 2
}

decoration {
    rounding = 6
}

animations {
    enabled = false
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}

$mod = SUPER
bind = $mod, Return, exec, /usr/bin/foot
bind = $mod, Q, killactive,
bind = $mod, E, exec, /usr/bin/wofi --show drun
bind = $mod, F, fullscreen,
EOF

# Fail with a readable message instead of aquamarine's "no allocator available":
# Hyprland's headless backend reports drmFD() == -1, so a real render node must
# be present for a GBM allocator to exist.
RUN cat > /usr/local/bin/start-desktop <<'START' && chmod 0755 /usr/local/bin/start-desktop
#!/usr/bin/env bash
set -euo pipefail

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

if [[ ! -e /dev/dri/renderD128 ]]; then
    echo "FATAL: /dev/dri/renderD128 is missing." >&2
    echo "Hyprland cannot start without a DRM render node, even headless." >&2
    echo "Mount /dev/dri into the pod and set the matching supplementalGroups." >&2
    exit 1
fi

exec Hyprland "$@"
START

ENV DOTFILES_REPO=https://github.com/swibrow/dotfiles.git \
    XDG_RUNTIME_DIR=/run/user/1001 \
    XDG_SESSION_TYPE=wayland \
    XDG_CURRENT_DESKTOP=Hyprland \
    NPM_CONFIG_PREFIX=/home/dev/.npm \
    PATH=/home/dev/.npm/bin:/home/dev/.local/bin:/home/dev/go/bin:/home/dev/.cargo/bin:/usr/local/bin:/usr/bin:/bin

USER dev
WORKDIR /workspace

EXPOSE 47984/tcp 47989/tcp 47990/tcp 48010/tcp
EXPOSE 47998/udp 47999/udp 48000/udp 48002/udp

LABEL org.opencontainers.image.description="Arch Linux dev workstation with Hyprland streamed over Sunshine/Moonlight, cloud tooling, and AI coding agents"

CMD ["/usr/local/bin/start-desktop"]
