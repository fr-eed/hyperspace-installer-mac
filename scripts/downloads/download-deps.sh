#!/bin/bash
set -e

# Source dependency versions from root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/.deps-versions"

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

# Flatten directory structure if needed
if [ -d "$EXTERNAL_DIR/ftlman" ] && [ -f "$EXTERNAL_DIR/ftlman/ftlman" ]; then
    mv "$EXTERNAL_DIR/ftlman/ftlman" "$EXTERNAL_DIR/ftlman.tmp"
    rm -rf "$EXTERNAL_DIR/ftlman"
    mv "$EXTERNAL_DIR/ftlman.tmp" "$EXTERNAL_DIR/ftlman"
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
