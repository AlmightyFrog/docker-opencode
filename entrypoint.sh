#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME:-/tmp}/.config}/opencode"

if [ -z "${HOME:-}" ]; then
    echo "warning: HOME is not set, using $CONFIG_DIR for config" >&2
fi

# seed default config into a freshly-mounted (empty) config volume
if ! mkdir -p "$CONFIG_DIR" 2>/dev/null; then
    echo "warning: $CONFIG_DIR not writable, skipping config seed" >&2
elif ! compgen -G "$CONFIG_DIR"/opencode.json* > /dev/null; then
    if cp /opt/opencode-defaults/opencode.jsonc "$CONFIG_DIR/opencode.jsonc" 2>/dev/null; then
        echo "seeded default opencode config" >&2
    else
        echo "warning: cannot seed config into $CONFIG_DIR, using opencode defaults" >&2
    fi
fi

# no args / flags / subcommands -> opencode; real binaries, paths and dirs exec directly
if [ "${1:-}" = "opencode" ]; then
    shift
fi
case "${1:-}" in
    ""|-*) set -- opencode "$@" ;;
    ./*|/*) [ -d "$1" ] && set -- opencode "$@" ;;
    *) type -P "$1" >/dev/null 2>&1 || set -- opencode "$@" ;;
esac

exec "$@"
