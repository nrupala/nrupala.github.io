# Contributing

## Change management (PR-flow discipline)

This repo follows the standing PR-flow discipline — direct pushes to `main` are retired:

- All changes land via **draft PRs** → owner reviews and merges.
- **No direct pushes to `main`** — ever.
- Each PR adds a `CHANGELOG.md` entry under `## [Unreleased]`.
- **Semver bumps** (patch = fix, minor = feature): this repo versions itself via
  the top-level `VERSION` file. Bump with the standard tool (updates `VERSION`
  and the on-page `<meta name="app-version">` marker together):
  ```bash
  node scripts/bump-version.mjs <X.Y.Z>
  ```
  Never hand-edit the version in `index.html` directly.
- Merge commits **reference the PR number**.
- A release = tagging `vX.Y.Z` after merge; the tag MUST equal `VERSION` (CI
  fails otherwise — see `.github/workflows/app-versioning.yml` and
  `docs/VERSIONING.md` for the full standard).
