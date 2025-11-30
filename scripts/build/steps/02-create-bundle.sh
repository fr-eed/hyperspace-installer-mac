#!/bin/bash
set -e

# Step 2: Create .app bundle structure
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 2: Creating .app bundle structure..."

# Create output directory
mkdir -p "$BUILD_OUTPUT_DIR"

# Remove old app if it exists
rm -rf "$INSTALLER_APP_DIR"

# Create app bundle structure
mkdir -p "$INSTALLER_APP_DIR/Contents/MacOS"
mkdir -p "$INSTALLER_APP_DIR/Contents/Resources/mods"

echo "  Created app directories"

# Copy the executable
cp "$EXECUTABLE_PATH" "$INSTALLER_APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
chmod +x "$INSTALLER_APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
success "Copied executable"
echo ""
