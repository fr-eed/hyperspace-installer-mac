#!/bin/bash
set -e

# Build apps for all supported platforms

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPTS_DIR/utils/utils.sh"

info "Building for All Platforms"
echo ""

read_version
echo "Version: $VERSION"
echo ""

# Build x86_64
step "Building for Intel x86_64..."
"$SCRIPTS_DIR/platforms/x86_64.sh"
echo ""

# Build arm64
step "Building for Apple Silicon arm64..."
"$SCRIPTS_DIR/platforms/arm64.sh"
echo ""

# Summary
echo -e "${GREEN}=== All Builds Complete ===${NC}"
echo ""
echo "Output:"
echo "  x86_64 Build:"
echo "    App: $REPO_ROOT/release/x86_64/HyperspaceInstaller.app"
echo "    DMG: $REPO_ROOT/release/x86_64/HyperspaceInstaller-$VERSION.dmg"
echo ""
echo "  arm64 Build:"
echo "    App: $REPO_ROOT/release/arm64/HyperspaceInstaller.app"
echo "    DMG: $REPO_ROOT/release/arm64/HyperspaceInstaller-$VERSION.dmg"
echo ""
