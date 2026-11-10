#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
POSTERMAKER_CONFIGURATION=release POSTERMAKER_UNIVERSAL=1 ./script/build_and_run.sh --build-only

# Package outside iCloud/File Provider folders, which can add Finder metadata
# back to app bundles after signing. The archive contains no extended attributes.
STAGING_DIR="$(mktemp -d /private/tmp/PosterMaker-package.XXXXXX)"
trap 'rm -rf "$STAGING_DIR"' EXIT
ditto --norsrc --noextattr dist/PosterMaker.app "$STAGING_DIR/PosterMaker.app"
codesign --force --deep --sign - "$STAGING_DIR/PosterMaker.app"
codesign --verify --deep --strict "$STAGING_DIR/PosterMaker.app"
ditto --norsrc --noextattr -c -k --keepParent "$STAGING_DIR/PosterMaker.app" dist/PosterMaker-1.1.0-universal.zip
shasum -a 256 dist/PosterMaker-1.1.0-universal.zip > dist/PosterMaker-1.1.0-universal.zip.sha256
echo "Created dist/PosterMaker-1.1.0-universal.zip"
