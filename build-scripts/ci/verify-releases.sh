#!/bin/bash
set -e

# Verify built releases exist and are ready for upload

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
RELEASE_DIR="$REPO_ROOT/release"

echo "=== Verifying Releases ==="
echo ""

# Check x86_64
if [ ! -f "$RELEASE_DIR/x86_64"/*.dmg ]; then
    echo "ERROR: x86_64 DMG not found"
    exit 1
fi

# Check arm64
if [ ! -f "$RELEASE_DIR/arm64"/*.dmg ]; then
    echo "ERROR: arm64 DMG not found"
    exit 1
fi

X86_DMG=$(ls "$RELEASE_DIR/x86_64"/*.dmg | head -1)
ARM64_DMG=$(ls "$RELEASE_DIR/arm64"/*.dmg | head -1)

echo "✓ x86_64: $(basename "$X86_DMG")"
echo "✓ arm64: $(basename "$ARM64_DMG")"
echo ""
echo "Ready for release!"
