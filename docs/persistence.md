# Persistence

Default runs are fully volatile: nothing survives unless you mount it.
Sessions, history and auth live in one SQLite file, `~/.local/share/opencode/opencode.db`.

## Keep sessions

Mount the whole data dir (a single-file db mount loses the `-wal`/`-shm` sidecars),
with scratch dirs on tmpfs:

```sh
D=/home/opencode/.local/share/opencode
mkdir -p .opencode/data
docker run --init --rm -it -v "$PWD:/workspace" -v "$PWD/.opencode/data:$D" \
    --tmpfs "$D/log" --tmpfs "$D/snapshot" --tmpfs "$D/shell" --tmpfs "$D/repos" \
    ghcr.io/almightyfrog/opencode
```

One db, so one folder serves all your project folders.

With `opencode-live`, same thing via `OPENCODE_DOCKER_ARGS`:

```sh
export OPENCODE_DOCKER_ARGS="-v $PWD/.opencode/data:$D \
    --tmpfs $D/log --tmpfs $D/snapshot --tmpfs $D/shell --tmpfs $D/repos"
opencode-live
```

Know before mounting:

- the db also stores auth → add `.opencode/` to `.gitignore`, never commit it
- mounted host files must be writable by uid 1000
- tmpfs `snapshot/` keeps `/undo` checkpoints out of disk (session history is unaffected)
- your own config instead of the seeded default: `-v ./.opencode-config:/home/opencode/.config/opencode`

## Share sessions via git

Easiest: `opencode-share` — volatile db, the session lands in one small
`.opencode-session.json`, auto re-imported/continued on the next run. Commit it to share.
The export is a few KB of plain JSON with no auth material, but it does contain your chat
text — share only with people you trust with it.

Handcrafted variant, same result:

```sh
# owner: export the newest session into the repo
SID=$(docker run --rm -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode session list --standalone | head -1 | cut -f1)
docker run --rm -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode session export --standalone "$SID" > .opencode-session.json
git add .opencode-session.json && git commit -m "share opencode session"

# teammate (after clone): import and continue
docker run --init --rm -it -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode session import --standalone .opencode-session.json
docker run --init --rm -it -v "$PWD:/workspace" ghcr.io/almightyfrog/opencode run -c
```

Details:

- the teammate needs their own login; nothing about your account transfers
- `session export --sanitize` redacts all message text — for public bug reports, not team sharing
- `opencode-share` round-trips only the newest top-level session; parallel sessions need
  one `SESSION_FILE` each, and `/undo` checkpoints do not survive
