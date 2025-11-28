#!/bin/bash
set -e

# Step 2: Create .app bundle structure
source "$(dirname "${BASH_SOURCE[0]}")/../utils/utils.sh"

step "Step 2: Creating .app bundle structure..."

# Create release directory
mkdir -p "$RELEASE_DIR"

# Remove old app if it exists
rm -rf "$APP_DIR"

# Create app bundle structure
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "  Created app directories"

# Copy the executable
require_file "$BUILD_DIR/$APP_NAME" "Executable"
cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
success "Copied executable"
echo ""
