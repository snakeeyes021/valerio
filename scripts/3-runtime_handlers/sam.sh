#!/bin/bash
VALERIO_CONTAINER_NAME="valerio-env"
VALERIO_PREFIX_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/valerio/prefix"
WINE_CUSTOM_BIN="/opt/wine-custom/bin"

URL="$1"

if [ -n "$URL" ]; then
    # Launched by browser (link provided)
    distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "export WINEPREFIX=\"$VALERIO_PREFIX_DIR\"; export PATH=\"$WINE_CUSTOM_BIN:\$PATH\"; cd \"$VALERIO_PREFIX_DIR/drive_c/Program Files/Steinberg/Activation Manager\"; wine 'SteinbergActivationManager.exe' --redirect '$URL'"
else
    # Standard launch (no link)
    distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "export WINEPREFIX=\"$VALERIO_PREFIX_DIR\"; export PATH=\"$WINE_CUSTOM_BIN:\$PATH\"; cd \"$VALERIO_PREFIX_DIR/drive_c/Program Files/Steinberg/Activation Manager\"; wine 'SteinbergActivationManager.exe'"
fi
