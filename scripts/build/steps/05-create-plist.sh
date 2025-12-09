#!/bin/bash
set -e

# Step 5: Create Info.plist
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

# Source actual downloaded versions
source "$EXTERNAL_DIR/.downloaded-versions"

step "Step 5: Creating Info.plist..."
echo "  Bundle Name: $INSTALLER_NAME"

cat > "$INSTALLER_APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.hyperspace.installer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$INSTALLER_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$INSTALLER_BUNDLE_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$INSTALLER_BUNDLE_VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>FTLManVersion</key>
    <string>${FTLMAN_VERSION:-unknown}</string>
    <key>HyperspaceVersion</key>
    <string>${HYPERSPACE_VERSION:-unknown}</string>
</dict>
</plist>
EOF

success "Created Info.plist"
echo ""
