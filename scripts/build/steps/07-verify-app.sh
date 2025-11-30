#!/bin/bash
set -e

# Step 7: Verify app
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 7: Verifying app..."

# Verify the app structure
require_file "$APP_DIR/Contents/MacOS/$APP_NAME" "Executable"
success "Executable present"

require_file "$APP_DIR/Contents/Resources/ftlman" "ftlman"
success "ftlman present"

require_file "$APP_DIR/Contents/Info.plist" "Info.plist"
success "Info.plist present"

echo ""
