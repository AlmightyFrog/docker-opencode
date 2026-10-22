#!/usr/bin/env bash
# opencode-share.sh — run OpenCode in the container, persisting the session in one file
#
# Session context is kept in .opencode-session.json (path configurable via SESSION_FILE). When
# committed to git, the file lets others continue the same session in their own container
# with their own model credentials. The container's opencode database is temporary: it is
# rebuilt from the session file at start and discarded when the container exits; if a session
# file exists it is imported and continued automatically (TUI opens it, `run` appends to it).
# Environment variables ending in _API_KEY are forwarded into the container.
#
# usage:
#   ./opencode-share.sh                  opens the interactive TUI
#   ./opencode-share.sh run "prompt"     one-off prompt; all arguments are passed
#                                        through to the opencode CLI
#
# environment:
#   OPENCODE_IMAGE  container image                     (default ghcr.io/almightyfrog/opencode)
#   SESSION_FILE    session file path inside the repo   (default .opencode-session.json)
#   HOST_CONFIG     if set and non-0: mount ~/.config/opencode/opencode.jsonc read-only as
#                   the container config; provider URLs must be reachable from the container
#                   (e.g. a LAN IP), since localhost inside the container is the container
set -euo pipefail

IMAGE="${OPENCODE_IMAGE:-ghcr.io/almightyfrog/opencode}"
SF="${SESSION_FILE:-.opencode-session.json}"
case "$SF" in "$PWD"/*) SF="${SF#"$PWD"/}" ;; ./*) SF="${SF#./}" ;; esac  # relative to repo root

envargs=()
while read -r k; do envargs+=(-e "$k"); done < <(compgen -e | grep '_API_KEY$' || true)
tty=(); if [ -t 0 ] && [ -t 1 ]; then tty=(-it); fi

cfg=()
if [ -n "${HOST_CONFIG:-}" ] && [ "${HOST_CONFIG:-}" != 0 ]; then
    oc_cfg="$HOME/.config/opencode/opencode.jsonc"
    if [ -f "$oc_cfg" ]; then
        cfg=(-v "$oc_cfg:/home/opencode/.config/opencode/opencode.jsonc:ro")
    else
        echo "warning: $oc_cfg not found, using container defaults" >&2
    fi
fi

docker run --init --rm "${tty[@]+"${tty[@]}"}" "${envargs[@]+"${envargs[@]}"}" \
    "${cfg[@]+"${cfg[@]}"}" -v "$PWD:/workspace" "$IMAGE" bash -c '
set -u
S="/workspace/$1"; shift
if [ -f "$S" ]; then
    opencode session import --standalone "$S" >/dev/null 2>&1
    # auto-continue the imported session: TUI gets -c, run gets -c after the subcommand
    case "${1:-}" in run) set -- run -c "${@:2}" ;; "") set -- -c ;; esac
fi
opencode "$@"; rc=$?
opencode service stop >/dev/null 2>&1
mkdir -p "$(dirname "$S")"
SID=$(opencode session list --standalone 2>/dev/null | head -n1 | cut -f1)
if [ -n "$SID" ] && opencode session export --standalone "$SID" 2>/dev/null > "$S.new" \
   && grep -q "\"messages\"" "$S.new"; then
    cmp -s "$S.new" "$S" || mv "$S.new" "$S"
fi
rm -f "$S.new"
exit $rc
' bash "$SF" "$@"
