#!/bin/bash
set -e

# Step 1: Build Swift release binary
source "$(dirname "${BASH_SOURCE[0]}")/../../utils/utils.sh"

step "Step 1: Building Swift release binary for $ARCH..."

# Generate Version.swift with the version from VERSION file
VERSION_FILE="$REPO_ROOT/VERSION"
if [ ! -f "$VERSION_FILE" ]; then
    error "VERSION file not found at $VERSION_FILE"
fi
VERSION=$(cat "$VERSION_FILE" | tr -d '\n' | xargs)

VERSION_SWIFT="$REPO_ROOT/Sources/HyperspaceInstaller/Helpers/Version.swift"
cat > "$VERSION_SWIFT" <<EOF
// Generated at build time - DO NOT EDIT
public struct InstallerVersion {
    public static let version = "$VERSION"
}
EOF

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
