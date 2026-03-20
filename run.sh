#!/bin/bash
# Build and run SAML2AWSCountdown as a macOS app bundle
set -e

swift build

APP_NAME="SAML2AWSCountdown"
BUILD_DIR=".build/debug"
BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

# Create app bundle structure
RESOURCES_DIR="$CONTENTS_DIR/Resources"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# Copy icon if available
ICON_PLIST_ENTRY=""
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    ICON_PLIST_ENTRY="    <key>CFBundleIconFile</key>
    <string>AppIcon</string>"
fi

# Create Info.plist for the bundle
cat > "$CONTENTS_DIR/Info.plist" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SAML2AWSCountdown</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.SAML2AWSCountdown</string>
    <key>CFBundleName</key>
    <string>SAML2AWSCountdown</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
$ICON_PLIST_ENTRY
</dict>
</plist>
PLISTEOF

echo "App bundle created at: $BUNDLE_DIR"
echo "Running..."
open "$BUNDLE_DIR"
