#!/bin/bash
# Build MarkdownPreview.app (+ embedded Quick Look extension), install to ~/Applications and register it.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MarkdownPreview"
EXTENSION_ID="com.pannous.MarkdownPreview.QuickLook"
INSTALL_DIR="$HOME/Applications"
BUILD_DIR="$PROJECT_DIR/build"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
SIGN_IDENTITY="${SIGN_IDENTITY:-Apple Development}"

cd "$PROJECT_DIR"
xcodegen generate --quiet
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release \
  -derivedDataPath "$BUILD_DIR" CODE_SIGN_IDENTITY="$SIGN_IDENTITY" -quiet build

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"
codesign --verify --deep --strict "$BUILT_APP"

osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALLED_APP"
ditto "$BUILT_APP" "$INSTALLED_APP"

"$LSREGISTER" -f -R -trusted "$INSTALLED_APP"
pluginkit -a "$INSTALLED_APP/Contents/PlugIns/MarkdownQuickLook.appex"
pluginkit -e use -i "$EXTENSION_ID"
qlmanage -r >/dev/null
qlmanage -r cache >/dev/null
echo "Installed $INSTALLED_APP"
pluginkit -m -v -i "$EXTENSION_ID"
