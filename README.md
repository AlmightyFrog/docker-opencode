# Docker OpenCode container
A throwaway dev container for [OpenCode V2](https://github.com/anomalyco/opencode/tree/v2).
Based on Debian trixie, uid/gid 1000, passwordless sudo and several dev tools preinstalled built for amd64 and arm64.

It is useful to sandbox OpenCode and only pass through defined folders RW/RO to be able to use auto allow without exposing whole system.

(!) Still always remember: a docker container is less safe/isolated than a vm or separate physical machine!


## Quick start
It is intended to use it with current directory mapped to `/workspace`; the image has no secrets and
remembers nothing unless you give it a specific volume.

The entrypoint routes arguments: flags and OpenCode subcommands reach the OpenCode CLI, while mostly anything that is a real binary, path
or directory runs as-is.

```sh
# interactive TUI
docker run --init --rm -it -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode

# plain shell
docker run --init --rm -it -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode bash

# one-off prompt
docker run --init --rm -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode run "explain this repo"

# list toolset baked into image
docker run --rm --entrypoint cat ghcr.io/almightyfrog/opencode /etc/image-versions
```


## Bash alias

For daily use — it also underlines the throwaway character: just the
mounted folder, no state kept. Add to your `~/.bashrc`:

```sh
alias opencode_live='docker run --init --rm -it -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode'
```

The single quotes matter: `$PWD` expands when you call the alias, not when
the shell starts. Run `opencode_live` in any folder to open the TUI on it,
or pass arguments through — `opencode_live bash`, `opencode_live run "explain this workspace"`.


## Persistence
Please note following mounts are both not sufficient tested and might be subject to change, but they are good guess...

| want to keep | mount |
|---|---|
| sessions & auth | `-v ./.opencode-data:/home/opencode/.local/share/opencode` |
| config | `-v ./.opencode-config:/home/opencode/.config/opencode` |


## Permissions
An empty config mount is seeded with sane defaults: `/tmp` and `/workspace`
read/write allowed, `.env` files still ask before being read.

## Building locally
```sh
# list commands
make help

# build native container
make build

# build container with qemu
make buildx
```

## AI use
Written primarily with AI coding agents (OpenCode and GitHub Copilot),
a human reviewed and owns whatever ships here.