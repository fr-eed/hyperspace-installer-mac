#!/bin/bash

# GitHub utilities for downloading releases using gh CLI
# Uses GitHub CLI (gh) which is pre-installed on GitHub Actions runners
# Automatically handles authentication via GITHUB_TOKEN

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Download a release asset by file name pattern
# Usage: download_release_asset "owner/repo" "tag_or_latest" "filename_pattern" "destination"
download_release_asset() {
    local repo=$1
    local tag=$2
    local filename_pattern=$3
    local destination=$4

    # Create destination directory if needed
    mkdir -p "$(dirname "$destination")"

    # Use gh release download with asset name pattern
    # gh automatically uses GITHUB_TOKEN for authentication
    if ! gh release download "$tag" \
        --repo "$repo" \
        --pattern "$filename_pattern" \
        --output "$destination" \
        --skip-existing; then
        error "Failed to download asset matching '$filename_pattern' from $repo@$tag"
    fi

    success "Downloaded to $destination"
}

# Download and extract release asset
# Usage: download_and_extract "owner/repo" "tag_or_latest" "filename_pattern" "destination_dir"
download_and_extract() {
    local repo=$1
    local tag=$2
    local filename_pattern=$3
    local destination_dir=$4

    mkdir -p "$destination_dir"

    # Determine file extension based on pattern
    local file_ext=""
    if [[ "$filename_pattern" == *.zip ]]; then
        file_ext=".zip"
    elif [[ "$filename_pattern" == *.tar.gz ]] || [[ "$filename_pattern" == *.tgz ]]; then
        file_ext=".tar.gz"
    fi

    local temp_file="/tmp/release_download_$$${file_ext}"

    download_release_asset "$repo" "$tag" "$filename_pattern" "$temp_file"

    # Check if it's an archive and extract if needed
    case "$temp_file" in
        *.zip)
            step "Extracting zip archive..."
            unzip -oq "$temp_file" -d "$destination_dir"
            success "Extracted to $destination_dir"
            ;;
        *.tar.gz|*.tgz)
            step "Extracting tar.gz archive..."
            tar -xzf "$temp_file" -C "$destination_dir"
            success "Extracted to $destination_dir"
            ;;
        *)
            # Single binary file - just copy it
            cp "$temp_file" "$destination_dir/"
            success "Copied to $destination_dir"
            ;;
    esac

    rm -f "$temp_file"
}
