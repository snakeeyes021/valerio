#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Array of directories to search. Order matters: it will stop at the first match.
SEARCH_DIRS=("$VALERIO_INSTALLERS_DIR" "$HOME/Downloads" "$(pwd)")
FOUND_INSTALLER=""

# 1. Search Phase
echo "Searching for Steinberg Download Assistant installer..."
for DIR in "${SEARCH_DIRS[@]}"; do
    if [ ! -d "$DIR" ]; then
        continue
    fi
    
    # Use a glob pattern to handle different version numbers in the filename
    MATCH=$(find "$DIR" -maxdepth 1 -name "Steinberg_Download_Assistant_*_Installer_win.exe" | head -n 1)
    
    if [ -n "$MATCH" ]; then
        FOUND_INSTALLER="$MATCH"
        echo "Found SDA installer: $FOUND_INSTALLER"
        break
    fi
done

# 2. Download / Fallback Phase
if [ -z "$FOUND_INSTALLER" ]; then
    echo "Error: Steinberg Download Assistant installer not found."
    echo "Please download the Windows installer from Steinberg's website and place it in:"
    echo "  - $VALERIO_INSTALLERS_DIR"
    echo "  - ~/Downloads"
    echo ""
    echo "Filename should match: Steinberg_Download_Assistant_*_Installer_win.exe"
    exit 1
fi

# 3. Execution Phase
# Passing the guaranteed absolute path ($FOUND_INSTALLER) to Wine inside the Distrobox container.
echo "Launching SDA installer in the container..."
distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "export WINEPREFIX=\"$VALERIO_PREFIX_DIR\"; export PATH=\"$WINE_CUSTOM_BIN:\$PATH\"; wine \"$FOUND_INSTALLER\""
