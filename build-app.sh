#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hyperspace Swift Installer Builder ===${NC}"
echo ""

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$REPO_ROOT/.build/release"
APP_NAME="HyperspaceInstaller"
APP_DIR="$REPO_ROOT/$APP_NAME.app"
EXTERNAL_DIR="$REPO_ROOT/external"

# Read version from VERSION file
if [ -f "$REPO_ROOT/VERSION" ]; then
    VERSION=$(cat "$REPO_ROOT/VERSION" | tr -d '\n' | xargs)
else
    echo -e "${RED}ERROR: VERSION file not found${NC}"
    exit 1
fi

echo "Version: $VERSION"
echo ""

echo -e "${BLUE}Step 1: Building Swift release binary...${NC}"
swift build -c release
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

echo -e "${BLUE}Step 2: Creating .app bundle structure...${NC}"
# Remove old app if it exists
rm -rf "$APP_DIR"

# Create app bundle structure
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "  Created app directories"

# Copy the executable
if [ -f "$BUILD_DIR/$APP_NAME" ]; then
    cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/"
    chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
    echo "  ✓ Copied executable"
else
    echo -e "${RED}ERROR: Executable not found at $BUILD_DIR/$APP_NAME${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 3: Bundling resources...${NC}"

# Copy ftlman and dylibs from external folder
if [ -f "$EXTERNAL_DIR/ftlman" ]; then
    cp "$EXTERNAL_DIR/ftlman" "$APP_DIR/Contents/Resources/"
    chmod +x "$APP_DIR/Contents/Resources/ftlman"
    echo "  ✓ Copied ftlman"
else
    echo -e "${RED}ERROR: ftlman not found in external folder${NC}"
    exit 1
fi

if [ -f "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.12.amd64.dylib" ]; then
    cp "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.12.amd64.dylib" "$APP_DIR/Contents/Resources/"
    echo "  ✓ Copied Hyperspace.1.6.12.amd64.dylib"
else
    echo -e "${RED}ERROR: Hyperspace.1.6.12.amd64.dylib not found${NC}"
    exit 1
fi

if [ -f "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.13.amd64.dylib" ]; then
    cp "$EXTERNAL_DIR/MacOS/Hyperspace.1.6.13.amd64.dylib" "$APP_DIR/Contents/Resources/"
    echo "  ✓ Copied Hyperspace.1.6.13.amd64.dylib"
else
    echo -e "${RED}ERROR: Hyperspace.1.6.13.amd64.dylib not found${NC}"
    exit 1
fi

if [ -f "$EXTERNAL_DIR/MacOS/Hyperspace.command" ]; then
    cp "$EXTERNAL_DIR/MacOS/Hyperspace.command" "$APP_DIR/Contents/Resources/"
    chmod +x "$APP_DIR/Contents/Resources/Hyperspace.command"
    echo "  ✓ Copied Hyperspace.command"
else
    echo -e "${RED}ERROR: Hyperspace.command not found${NC}"
    exit 1
fi

# Create mods directory and copy hyperspace.ftl
mkdir -p "$APP_DIR/Contents/Resources/mods"
if [ -f "$EXTERNAL_DIR/Hyperspace.ftl" ]; then
    cp "$EXTERNAL_DIR/Hyperspace.ftl" "$APP_DIR/Contents/Resources/mods/"
    echo "  ✓ Copied hyperspace.ftl"
else
    echo -e "${RED}ERROR: hyperspace.ftl not found${NC}"
    exit 1
fi

if [ -f "$REPO_ROOT/HSInstaller.icns" ]; then
    cp "$REPO_ROOT/HSInstaller.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
    echo "  ✓ Copied HSInstaller.icns as AppIcon.icns"
else
    echo -e "${RED}ERROR: HSInstaller.icns not found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 4: Creating Info.plist...${NC}"

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>HyperspaceInstaller</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.hyperspace.installer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Hyperspace Installer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "  ✓ Created Info.plist"

echo ""
echo -e "${BLUE}Step 5: Signing the app...${NC}"

# Ad-hoc codesign the app
codesign -f -s - --timestamp=none "$APP_DIR"
echo "  ✓ Codesigned app"

echo ""
echo -e "${BLUE}Step 6: Verifying app...${NC}"

# Verify the app structure
if [ -f "$APP_DIR/Contents/MacOS/$APP_NAME" ]; then
    echo "  ✓ Executable present"
else
    echo -e "${RED}ERROR: Executable not found in app bundle${NC}"
    exit 1
fi

if [ -f "$APP_DIR/Contents/Resources/ftlman" ]; then
    echo "  ✓ ftlman present"
else
    echo -e "${RED}ERROR: ftlman not found in app bundle${NC}"
    exit 1
fi

if [ -f "$APP_DIR/Contents/Info.plist" ]; then
    echo "  ✓ Info.plist present"
else
    echo -e "${RED}ERROR: Info.plist not found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 7: Creating DMG (optional)...${NC}"

DMG_NAME="HyperspaceInstaller-$VERSION.dmg"

# Remove old DMG if it exists
rm -f "$REPO_ROOT/$DMG_NAME"

# Create temporary directory for DMG
TEMP_DMG_DIR="/tmp/hyperspace_dmg"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# Copy app to temp directory
cp -r "$APP_DIR" "$TEMP_DMG_DIR/"

# Create DMG
hdiutil create -volname "Hyperspace Installer" \
    -srcfolder "$TEMP_DMG_DIR" \
    -ov -format UDZO \
    "$REPO_ROOT/$DMG_NAME"

# Clean up
rm -rf "$TEMP_DMG_DIR"

echo "  ✓ Created $DMG_NAME"

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""
echo "Output:"
echo "  App Bundle: $APP_DIR"
echo "  DMG: $REPO_ROOT/$DMG_NAME"
echo ""
echo "To run the installer:"
echo "  open \"$APP_DIR\""
echo ""
echo "To distribute:"
echo "  - Share the DMG file: $REPO_ROOT/$DMG_NAME"
echo ""
