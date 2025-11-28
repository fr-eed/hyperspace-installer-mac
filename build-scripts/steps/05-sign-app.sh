#!/bin/bash
set -e

# Step 5: Sign the app
source "$(dirname "${BASH_SOURCE[0]}")/../utils/utils.sh"

step "Step 5: Signing the app..."

# Ad-hoc codesign the app
codesign -f -s - --timestamp=none "$APP_DIR"
success "Codesigned app"
echo ""
