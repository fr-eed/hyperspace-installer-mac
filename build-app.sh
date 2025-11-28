#!/bin/bash
set -e

# Build Hyperspace Installer for Apple arm64 (default)
# For other architectures, use: build-scripts/platforms/<arch>.sh
# For all architectures, use: build-scripts/build-all.sh

"$(dirname "${BASH_SOURCE[0]}")/build-scripts/platforms/arm64.sh"
