#!/bin/bash
VALERIO_CONTAINER_NAME="valerio-env"
VALERIO_PREFIX_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/valerio/prefix"
WINE_CUSTOM_BIN="/opt/wine-custom/bin"

URL="$1"

if [ -n "$URL" ]; then
    # Launched by browser (link provided) - pass the URL directly without --redirect
    distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "export WINEPREFIX=\"$VALERIO_PREFIX_DIR\"; export PATH=\"$WINE_CUSTOM_BIN:\$PATH\"; wine 'C:\\Program Files (x86)\\Steinberg\\Download Assistant\\Steinberg Download Assistant.exe' '$URL'"
else
    # Standard launch (no link)
    distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "export WINEPREFIX=\"$VALERIO_PREFIX_DIR\"; export PATH=\"$WINE_CUSTOM_BIN:\$PATH\"; wine 'C:\\Program Files (x86)\\Steinberg\\Download Assistant\\Steinberg Download Assistant.exe'"
fi
