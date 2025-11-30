#!/bin/bash
set -e

# Download HyperspaceInstaller executables from GitHub release
# Usage: ./download-executables.sh [version] [output-dir]
# Example: ./download-executables.sh 1.0.5 ./release

VERSION="${1:-.}"
OUTPUT_DIR="${2:-./release}"

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "$SCRIPTS_DIR/utils/utils.sh"
source "$SCRIPTS_DIR/utils/github-utils.sh"

if [ "$VERSION" = "." ]; then
    # If no version provided, read from VERSION file
    read_version
else
    export VERSION="$VERSION"
fi

info "Downloading HyperspaceInstaller executables version $VERSION"
echo ""

# Download executables from release
step "Downloading HyperspaceInstaller-$VERSION-executables.tar.gz..."
download_and_extract "freed-al/hyperspace-installer-mac" "v$VERSION" "*-executables.tar.gz" "$OUTPUT_DIR"
echo ""

# Verify executables exist
step "Verifying executables..."
require_file "$OUTPUT_DIR/x86_64/HyperspaceInstaller" "x86_64 executable"
require_file "$OUTPUT_DIR/arm64/HyperspaceInstaller" "arm64 executable"
success "All executables verified"

