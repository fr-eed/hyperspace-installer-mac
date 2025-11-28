#!/bin/bash

# GitHub API utilities for downloading releases
# Low-level functions that accept tag/version as arguments

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Get release info by tag
# Usage: get_release_info "owner/repo" "tag_or_latest"
# Returns: JSON response from GitHub API
get_release_info() {
    local repo=$1
    local tag=$2

    if [ "$tag" = "latest" ]; then
        curl -s "https://api.github.com/repos/$repo/releases/latest"
    else
        curl -s "https://api.github.com/repos/$repo/releases/tags/$tag"
    fi
}

# Download a release asset by file name pattern
# Usage: download_release_asset "owner/repo" "tag_or_latest" "filename_pattern" "destination"
download_release_asset() {
    local repo=$1
    local tag=$2
    local filename_pattern=$3
    local destination=$4

    local release_info=$(get_release_info "$repo" "$tag")

    # Check for API errors
    if echo "$release_info" | grep -q "\"message\""; then
        local message=$(echo "$release_info" | grep -o '"message":"[^"]*' | cut -d'"' -f4)
        error "GitHub API error for $repo@$tag: $message"
    fi

    # Extract download URL for the matching asset
    # Search for assets where the name contains the pattern
    local download_url=$(echo "$release_info" | grep -F "$filename_pattern" | grep "browser_download_url" | head -1 | grep -o 'https://[^"]*')

    if [ -z "$download_url" ]; then
        error "Asset matching '$filename_pattern' not found in $repo@$tag"
    fi

    # Create destination directory if needed
    mkdir -p "$(dirname "$destination")"

    # Download the file
    if ! curl -sL -o "$destination" "$download_url"; then
        error "Failed to download from $download_url"
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
