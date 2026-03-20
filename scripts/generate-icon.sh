#!/bin/bash
# Generate AppIcon.icns from a 1024x1024 source PNG
# Usage: ./scripts/generate-icon.sh [path/to/icon-1024.png]
set -e

SOURCE="${1:-Resources/AppIcon.png}"
ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
OUTPUT="Resources/AppIcon.icns"

if [ ! -f "$SOURCE" ]; then
    echo "Error: Source image not found: $SOURCE"
    echo "Usage: $0 [path/to/1024x1024.png]"
    exit 1
fi

# Verify dimensions
WIDTH=$(sips -g pixelWidth "$SOURCE" | tail -1 | awk '{print $2}')
HEIGHT=$(sips -g pixelHeight "$SOURCE" | tail -1 | awk '{print $2}')
if [ "$WIDTH" -ne 1024 ] || [ "$HEIGHT" -ne 1024 ]; then
    echo "Warning: Source image is ${WIDTH}x${HEIGHT}, expected 1024x1024"
fi

mkdir -p "$ICONSET_DIR"
mkdir -p "$(dirname "$OUTPUT")"

# Generate all required icon sizes
declare -a SIZES=(
    "icon_16x16:16"
    "icon_16x16@2x:32"
    "icon_32x32:32"
    "icon_32x32@2x:64"
    "icon_128x128:128"
    "icon_128x128@2x:256"
    "icon_256x256:256"
    "icon_256x256@2x:512"
    "icon_512x512:512"
    "icon_512x512@2x:1024"
)

for entry in "${SIZES[@]}"; do
    NAME="${entry%%:*}"
    SIZE="${entry##*:}"
    sips -z "$SIZE" "$SIZE" "$SOURCE" --out "$ICONSET_DIR/${NAME}.png" > /dev/null 2>&1
done

# Convert iconset to icns
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT"
rm -rf "$(dirname "$ICONSET_DIR")"

echo "Generated $OUTPUT"
