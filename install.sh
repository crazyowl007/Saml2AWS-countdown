#!/bin/bash
# Build and install SAML2AWSCountdown to /Applications
set -e

echo "Building..."
swift build -c release

APP_NAME="SAML2AWSCountdown"
BUILD_DIR=".build/release"
BUNDLE_DIR="/Applications/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

# Remove old installation
rm -rf "$BUNDLE_DIR"

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

# Create Info.plist
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

echo "Installed to /Applications/$APP_NAME.app"
echo "You can now launch it from Spotlight (Cmd+Space -> SAML2AWSCountdown)"
open "$BUNDLE_DIR"
