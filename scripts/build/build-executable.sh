#!/bin/bash
set -e

# Build Swift executable for a specific architecture
# Usage: build-executable.sh <architecture>
# Example: build-executable.sh x86_64

if [ -z "$1" ]; then
    echo "Usage: $0 <architecture>"
    echo "Example: $0 x86_64"
    echo "Supported: x86_64, arm64"
    exit 1
fi

export ARCH="$1"

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"
REPO_ROOT="$(cd "$SCRIPTS_DIR/../../" && pwd)"

# Set paths explicitly for this architecture
export RELEASE_DIR="$REPO_ROOT/release/$ARCH"
export APP_DIR="$RELEASE_DIR/HyperspaceInstaller.app"

source "$SCRIPTS_DIR/../utils/utils.sh"

# Display header
info "Building Swift Executable - $ARCH"
echo ""

# Read version
read_version
echo "Version: $VERSION"
echo "Architecture: $ARCH"
echo ""

# Run build step only
"$SCRIPTS_DIR/steps/01-build-swift.sh"

# Display completion
echo -e "${GREEN}=== Executable Build Complete ($ARCH) ===${NC}"
echo ""
echo "Output:"
echo "  Executable: $REPO_ROOT/release/$ARCH/$APP_NAME"
echo ""
