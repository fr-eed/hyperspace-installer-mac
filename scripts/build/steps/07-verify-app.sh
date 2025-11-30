#!/bin/bash
set -e

# Step 7: Verify app
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 7: Verifying app..."

# Verify the app structure
[ -f "$INSTALLER_APP_DIR/Contents/MacOS/$EXECUTABLE_NAME" ] || error "Executable missing"
success "Executable present"

[ -f "$INSTALLER_APP_DIR/Contents/Resources/ftlman" ] || error "ftlman missing"
success "ftlman present"

[ -f "$INSTALLER_APP_DIR/Contents/Info.plist" ] || error "Info.plist missing"
success "Info.plist present"

echo ""
