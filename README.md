# nrupala.github.io

Public portfolio index — a single static page listing Nrupal Akolkar's projects
and repositories. Served at <https://nrupala.github.io> via GitHub Pages.

## What's here

- `index.html` — the whole site: a dark-themed index page (project table with
  descriptions, badges, and links) styled inline. No build step; open it in a
  browser.
- `VERSION` — single source of truth for the site version (SemVer).
- `CHANGELOG.md` — version history (Keep a Changelog).
- `docs/VERSIONING.md` — the app versioning standard used across his projects.
- `scripts/bump-version.mjs` — author-time version bump (updates `VERSION` and
  the `app-version` meta marker in `index.html` together).
- `scripts/stamp-app-version.sh` — build-time version stamping for native apps
  (Android/iOS); not used by this static page.
- `.github/workflows/app-versioning.yml` — version guard + GitHub Release
  publisher on `v*` tags.

## Quickstart

Open `index.html` in any browser — there is no build step and no dependencies.

## Build & test

No build. No automated tests. The version guard runs in CI on tags:
push a tag `vX.Y.Z` matching `VERSION` and the workflow publishes a GitHub
Release (auto-generated release notes).

## Changing the site

Edit `index.html`, follow the PR-flow in `CONTRIBUTING.md`, and bump the
version for any user-visible change:

```bash
node scripts/bump-version.mjs <X.Y.Z>
```

GitHub Pages republishes `main` automatically — there is no separate deploy step.
