#!/bin/bash
set -e

# Step 3: Bundle resources
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 3: Bundling resources..."

# Copy ftlman
cp "$EXTERNAL_DIR/ftlman" "$INSTALLER_APP_DIR/Contents/Resources/"
chmod +x "$INSTALLER_APP_DIR/Contents/Resources/ftlman"
success "Copied ftlman"

# Copy dylibs
cp "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.12.amd64.dylib" "$INSTALLER_APP_DIR/Contents/Resources/"
success "Copied Hyperspace.1.6.12.amd64.dylib"

cp "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.13.amd64.dylib" "$INSTALLER_APP_DIR/Contents/Resources/"
success "Copied Hyperspace.1.6.13.amd64.dylib"

# Copy Hyperspace.command
cp "$EXTERNAL_DIR/MacOS/Hyperspace.command" "$INSTALLER_APP_DIR/Contents/Resources/"
chmod +x "$INSTALLER_APP_DIR/Contents/Resources/Hyperspace.command"
success "Copied Hyperspace.command"

# Copy custom mods from exact paths if provided
if [ -n "$INSTALLER_MOD_FILES" ]; then
    for modpath in $INSTALLER_MOD_FILES; do
        if [ -f "$modpath" ]; then
            cp "$modpath" "$INSTALLER_APP_DIR/Contents/Resources/mods/"
            success "Copied mod: $(basename "$modpath")"
        fi
    done
fi

# Copy custom icon or default
if [ -n "$INSTALLER_ICON_PATH" ] && [ -f "$INSTALLER_ICON_PATH" ]; then
    cp "$INSTALLER_ICON_PATH" "$INSTALLER_APP_DIR/Contents/Resources/AppIcon.icns"
    success "Copied custom icon"
else
    cp "$REPO_ROOT/HSInstaller.icns" "$INSTALLER_APP_DIR/Contents/Resources/AppIcon.icns"
    success "Copied default icon"
fi

echo ""
