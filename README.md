# docker-opencode

OpenCode V2 in a sandboxed Docker container (Debian trixie, uid 1000, amd64 + arm64).
The container has no secrets and remembers nothing unless you mount something.

## Run

```sh
docker run --init --rm -it -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode
```

Make it a daily habit with **either** an alias in `~/.bashrc`:

```sh
alias opencode_live='docker run --init --rm -it -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode'
```

**or** the install script, which instead installs the helper scripts `opencode-live`,
`opencode-share` (session sharing via git) and `opencode-update` (image update) into
`~/.local/bin`:

```sh
curl -fsSL https://raw.githubusercontent.com/AlmightyFrog/docker-opencode/main/install.sh | sh

opencode-live                        # same as the alias
opencode-live run "prompt"
opencode-share                       # keeps the session in .opencode-session.json → commit & share
```

## Tips

- mount the current dir into `/workspace`, run from any folder
- show what's baked into the image:
  `docker run --rm --entrypoint cat ghcr.io/almightyfrog/opencode /etc/image-versions`
- keep session history: mount `.opencode/data` as the container's data dir, see [docs/persistence.md](docs/persistence.md)
- container isolation is weaker than a VM — don't use auto-allow blindly

## Build

```sh
make build    # native arch
make buildx   # arm64 via qemu
```
