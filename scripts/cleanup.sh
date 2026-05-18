#!/bin/bash
# Valerio Cleanup / Uninstaller Script
# This script wipes the Valerio environment including the container, data, and cache.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo ""
echo "WARNING:"
echo ""
echo "⚠️  If you have not deactivated your license(s), you will PERMANENTLY lose access!"
echo "⚠️  If you store your Dorico projects inside the data directory, you will PERMANENTLY lose access!"
echo ""
echo "This operation will permanently delete the following:"
echo " - Distrobox container: $VALERIO_CONTAINER_NAME"
echo " - Data directory: $VALERIO_DATA_DIR (includes Wine prefix)"
echo " - Cache directory: $VALERIO_CACHE_DIR (includes Wine source code and compilation artifacts)"
echo " - Host integration scripts and .desktop files"
echo " - Extracted desktop icons"
echo ""
read -p "Have you deactivated your license(s)? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi
read -p "Have you backed up any Dorico projects you were keeping in the data directory? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi
read -p "If you have read the above warning and would like to proceed, type 'yes, permanently delete everything' to continue: " confirm

if [[ "$confirm" != "yes, permanently delete everything" ]]; then
    echo "Confirmation failed. Cleanup cancelled."
    exit 0
fi

echo "Removing Distrobox container..."
distrobox rm "$VALERIO_CONTAINER_NAME" --force || true

echo "Removing data and cache directories..."
rm -rf "$VALERIO_DATA_DIR"
rm -rf "$VALERIO_CACHE_DIR"

echo "Removing host integrations..."
# Removing scripts from ~/.local/bin
rm -f "$HOME/.local/bin/dorico.sh"
rm -f "$HOME/.local/bin/sam.sh"
rm -f "$HOME/.local/bin/steinberg-sda-handler.sh"

# Removing .desktop files
rm -f "$HOME/.local/share/applications/Dorico.desktop"
rm -f "$HOME/.local/share/applications/Steinberg Activation Manager.desktop"
rm -f "$HOME/.local/share/applications/steinberg-sda-handler.desktop"
rm -f "$HOME/.local/share/applications/wine-extension-dorico.desktop"

# Removing extracted icons
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/valerio-dorico.png"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/valerio-dorico-project.png"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/valerio-sda.png"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/valerio-sam.png"

# Removing MIME types
rm -f "$HOME/.local/share/mime/packages/application-x-dorico.xml"

echo "Updating desktop database and icon cache..."
update-desktop-database "$HOME/.local/share/applications/" || true
update-mime-database "$HOME/.local/share/mime/" || true
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" || true
fi

echo "Cleanup complete! The Valerio environment has been wiped."
