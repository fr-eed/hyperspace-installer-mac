#!/bin/bash
set -e

# Build Swift executables for all supported platforms

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPTS_DIR/../utils/utils.sh"

info "Building Executables For All Platforms"
echo ""

read_version
echo "Version: $VERSION"
echo ""

# Build x86_64
step "Building for Intel x86_64..."
"$SCRIPTS_DIR/build-executable.sh" "x86_64"
echo ""

# Build arm64
step "Building for Apple Silicon arm64..."
"$SCRIPTS_DIR/build-executable.sh" "arm64"
echo ""

# Summary
echo -e "${GREEN}=== All Executable Builds Complete ===${NC}"
echo ""
echo "Output:"
echo "  x86_64: $REPO_ROOT/release/x86_64/HyperspaceInstaller"
echo "  arm64:  $REPO_ROOT/release/arm64/HyperspaceInstaller"
echo ""
