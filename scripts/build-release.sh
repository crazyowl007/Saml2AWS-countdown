#!/bin/bash
# Build a release .app bundle and DMG for distribution
set -e

APP_NAME="SAML2AWSCountdown"
VERSION="${1:-1.0.0}"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DMG_NAME="$APP_NAME-$VERSION.dmg"

echo "==> Building Universal Binary (arm64 + x86_64)..."
swift build -c release --arch arm64 --arch x86_64

echo "==> Creating app bundle..."
rm -rf "$DIST_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy binary
cp ".build/apple/Products/Release/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# Copy icon if available
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    ICON_ENTRY="    <key>CFBundleIconFile</key>
    <string>AppIcon</string>"
else
    ICON_ENTRY=""
    echo "Warning: Resources/AppIcon.icns not found, building without icon"
fi

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
$ICON_ENTRY
</dict>
</plist>
PLISTEOF

echo "==> Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Creating DMG..."
DMG_TEMP="$(mktemp -d)"
cp -R "$APP_BUNDLE" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DIST_DIR/$DMG_NAME"

rm -rf "$DMG_TEMP"

echo ""
echo "Build complete:"
echo "  App:  $APP_BUNDLE"
echo "  DMG:  $DIST_DIR/$DMG_NAME"
