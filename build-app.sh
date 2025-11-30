#!/bin/bash
set -e

# Build Hyperspace Installer for the current architecture
# Usage: ./build-app.sh [architecture]
# Example: ./build-app.sh arm64

ARCH="${1:-arm64}"
REPO_ROOT="$(dirname "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Download deps
"$SCRIPTS_DIR/downloads/download-deps.sh"

# Build executable
"$SCRIPTS_DIR/build/build-executable.sh" "$ARCH"

# Build installer with basemod
"$SCRIPTS_DIR/build/build-installer.sh" \
  --executable "$REPO_ROOT/release/$ARCH/HyperspaceInstaller" \
  --mod-files "$REPO_ROOT/external/Hyperspace.ftl" \
  --icon-path "$REPO_ROOT/HSInstaller.icns" \
  --installer-name "Hyperspace Installer" \
  --output-dir "$REPO_ROOT/release/$ARCH" \
  --arch "$ARCH"
