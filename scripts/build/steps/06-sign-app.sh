#!/bin/bash
set -e

# Step 6: Sign the app
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 6: Signing the app..."

# Ad-hoc codesign the app
codesign -f -s - --timestamp=none "$INSTALLER_APP_DIR"
success "Codesigned app"
echo ""
