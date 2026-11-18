# mahatracker.org

A static site built from Typst content. `site.typ` pulls in `content/` and
`lib.typ`, Typst's HTML export writes `_site/index.html`, and GitHub Actions
publishes to GitHub Pages from `main`.

## Toolchain: use the Nix flake

`typst` and `just` come from the flake's devShell (`flake.nix` ->
`devShells.default`). They are **not** on the login PATH, and `direnv` is not
installed, so `.envrc`'s `use flake` never fires. A bare `just` fails with
`command not found` (exit 127).

Run every project command through the flake:

```bash
nix develop -c just <recipe>
```

**In a fresh shell `nix` itself may not be on PATH.** `~/.bashrc` and
`/etc/profile.d/nix.sh` both source the Nix profile, but a shell that inherits
`__ETC_PROFILE_NIX_SOURCED=1` with a rewritten `PATH` (Claude Code's shell
snapshot does this) skips it and ends up without `nix`. Use the absolute path,
which always works:

```bash
/nix/var/nix/profiles/default/bin/nix develop -c just <recipe>
```

Flakes are already enabled via `~/.config/nix/nix.conf`, so no
`--extra-experimental-features` flag is needed. Never invoke a binary out of
`/nix/store/...` directly — those paths break on the next `nix flake update`.

## Commands

| Task | Command |
| --- | --- |
| Serve with live reload | `nix develop -c just watch` |
| Build into `_site/` | `nix develop -c just build` |
| Lint the records | `nix develop -c just check` |
| Build exactly as CI does | `nix build` (output in `result/`) |

### Run locally

Kill any watcher for this folder first, then start a new one. The port is
pinned to 3000, so a leftover watcher makes the new one die with
`port 3000 is already in use`:

```bash
pgrep -f "typst watch --format" | xargs -r kill
cd /home/chi/mahatracker.org && /nix/var/nix/profiles/default/bin/nix develop -c just watch
```

Serves at <http://127.0.0.1:3000> with live reload. Other Claude sessions on
this machine have been seen starting their own detached watcher on this folder
and taking port 3000 — check for one before assuming the port is free.

The `html export is under active development and incomplete` warning on every
compile is expected and is not an error.

### Push to site

Pushing to `main` *is* deploying: `.github/workflows/pages.yml` builds with
`nix build` and publishes to Pages on every push to `main`. Commit everything
with a message written from the actual diff, then push:

```bash
git add -A && git commit && git push origin main
```

A failing build never reaches the live site, so run `nix develop -c just check`
before pushing content changes.

## Conventions

- Entries live in `content/entries.typ`; `lib.typ` holds the rendering helpers
  and the `warnings()` check that `just check` surfaces (missing sources,
  likely duplicates).
- `_site/` and `result/` are build output — never edit them by hand.
