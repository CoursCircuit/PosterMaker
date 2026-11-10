#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="PosterMaker"
BUNDLE_ID="com.sylvainbovat.Postermaker"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
CONFIGURATION="${POSTERMAKER_CONFIGURATION:-debug}"
ARCH_FLAGS=(--arch "$(uname -m)")
if [ "${POSTERMAKER_UNIVERSAL:-0}" = "1" ]; then
  ARCH_FLAGS=(--arch arm64 --arch x86_64)
fi

case "$MODE" in
  run|--verify|--debug|--logs|--telemetry|--build-only) ;;
  *) echo "usage: $0 [run|--verify|--debug|--logs|--telemetry|--build-only]" >&2; exit 2 ;;
esac

if [ "$MODE" != "--build-only" ]; then
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
fi

# Keep compiler caches inside the project for restricted build environments.
mkdir -p "$ROOT_DIR/.build/ModuleCache"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/ModuleCache"
swift build --disable-sandbox -c "$CONFIGURATION" "${ARCH_FLAGS[@]}" --product "$APP_NAME" -Xcc -fmodules-cache-path="$ROOT_DIR/.build/ModuleCache"
BUILD_DIR="$(swift build --disable-sandbox -c "$CONFIGURATION" "${ARCH_FLAGS[@]}" --show-bin-path)"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME.new"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME.new"
mv -f "$APP_BUNDLE/Contents/MacOS/$APP_NAME.new" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
  cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_NAME</string>
<key>CFBundleDisplayName</key><string>$APP_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1.0</string>
<key>CFBundleVersion</key><string>3</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>CFBundleDevelopmentRegion</key><string>fr</string>
<key>CFBundleLocalizations</key><array><string>fr</string></array>
<key>NSHumanReadableCopyright</key><string>PosterMaker</string>
</dict></plist>
PLIST

# Finder metadata inherited from an older bundle must not enter its signature.
xattr -dr com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
xattr -dr com.apple.ResourceFork "$APP_BUNDLE" 2>/dev/null || true
codesign --force --deep --sign - "$APP_BUNDLE"

case "$MODE" in
  --build-only) echo "Built $APP_BUNDLE" ;;
  --debug) lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  --logs)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify)
    /usr/bin/open -n "$APP_BUNDLE"
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    echo "PosterMaker launched successfully."
    ;;
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
esac
