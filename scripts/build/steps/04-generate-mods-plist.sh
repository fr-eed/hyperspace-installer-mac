#!/bin/bash
set -e

# Step 4: Generate mods.plist
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 4: Generating mods.plist..."

# Generate internal mods.plist with the list of mod files
if [ ${#MODS_LIST[@]} -gt 0 ]; then
    MODS_PLIST="$APP_DIR/Contents/Resources/mods.plist"

    # Remove old plist if it exists
    rm -f "$MODS_PLIST"

    # Create plist with dict root and "mods" key containing array
    /usr/libexec/PlistBuddy -c "Add : dict" "$MODS_PLIST"
    /usr/libexec/PlistBuddy -c "Add :mods array" "$MODS_PLIST"

    # Add each mod filename to mods array
    for i in "${!MODS_LIST[@]}"; do
        /usr/libexec/PlistBuddy -c "Add :mods:$i string ${MODS_LIST[$i]}" "$MODS_PLIST"
    done

    success "Generated mods.plist with ${#MODS_LIST[@]} mod(s)"
else
    success "No mods to include"
fi

echo ""
