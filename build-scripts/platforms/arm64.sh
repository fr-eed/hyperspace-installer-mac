#!/bin/bash
set -e

# Build Hyperspace Installer for Apple Silicon arm64

"$(dirname "${BASH_SOURCE[0]}")/../app-builder.sh" "arm64"
