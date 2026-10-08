# Minimal OpenCode dev container, similar to ghcr.io/anomalyco/opencode
FROM debian:trixie-slim

LABEL org.opencontainers.image.title="opencode" \
      org.opencontainers.image.description="OpenCode V2 dev container on Debian trixie, uid 1000" \
      org.opencontainers.image.source="https://github.com/AlmightyFrog/docker-opencode" \
      org.opencontainers.image.licenses="MIT-0" \
      org.opencontainers.image.base.name="docker.io/library/debian:trixie-slim"

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git openssh-client sudo jq \
        ripgrep fzf nano p7zip-full unzip zip xz-utils zstd \
        file python3 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# non-root user 1000:1000 with passwordless sudo
RUN groupadd -g 1000 opencode \
    && useradd -m -u 1000 -g 1000 -s /bin/bash opencode \
    && git config --file /home/opencode/.gitconfig --add safe.directory '*' \
    && chown 1000:1000 /home/opencode/.gitconfig

# sudoers: 0440 is required; keep opencode/uv on PATH under sudo
RUN { echo 'Defaults env_keep += "PATH"'; \
      echo 'Defaults secure_path="/home/opencode/.opencode/bin:/home/opencode/.local/bin:/usr/local/bin:/usr/bin"'; \
      echo 'opencode ALL=(ALL) NOPASSWD:ALL'; } > /etc/sudoers.d/opencode \
    && chmod 0440 /etc/sudoers.d/opencode

# tooling as user 1000 (auto-update friendly)
RUN runuser -u opencode -- bash -c \
        'curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path' \
    && runuser -u opencode -- bash -c \
        'curl -LsSf https://astral.sh/uv/install.sh | sh'

# version manifest: labels are static, so record what actually got installed
RUN printf '%-12s %s\n' \
        "debian" "$(cut -d= -f2 /etc/debian_version)" \
        "arch" "$(uname -m)" \
        "opencode" "$(/home/opencode/.opencode/bin/opencode --version | cut -d' ' -f2)" \
        "uv" "$(/home/opencode/.local/bin/uv --version | cut -d' ' -f2)" \
        "git" "$(git --version | cut -d' ' -f3)" \
        "python" "$(python3 --version | cut -d' ' -f2)" \
        "jq" "$(jq --version)" \
        "7zip" "$(7z 2>/dev/null | sed -n 's/^7-Zip \([0-9.]*\).*/\1/p')" \
        > /etc/image-versions \
    && chmod 644 /etc/image-versions

# default config; entrypoint seeds it into empty config volumes
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY config/opencode.jsonc /opt/opencode-defaults/opencode.jsonc

RUN mkdir -p /workspace \
    && mkdir -p /home/opencode/.config/opencode /home/opencode/.local/share/opencode \
    && chown -R 1000:1000 /workspace /home/opencode/.config /home/opencode/.local

WORKDIR /workspace
USER 1000:1000
ENV PATH="/home/opencode/.opencode/bin:/home/opencode/.local/bin:${PATH}"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opencode"]