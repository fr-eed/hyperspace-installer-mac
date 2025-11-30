#!/bin/bash
set -e

# Step 1: Build Swift release binary
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 1: Building Swift release binary for $ARCH..."

# Build with architecture flag (minimum macOS 13.0 for SwiftUI compatibility)
if [ "$ARCH" = "arm64" ]; then
    swift build -c release -Xswiftc -target -Xswiftc arm64-apple-macosx13.0
elif [ "$ARCH" = "x86_64" ]; then
    swift build -c release -Xswiftc -target -Xswiftc x86_64-apple-macosx13.0
else
    error "Unsupported architecture: $ARCH"
fi

success "Build complete for $ARCH"

# Copy executable to release directory
RELEASE_ARCH_DIR="$REPO_ROOT/release/$ARCH"
mkdir -p "$RELEASE_ARCH_DIR"
cp "$BUILD_DIR/$APP_NAME" "$RELEASE_ARCH_DIR/$APP_NAME"
chmod +x "$RELEASE_ARCH_DIR/$APP_NAME"
success "Copied executable to $RELEASE_ARCH_DIR"

echo ""
