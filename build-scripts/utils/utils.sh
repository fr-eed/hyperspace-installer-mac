#!/bin/bash

# Shared utilities for build scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables - set once at the start
export REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
export ARCH="${ARCH:-x86_64}"  # Default to x86_64 if not set
export BUILD_DIR="$REPO_ROOT/.build/release"
export APP_NAME="HyperspaceInstaller"
export RELEASE_DIR="$REPO_ROOT/release/$ARCH"
export APP_DIR="$RELEASE_DIR/$APP_NAME.app"
export EXTERNAL_DIR="$REPO_ROOT/external"

# Read version from VERSION file
read_version() {
    if [ -f "$REPO_ROOT/VERSION" ]; then
        VERSION=$(cat "$REPO_ROOT/VERSION" | tr -d '\n' | xargs)
        export VERSION
    else
        error "VERSION file not found"
    fi
}

# Print functions
info() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

step() {
    echo -e "${BLUE}$1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

# Verify file exists, exit if not
require_file() {
    local file=$1
    local description=$2
    if [ ! -f "$file" ]; then
        error "$description not found at $file"
    fi
}

# Verify directory exists, exit if not
require_dir() {
    local dir=$1
    local description=$2
    if [ ! -d "$dir" ]; then
        error "$description directory not found at $dir"
    fi
}
