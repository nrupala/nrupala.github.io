# App Versioning Standard

The single versioning standard for **every** app built here - plain web app,
PWA, Android APK, or iOS native. One version, one source of truth, stamped
consistently onto every surface, with a changelog and auto-generated release
notes so history never gets lost.

## Principles
1. **One source of truth.** `package.json` `"version"` (SemVer `X.Y.Z`) is the
   canonical version. (Non-JS repos: a top-level `VERSION` file instead.)
2. **The tag is the release.** Cutting a release = tagging the repo:
   - canonical: `v<X.Y.Z>`
   - APK-only builds may also use `apk-v<X.Y.Z>` (both are accepted by the stamp script).
   The tag MUST equal `package.json` version - CI fails the build otherwise.
3. **Every surface derives from that one version** - never hand-edited per file.
4. **History is durable.** `CHANGELOG.md` (Keep a Changelog) + GitHub
   auto-generated release notes per tag.

## Per-surface mapping
| Surface | Field | Value |
|---|---|---|
| Web app | on-page footer / `<meta>` version marker | `X.Y.Z` |
| PWA | `manifest.json` `version` | `X.Y.Z` |
| PWA | service-worker cache name (`CACHE` / `CACHE_NAME`) | `<app>-v<X.Y.Z>` (bump invalidates old caches on release) |
| Android | `versionName` | `X.Y.Z` |
| Android | `versionCode` | `MAJOR*10000 + MINOR*100 + PATCH` (monotonic; F-Droid/Play safe) |
| iOS | `CFBundleShortVersionString` | `X.Y.Z` |
| iOS | `CFBundleVersion` | same integer as Android `versionCode` |

`versionCode` scheme: `0.2.1 -> 201`, `0.3.0 -> 300`, `1.0.0 -> 10000`.
Constraint: MINOR and PATCH must each stay `< 100`. (More headroom later? switch
repo-wide to `MAJOR*1000000 + MINOR*1000 + PATCH`.)

## Two moving parts
- **Author time - `scripts/bump-version.mjs <X.Y.Z>`**: writes the version into
  every *committed* web/PWA surface (package.json, footer, manifest, SW cache)
  and promotes the CHANGELOG `Unreleased` section to a dated release heading.
- **Build time - `scripts/stamp-app-version.sh`**: in CI, derives the version
  from the tag and stamps the *generated* native projects (Android
  `build.gradle`, iOS `Info.plist`). Those native folders are generated per
  build (not committed), so they MUST be stamped in CI or they reset to the
  Capacitor template defaults (`versionCode 1` / `versionName "1.0"`).

## Release flow
1. `node scripts/bump-version.mjs 0.2.2`
2. Fill in the CHANGELOG entry under the new heading.
3. `git commit -am "chore: v0.2.2"` -> open PR -> merge (per phased-delivery).
4. `git tag v0.2.2 && git push --follow-tags` (or, APK-only, `apk-v0.2.2`).
5. CI: version guard passes -> native artifacts stamped -> APK/IPA built ->
   GitHub Release published with auto-generated notes.

## CI enforcement (build workflow)
- A **version guard** step fails the build if the tag != `package.json` version.
- A **stamp** step runs `scripts/stamp-app-version.sh` after `cap add`/`cap sync`
  and before the native build.
- The release step sets `generate_release_notes: true`.

> Workflow files under `.github/workflows/` are pasted via the GitHub web editor
> when the API token lacks the `workflow` scope. A ready-to-paste copy lives in
> `deploy/github-actions/`.

## Adopting in a new repo
1. Copy `scripts/bump-version.mjs`, `scripts/stamp-app-version.sh`,
   `CHANGELOG.md`, and this file.
2. Point the bump script's web/PWA selectors at the repo's actual paths (footer
   marker, manifest, SW cache constant).
3. Add the guard + stamp steps to the build workflow; enable auto release notes.
4. Set `package.json` `"version"` (or `VERSION`), tag `v<X.Y.Z>`, done.

_Phased-delivery applies: branch + PR, never direct-to-main, no Docker._