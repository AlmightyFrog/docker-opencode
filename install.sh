#!/bin/sh
# install.sh — install the opencode-live helper scripts without checking out the repo:
#
#   curl -fsSL https://raw.githubusercontent.com/AlmightyFrog/docker-opencode/main/install.sh | sh
#
# Installs opencode-live, opencode-share and opencode-update into ~/.local/bin
# and appends ~/.local/bin to PATH in your shell rc if it isn't on it yet.
# Idempotent: safe to re-run (same as `opencode-update --scripts`).
#
# options:
#   --no-path    do not touch the shell rc, only install the scripts
#
# variables (as env, e.g. curl ... | OPENCODE_BIN_DIR=~/.opt sh):
#   OPENCODE_BIN_DIR  install dir      (default ~/.local/bin)
#   OPENCODE_REF      repo ref         (default main)
#   OPENCODE_RAW      payload URL override (for testing/dev)
set -eu

REPO="${OPENCODE_REPO:-AlmightyFrog/docker-opencode}"
RAW="${OPENCODE_RAW:-https://raw.githubusercontent.com/$REPO/${OPENCODE_REF:-main}}"
BIN="${OPENCODE_BIN_DIR:-$HOME/.local/bin}"

no_path=0
for arg in "$@"; do
    case "$arg" in
        --no-path) no_path=1 ;;
        -h|--help) cat <<'EOF'
install.sh — install the opencode-live helper scripts (> ~/.local/bin), no repo checkout needed:

  curl -fsSL https://raw.githubusercontent.com/AlmightyFrog/docker-opencode/main/install.sh | sh

options:
  --no-path            do not touch the shell rc, only install the scripts
env (curl ... | OPENCODE_BIN_DIR=~/.opt sh):
  OPENCODE_BIN_DIR     install dir      (default ~/.local/bin)
  OPENCODE_REF         repo ref         (default main)
  OPENCODE_RAW         payload URL override (for testing/dev)
EOF
        exit 0 ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 1 ;;
    esac
done

if [ -z "${HOME:-}" ]; then
    echo "error: HOME is not set" >&2
    exit 1
fi
command -v curl >/dev/null 2>&1 || { echo "error: curl is required" >&2; exit 1; }
command -v docker >/dev/null 2>&1 \
    || echo "note: docker not found on PATH — install it before running opencode-live" >&2

mkdir -p "$BIN"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for script in opencode-live opencode-share opencode-update; do
    echo "==> $BIN/$script"
    curl -fsSL "$RAW/$script.sh" -o "$tmp/$script"
    cat "$tmp/$script" > "$BIN/$script"
    chmod 0755 "$BIN/$script"
done

# PATH wiring, marker-delimited and idempotent
if [ "$no_path" = 0 ]; then
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ ! -f "$rc" ]; then
            # create a missing bashrc, but don't invent a zshrc nobody uses
            case "$rc" in */.bashrc) : ;; *) continue ;; esac
            touch "$rc"
        fi
        grep -q '# >>> opencode-live >>>' "$rc" && continue
        cat >> "$rc" <<'EOF'
# >>> opencode-live >>>
case ":$PATH:" in *":$HOME/.local/bin:"*) ;;
*) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# <<< opencode-live <<<
EOF
        echo "==> PATH extended in $rc (open a new shell or: source $rc)"
    done
fi
