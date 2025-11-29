#!/bin/bash
set -e

# Main app builder orchestrator
# Usage: app-builder.sh <architecture>
# Example: app-builder.sh x86_64

if [ -z "$1" ]; then
    echo "Usage: $0 <architecture>"
    echo "Example: $0 x86_64"
    echo "Supported: x86_64, arm64"
    exit 1
fi

export ARCH="$1"

source "$(dirname "${BASH_SOURCE[0]}")/utils/utils.sh"

# Display header
info "Hyperspace Swift Installer Builder - $ARCH"
echo ""

# Read version
read_version
echo "Version: $VERSION"
echo "Architecture: $ARCH"
echo ""

# Run all build scripts in sequence
"$(dirname "${BASH_SOURCE[0]}")/steps/01-build-swift.sh"
"$(dirname "${BASH_SOURCE[0]}")/steps/02-create-bundle.sh"
"$(dirname "${BASH_SOURCE[0]}")/steps/03-copy-resources.sh"
"$(dirname "${BASH_SOURCE[0]}")/steps/04-create-plist.sh"
"$(dirname "${BASH_SOURCE[0]}")/steps/05-sign-app.sh"
"$(dirname "${BASH_SOURCE[0]}")/steps/06-verify-app.sh"
"$(dirname "${BASH_SOURCE[0]}")/steps/07-create-dmg.sh"

# Display completion message
echo -e "${GREEN}=== Build Complete ($ARCH) ===${NC}"
echo ""
echo "Output:"
echo "  App Bundle: $APP_DIR"
echo "  DMG: $RELEASE_DIR/HyperspaceInstaller-$VERSION-$ARCH.dmg"
echo ""
echo "To run the installer:"
echo "  open \"$APP_DIR\""
echo ""
echo "To distribute:"
echo "  - Share the DMG file: $RELEASE_DIR/HyperspaceInstaller-$VERSION.dmg"
echo ""
