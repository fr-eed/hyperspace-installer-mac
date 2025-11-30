#!/bin/bash
set -e

# Build installer package from pre-compiled executable
# Calls steps 02-07 to package executable with mods/config/icon
#
# Usage:
#   build-installer.sh \
#     --executable /path/to/HyperspaceInstaller \
#     --mod-files 'mods/*.ftl' \
#     --config-path installer-config.json \
#     --icon-path icon.icns \
#     --installer-name "My Installer"

SCRIPTS_DIR="$(dirname "${BASH_SOURCE[0]}")"
REPO_ROOT="$(dirname "$(dirname "$SCRIPTS_DIR")")"

# Source utils first so error function is available
source "$SCRIPTS_DIR/../utils/utils.sh"

# Parse arguments
EXECUTABLE=""
MOD_FILES=""
ICON_PATH=""
INSTALLER_NAME="Hyperspace"
OUTPUT_DIR="."
ARCH_NAME="universal"
INSTALLER_BUNDLE_VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --executable) EXECUTABLE="$2"; shift 2 ;;
        --mod-files) MOD_FILES="$2"; shift 2 ;;
        --icon-path) ICON_PATH="$2"; shift 2 ;;
        --installer-name) INSTALLER_NAME="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --arch) ARCH_NAME="$2"; shift 2 ;;
        --installer-bundle-version) INSTALLER_BUNDLE_VERSION="$2"; shift 2 ;;
        *) error "Unknown option: $1" ;;
    esac
done

# Validate required parameters
[ -z "$EXECUTABLE" ] && error "Missing --executable parameter"
[ -z "$MOD_FILES" ] && error "Missing --mod-files parameter"
[ ! -f "$EXECUTABLE" ] && error "Executable not found: $EXECUTABLE"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Get installer bundle version from parameter or use date
[ -z "$INSTALLER_BUNDLE_VERSION" ] && INSTALLER_BUNDLE_VERSION=$(date +%Y.%m.%d)

# ============================================================
# EXPORTS - All variables passed to step scripts
# ============================================================
export REPO_ROOT="$REPO_ROOT"
export EXTERNAL_DIR="$REPO_ROOT/external"
export EXECUTABLE_PATH="$EXECUTABLE"
export EXECUTABLE_NAME="HyperspaceInstaller"
export BUILD_OUTPUT_DIR="$OUTPUT_DIR"
export INSTALLER_BUNDLE_VERSION="$INSTALLER_BUNDLE_VERSION"
export BUILD_ARCH="$ARCH_NAME"
export INSTALLER_APP_DIR="$OUTPUT_DIR/$INSTALLER_NAME.app"
export INSTALLER_BUNDLE_NAME="$INSTALLER_NAME"
export INSTALLER_NAME="$INSTALLER_NAME"
export INSTALLER_MOD_FILES="$MOD_FILES"
export INSTALLER_ICON_PATH="$ICON_PATH"
# ============================================================

# Validate mod files exist
for modpath in $MOD_FILES; do
    if [ ! -f "$modpath" ]; then
        error "Mod file not found: $modpath"
    fi
done

# Display header
info "Building Installer Package"
echo ""
echo "Configuration:"
echo "  Executable: $EXECUTABLE"
echo "  Installer Name: $INSTALLER_NAME"
echo "  Mod Files: $MOD_FILES"
[ -n "$ICON_PATH" ] && echo "  Icon: $ICON_PATH"
echo "  Output: $OUTPUT_DIR"
echo ""

# Call step scripts
"$SCRIPTS_DIR/steps/02-create-bundle.sh"
"$SCRIPTS_DIR/steps/03-copy-resources.sh"
"$SCRIPTS_DIR/steps/04-generate-mods-plist.sh"
"$SCRIPTS_DIR/steps/05-create-plist.sh"
"$SCRIPTS_DIR/steps/06-sign-app.sh"
"$SCRIPTS_DIR/steps/07-verify-app.sh"
"$SCRIPTS_DIR/steps/08-create-dmg.sh"

# Display completion
echo -e "${GREEN}=== Installer Build Complete ===${NC}"
echo ""
echo "Output:"
echo "  App Bundle: $INSTALLER_APP_DIR"
echo "  DMG: $BUILD_OUTPUT_DIR/$INSTALLER_NAME-$INSTALLER_BUNDLE_VERSION-$BUILD_ARCH.dmg"
echo ""
