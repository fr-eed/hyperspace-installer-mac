#!/bin/bash
set -e

# Hardcoded versions
FTLMAN_VERSION="v0.6.6"
HYPERSPACE_VERSION="v1.20.2"

# Download dependencies from GitHub releases
# This is a standalone script with hardcoded dependency versions

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$SCRIPTS_DIR/utils/utils.sh"
source "$SCRIPTS_DIR/utils/github-utils.sh"



# Display header
info "Downloading Dependencies"
echo ""
echo "Dependency versions:"
echo "  ftlman: $FTLMAN_VERSION"
echo "  FTL-Hyperspace: $HYPERSPACE_VERSION"
echo ""

# Create external directory
mkdir -p "$EXTERNAL_DIR"

# Download ftlman (Intel x86_64)
step "Downloading ftlman-x86_64@$FTLMAN_VERSION..."
download_and_extract "afishhh/ftlman" "$FTLMAN_VERSION" "ftlman-x86_64-apple-darwin.tar.gz" "$EXTERNAL_DIR"
# Move ftlman from subdirectory to external root if needed
if [ -f "$EXTERNAL_DIR/ftlman/ftlman" ]; then
    mv "$EXTERNAL_DIR/ftlman/ftlman" "$EXTERNAL_DIR/ftlman-bin"
    rm -rf "$EXTERNAL_DIR/ftlman"
    mv "$EXTERNAL_DIR/ftlman-bin" "$EXTERNAL_DIR/ftlman"
fi
chmod +x "$EXTERNAL_DIR/ftlman"
echo ""

# Download FTL-Hyperspace (MacOS build)
step "Downloading FTL-Hyperspace@$HYPERSPACE_VERSION..."
download_and_extract "fr-eed/FTL-Hyperspace-Dino" "$HYPERSPACE_VERSION" "*-MacOS.zip" "$EXTERNAL_DIR"
echo ""

# Verify downloads
step "Verifying downloaded files..."
require_file "$EXTERNAL_DIR/ftlman" "ftlman"
success "ftlman verified"

# Check for Hyperspace files
if ls "$EXTERNAL_DIR"/Hyperspace* &> /dev/null; then
    success "Hyperspace files verified"
else
    echo "  Note: Checking for Hyperspace files..."
    ls -la "$EXTERNAL_DIR" | grep -i hyperspace || true
fi

echo ""
echo -e "${GREEN}=== Dependencies Downloaded Successfully ===${NC}"
echo ""
