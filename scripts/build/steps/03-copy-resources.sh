#!/bin/bash
set -e

# Step 3: Bundle resources
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 3: Bundling resources..."

# Copy ftlman
require_file "$EXTERNAL_DIR/ftlman" "ftlman"
cp "$EXTERNAL_DIR/ftlman" "$APP_DIR/Contents/Resources/"
chmod +x "$APP_DIR/Contents/Resources/ftlman"
success "Copied ftlman"

# Copy dylibs
require_file "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.12.amd64.dylib" "Hyperspace.1.6.12.amd64.dylib"
cp "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.12.amd64.dylib" "$APP_DIR/Contents/Resources/"
success "Copied Hyperspace.1.6.12.amd64.dylib"

require_file "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.13.amd64.dylib" "Hyperspace.1.6.13.amd64.dylib"
cp "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.13.amd64.dylib" "$APP_DIR/Contents/Resources/"
success "Copied Hyperspace.1.6.13.amd64.dylib"

# Copy Hyperspace.command
require_file "$EXTERNAL_DIR/MacOS/Hyperspace.command" "Hyperspace.command"
cp "$EXTERNAL_DIR/MacOS/Hyperspace.command" "$APP_DIR/Contents/Resources/"
chmod +x "$APP_DIR/Contents/Resources/Hyperspace.command"
success "Copied Hyperspace.command"


# Copy custom mods from exact paths if provided
if [ -n "$MOD_FILES_PATHS" ]; then
    while IFS= read -r modpath; do
        [ -z "$modpath" ] && continue
        if [ -f "$modpath" ]; then
            cp "$modpath" "$APP_DIR/Contents/Resources/mods/"
            success "Copied mod: $(basename "$modpath")"
        fi
    done <<< "$MOD_FILES_PATHS"
fi

# Copy custom icon or default
if [ -n "$CUSTOM_ICON_PATH" ] && [ -f "$CUSTOM_ICON_PATH" ]; then
    cp "$CUSTOM_ICON_PATH" "$APP_DIR/Contents/Resources/AppIcon.icns"
    success "Copied custom icon"
else
    require_file "$REPO_ROOT/HSInstaller.icns" "HSInstaller.icns"
    cp "$REPO_ROOT/HSInstaller.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
    success "Copied default icon"
fi

echo ""
