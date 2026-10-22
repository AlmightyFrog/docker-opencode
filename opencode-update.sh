#!/usr/bin/env bash
# opencode-update.sh — pull the latest container image and/or refresh the
# opencode-live helper scripts installed in ~/.local/bin
#
# usage:
#   opencode-update            image + installed scripts (default)
#   opencode-update --image    only docker pull
#   opencode-update --scripts  only refresh the installed scripts
#
# environment:
#   OPENCODE_IMAGE     container image                    (default ghcr.io/almightyfrog/opencode)
#   OPENCODE_REF       repo ref the scripts come from     (default main)
#   OPENCODE_RAW       payload URL override               (for testing/dev)
#   OPENCODE_BIN_DIR   install dir                        (default ~/.local/bin)
set -euo pipefail

IMAGE="${OPENCODE_IMAGE:-ghcr.io/almightyfrog/opencode}"
RAW="${OPENCODE_RAW:-https://raw.githubusercontent.com/AlmightyFrog/docker-opencode/${OPENCODE_REF:-main}}"
BIN="${OPENCODE_BIN_DIR:-$HOME/.local/bin}"

usage() { sed -n '5,14p' "$0"; }

pull=0 scripts=0
if [ $# -eq 0 ]; then pull=1 scripts=1; fi
while [ $# -gt 0 ]; do
    case "$1" in
        --image) pull=1 ;;
        --scripts) scripts=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown option: $1 (see 'opencode-update --help')" >&2; exit 1 ;;
    esac
    shift
done

if [ "$pull" = 1 ]; then
    echo "==> docker pull $IMAGE"
    docker pull "$IMAGE"
fi

if [ "$scripts" = 1 ]; then
    echo "==> refreshing helper scripts in $BIN (from $RAW)"
    command -v curl >/dev/null 2>&1 || { echo "error: curl is required" >&2; exit 1; }
    mkdir -p "$BIN"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    for script in opencode-live opencode-share opencode-update; do
        curl -fsSL "$RAW/$script.sh" -o "$tmp/$script"
        mv "$tmp/$script" "$BIN/$script"
        chmod 0755 "$BIN/$script"
    done
    echo "    done"
fi
