#!/bin/bash

# Valerio Common Environment Variables
# This script is sourced by other scripts to ensure consistent paths and settings.

# The name of the Distrobox container
export VALERIO_CONTAINER_NAME="valerio-env"

# XDG-compliant directories for persistent data and cache
export VALERIO_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/valerio"
export VALERIO_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/valerio"

# Wine Prefix location
export VALERIO_PREFIX_DIR="$VALERIO_DATA_DIR/prefix"

# Wine Build location
export VALERIO_BUILD_DIR="$VALERIO_CACHE_DIR/wine-build"

# Installer locations
# If we are running from the repo, we can find the installers directory there.
# Otherwise, we might want a standard location like ~/Downloads/valerio-installers
VALERIO_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export VALERIO_INSTALLERS_DIR="$VALERIO_REPO_DIR/installers"

# Wine binary paths (usually inside /opt/wine-custom in the container)
export WINE_CUSTOM_PATH="/opt/wine-custom"
export WINE_CUSTOM_BIN="$WINE_CUSTOM_PATH/bin"

# Ensure directories exist
# Note: We don't create the prefix here, as that's handled by wineboot.
# But we ensure the base data and cache dirs exist.
mkdir -p "$VALERIO_DATA_DIR"
mkdir -p "$VALERIO_CACHE_DIR"
mkdir -p "$VALERIO_INSTALLERS_DIR"
