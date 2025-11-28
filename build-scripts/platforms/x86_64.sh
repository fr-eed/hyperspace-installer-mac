#!/bin/bash
set -e

# Build Hyperspace Installer for Intel x86_64

"$(dirname "${BASH_SOURCE[0]}")/../app-builder.sh" "x86_64"
