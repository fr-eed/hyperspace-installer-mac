#!/bin/bash
set -e

# Step 7: Create DMG
source "$(dirname "${BASH_SOURCE[0]}")/../utils/utils.sh"

step "Step 7: Creating DMG..."

DMG_NAME="HyperspaceInstaller-$VERSION.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"

# Remove old DMG if it exists
rm -f "$DMG_PATH"

# Create temporary directory for DMG
TEMP_DMG_DIR="/tmp/hyperspace_dmg"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# Copy app to temp directory
cp -r "$APP_DIR" "$TEMP_DMG_DIR/"

# Create DMG
hdiutil create -volname "Hyperspace Installer" \
    -srcfolder "$TEMP_DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$TEMP_DMG_DIR"

success "Created $DMG_NAME"
echo ""
