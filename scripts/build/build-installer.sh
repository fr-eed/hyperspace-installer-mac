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

# Source utils first so error function is available
source "$SCRIPTS_DIR/../utils/utils.sh"

# Parse arguments
EXECUTABLE=""
MOD_FILES=""
ICON_PATH=""
INSTALLER_NAME="Hyperspace Installer"
OUTPUT_DIR="."
ARCH_NAME="universal"

while [[ $# -gt 0 ]]; do
    case $1 in
        --executable) EXECUTABLE="$2"; shift 2 ;;
        --mod-files) MOD_FILES="$2"; shift 2 ;;
        --icon-path) ICON_PATH="$2"; shift 2 ;;
        --installer-name) INSTALLER_NAME="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --arch) ARCH_NAME="$2"; shift 2 ;;
        *) error "Unknown option: $1" ;;
    esac
done

# Validate required parameters
[ -z "$EXECUTABLE" ] && error "Missing --executable parameter"
[ -z "$MOD_FILES" ] && error "Missing --mod-files parameter"
[ ! -f "$EXECUTABLE" ] && error "Executable not found: $EXECUTABLE"
[ ! -d "$OUTPUT_DIR" ] && error "Output directory not found: $OUTPUT_DIR"

# Set paths explicitly before sourcing utils
export RELEASE_DIR="$OUTPUT_DIR"
export APP_DIR="$OUTPUT_DIR/HyperspaceInstaller.app"

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

# Get version from environment or use date
[ -z "$VERSION" ] && VERSION=$(date +%Y.%m.%d)
export VERSION

# Export executable source for step scripts
export EXECUTABLE_SOURCE="$EXECUTABLE"

# Build list of mod filenames from the exact paths provided
MODS_LIST=()
while IFS= read -r modpath; do
    [ -z "$modpath" ] && continue
    if [ -f "$modpath" ]; then
        MODS_LIST+=("$(basename "$modpath")")
    else
        error "Mod file not found: $modpath"
    fi
done <<< "$MOD_FILES"

# Export custom parameters for step scripts
export MOD_FILES_PATHS="$MOD_FILES"
export CUSTOM_ICON_PATH="$ICON_PATH"
export CUSTOM_INSTALLER_NAME="$INSTALLER_NAME"

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
echo "  App Bundle: $APP_DIR"
echo "  DMG: $RELEASE_DIR/HyperspaceInstaller-$VERSION-$ARCH_NAME.dmg"
echo ""
