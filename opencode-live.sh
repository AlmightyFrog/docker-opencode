#!/usr/bin/env bash
# opencode-live.sh — daily driver for the OpenCode dev container
#
# Installed as ~/.local/bin/opencode-live by install.sh (the opencode_live alias
# points at it). Fully volatile run: only the current directory is mounted at
# /workspace and nothing is remembered after the container exits. All arguments
# are passed through to the container entrypoint (TUI, `run "prompt"`, `bash`, ...).
#
# usage:
#   opencode-live                  interactive TUI on the current directory
#   opencode-live run "prompt"     one-off prompt
#   opencode-live bash             plain shell inside the container
#
# environment:
#   OPENCODE_IMAGE        container image                    (default ghcr.io/almightyfrog/opencode)
#   OPENCODE_DOCKER_ARGS  extra docker run args, word-split  (e.g. persistence mounts, see README)
set -euo pipefail

IMAGE="${OPENCODE_IMAGE:-ghcr.io/almightyfrog/opencode}"
tty=(); if [ -t 0 ] && [ -t 1 ]; then tty=(-it); fi

# shellcheck disable=SC2086
exec docker run --init --rm ${tty[@]+"${tty[@]}"} ${OPENCODE_DOCKER_ARGS:-} \
    -v "$PWD:/workspace" "$IMAGE" "$@"
