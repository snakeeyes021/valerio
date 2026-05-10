#!/bin/bash
set -e

# Valerio Master Installer
# This script automates the entire installation process for Steinberg software on Linux.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

echo "==========================================="
echo "   Valerio: Steinberg on Linux Installer   "
echo "==========================================="
echo ""

# 1. Prerequisite Checks
echo "Checking prerequisites..."
if ! command -v distrobox >/dev/null 2>&1; then
    echo "Error: distrobox is not installed."
    echo "Please install distrobox and either docker or podman."
    exit 1
fi

# Check for docker or podman
if ! command -v docker >/dev/null 2>&1 && ! command -v podman >/dev/null 2>&1; then
    echo "Error: Neither docker nor podman was found."
    echo "Please install one of them to use with distrobox."
    exit 1
fi

# 2. Asset Validation
echo "Validating installers..."
mkdir -p "$VALERIO_INSTALLERS_DIR"
if [ ! -f "$VALERIO_INSTALLERS_DIR/MediaBay_Installer_win64.zip" ] && [ ! -f "$HOME/Downloads/MediaBay_Installer_win64.zip" ]; then
    echo "Warning: MediaBay_Installer_win64.zip not found."
    echo "Please place it in $VALERIO_INSTALLERS_DIR or ~/Downloads before continuing."
    read -p "Press Enter to continue once the file is in place, or Ctrl+C to abort."
fi

# 3. Container Creation
echo "Phase 1: Creating Distrobox container ($VALERIO_CONTAINER_NAME)..."
if distrobox list | grep -q "$VALERIO_CONTAINER_NAME"; then
    echo "Container $VALERIO_CONTAINER_NAME already exists. Skipping creation."
else
    distrobox create -i ubuntu:24.04 -n "$VALERIO_CONTAINER_NAME" --yes
fi

# We use the absolute path to the workspace within the container. 
# Distrobox mounts the host's current directory to the exact same path in the container.
WORKSPACE_DIR="$(pwd)"

# 4. Engine Compilation & Installation
echo "Phase 2: Compiling Wine Engine..."
distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "cd \"$WORKSPACE_DIR\" && ./scripts/1-build/build_wine.sh"

# 5. Prefix Initialization
echo "Phase 3: Initializing Wine Prefix..."
distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "cd \"$WORKSPACE_DIR\" && ./scripts/2-install/setup_prefix.sh"

# 6. Software Component Installation
echo "Phase 4: Installing Steinberg Components..."

echo "Installing SDA..."
distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "cd \"$WORKSPACE_DIR\" && ./scripts/2-install/install_sda.sh"

echo "Installing MediaBay..."
distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "cd \"$WORKSPACE_DIR\" && ./scripts/2-install/install_mediabay.sh"

echo "Checking for NotePerformer..."
# Find NotePerformer installer if it exists
NP_FOUND=""
for DIR in "$VALERIO_INSTALLERS_DIR" "$HOME/Downloads" "$WORKSPACE_DIR"; do
    if [ -d "$DIR" ]; then
        MATCH=$(find "$DIR" -maxdepth 1 -name "NotePerformer-Installer-*.exe" | head -n 1)
        if [ -n "$MATCH" ]; then
            NP_FOUND="true"
            break
        fi
    fi
done

if [ -n "$NP_FOUND" ]; then
    echo "Installing NotePerformer..."
    distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "cd \"$WORKSPACE_DIR\" && ./scripts/2-install/install_noteperformer.sh"
else
    echo "NotePerformer installer not found. Skipping."
fi

# 7. Host Integration
echo "Phase 5: Performing Host Integration..."
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/scripts/3-runtime_handlers/"*.sh "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"*.sh

cp "$SCRIPT_DIR/desktop_stubs/"*.desktop "$HOME/.local/share/applications/"
update-desktop-database "$HOME/.local/share/applications/"

echo ""
echo "==========================================="
echo "   Installation Complete!                 "
echo "==========================================="
echo "You can now launch Dorico 6, SAM, or SDA from your application menu."
