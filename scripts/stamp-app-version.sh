#!/usr/bin/env bash
# stamp-app-version.sh - STANDARD app versioning (native build-time stamp).
#
# Derives the app version from the release tag (single source of truth) and
# stamps every native surface present in the checkout:
#   Android : android/app/build.gradle -> versionName=X.Y.Z, versionCode=M*10000+m*100+p
#   iOS     : ios/App/App/Info.plist    -> CFBundleShortVersionString=X.Y.Z, CFBundleVersion=code
#
# Web + PWA surfaces are stamped at AUTHOR time by scripts/bump-version.mjs.
# Run this in CI AFTER `npx cap add <platform>` / `cap sync`, BEFORE the platform build.
#
# Version resolution order: $1 arg > $STAMP_VERSION env > apk-v*/v* tag > package.json
# (or a top-level VERSION file for non-JS repos).
# See docs/VERSIONING.md for the full standard.
set -euo pipefail

raw="${1:-${STAMP_VERSION:-}}"
if [ -z "$raw" ] && [ "${GITHUB_REF_TYPE:-}" = "tag" ]; then
  raw="${GITHUB_REF_NAME:-}"
fi
is_tag=1
case "$raw" in
  apk-v*) raw="${raw#apk-v}" ;;
  v*)     raw="${raw#v}" ;;
  "")     
    if [ -f package.json ]; then
      raw="$(node -p "require('./package.json').version")"
    elif [ -f VERSION ]; then
      raw="$(tr -d '[:space:]' < VERSION)"
    else
      echo "stamp-app-version: no package.json or VERSION file to resolve version" >&2
      exit 1
    fi
    is_tag=0 ;;
esac

if ! printf '%s' "$raw" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "stamp-app-version: could not resolve a semver X.Y.Z (got '$raw')" >&2
  exit 1
fi

MAJOR="${raw%%.*}"; rest="${raw#*.}"; MINOR="${rest%%.*}"; PATCH="${rest#*.}"
if [ "$MINOR" -ge 100 ] || [ "$PATCH" -ge 100 ]; then
  echo "stamp-app-version: minor/patch must be < 100 for the versionCode scheme (got $raw)" >&2
  exit 1
fi
CODE=$(( MAJOR * 10000 + MINOR * 100 + PATCH ))
NAME="$raw"
[ "$is_tag" -eq 0 ] && NAME="${raw}-dev"

stamped=0

# --- Android ---
GRADLE="android/app/build.gradle"
if [ -f "$GRADLE" ]; then
  sed -i -E "s/versionCode[[:space:]]+[0-9]+/versionCode ${CODE}/" "$GRADLE"
  sed -i -E "s/versionName[[:space:]]+\"[^\"]*\"/versionName \"${NAME}\"/" "$GRADLE"
  echo "android: versionName=${NAME} versionCode=${CODE}"
  grep -E "versionCode|versionName" "$GRADLE" || true
  stamped=1
fi

# --- iOS ---
PLIST="ios/App/App/Info.plist"
if [ -f "$PLIST" ]; then
  if [ -x /usr/libexec/PlistBuddy ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${raw}" "$PLIST" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string ${raw}" "$PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${CODE}" "$PLIST" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string ${CODE}" "$PLIST"
  else
    # Portable fallback (Linux CI): replace the <string> value following each key.
    perl -0pi -e "s/(<key>CFBundleShortVersionString<\/key>\s*<string>)[^<]*(<\/string>)/\${1}${raw}\${2}/s" "$PLIST"
    perl -0pi -e "s/(<key>CFBundleVersion<\/key>\s*<string>)[^<]*(<\/string>)/\${1}${CODE}\${2}/s" "$PLIST"
  fi
  echo "ios: CFBundleShortVersionString=${raw} CFBundleVersion=${CODE}"
  stamped=1
fi

if [ "$stamped" -eq 0 ]; then
  echo "stamp-app-version: no native project found (android/ or ios/) - nothing to stamp" >&2
fi