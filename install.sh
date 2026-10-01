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
# command line overrides reach every target, also the Uniscript package's resource bundle, which has no team of its own
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-$(awk '/DEVELOPMENT_TEAM:/ {print $2}' "$PROJECT_DIR/project.yml")}"

cd "$PROJECT_DIR"
xcodegen generate --quiet
# uniscript is followed on its main branch: drop both generated pins so every build resolves its latest commit
rm -f "$APP_NAME.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" "$BUILD_DIR/SourcePackages/workspace-state.json"
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release \
  -derivedDataPath "$BUILD_DIR" CODE_SIGN_IDENTITY="$SIGN_IDENTITY" DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" -quiet build

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"
# Xcode copies the Uniscript resource bundle into both the app and the appex and can re-sign a copy after the appex was
# sealed ("a sealed resource is missing or invalid"): reseal inside-out, keeping identifiers and entitlements
for bundle in "$BUILT_APP/Contents/PlugIns/MarkdownQuickLook.appex" "$BUILT_APP"; do
  codesign --force --sign "$SIGN_IDENTITY" --preserve-metadata=identifier,entitlements,flags "$bundle" 2>/dev/null
done
codesign --verify --deep --strict "$BUILT_APP"

osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALLED_APP"
ditto "$BUILT_APP" "$INSTALLED_APP"
touch "$INSTALLED_APP"  # ditto keeps the build timestamp; a fresh one makes the Dock/app switcher drop cached icons

"$LSREGISTER" -f -R -trusted "$INSTALLED_APP"
# xcodebuild registers the build copy too, and Launch Services may then start it as a second instance next to the installed one
"$LSREGISTER" -u "$BUILT_APP"
pluginkit -a "$INSTALLED_APP/Contents/PlugIns/MarkdownQuickLook.appex"
pluginkit -e use -i "$EXTENSION_ID"
qlmanage -r >/dev/null
qlmanage -r cache >/dev/null
echo "Installed $INSTALLED_APP"
pluginkit -m -v -i "$EXTENSION_ID"
