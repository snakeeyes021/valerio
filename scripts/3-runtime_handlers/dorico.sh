#!/bin/bash
VALERIO_CONTAINER_NAME="valerio-env"
VALERIO_PREFIX_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/valerio/prefix"
WINE_CUSTOM_BIN="/opt/wine-custom/bin"

distrobox enter "$VALERIO_CONTAINER_NAME" -- bash -c "export WINEPREFIX=\"$VALERIO_PREFIX_DIR\"; export WINEDLLOVERRIDES=\"winemenubuilder.exe=d\"; export PATH=\"$WINE_CUSTOM_BIN:\$PATH\"; cd \"$VALERIO_PREFIX_DIR/drive_c/Program Files/Steinberg/Dorico6\"; wine 'Dorico6.exe'"