#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# Array of directories to search. Order matters: it will stop at the first match.
SEARCH_DIRS=("$VALERIO_INSTALLERS_DIR" "$HOME/Downloads" "$(pwd)")
FOUND_INSTALLER=""

# 1. Search Phase
for DIR in "${SEARCH_DIRS[@]}"; do
    # Skip if the directory doesn't exist
    if [ ! -d "$DIR" ]; then
        continue
    fi
    
    # Look for the NotePerformer installer in this directory
    # NotePerformer installers often include personalized names/IDs, so we use a loose glob.
    MATCH=$(find "$DIR" -maxdepth 1 -name "NotePerformer-Installer-*.exe" | head -n 1)
    
    if [ -n "$MATCH" ]; then
        FOUND_INSTALLER="$MATCH"
        echo "Found NotePerformer installer: $FOUND_INSTALLER"
        break
    fi
done

# 2. Download / Fallback Phase
if [ -z "$FOUND_INSTALLER" ]; then
    echo "Error: NotePerformer installer not found locally."
    echo "NotePerformer must be downloaded manually from your personal link."
    echo "Please place the installer in $VALERIO_INSTALLERS_DIR, ~/Downloads, or run this script from the directory containing it."
    
    exit 1
fi

# 3. Execution Phase
# Passing the guaranteed absolute path ($FOUND_INSTALLER) to Wine inside the Distrobox container.
distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "export WINEPREFIX=\"$VALERIO_PREFIX_DIR\"; export PATH=\"$WINE_CUSTOM_BIN:\$PATH\"; wine \"$FOUND_INSTALLER\""
