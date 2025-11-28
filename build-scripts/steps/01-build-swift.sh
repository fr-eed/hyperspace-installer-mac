#!/bin/bash
set -e

# Step 1: Build Swift release binary
source "$(dirname "${BASH_SOURCE[0]}")/../utils/utils.sh"

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
echo ""
