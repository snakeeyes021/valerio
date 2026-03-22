#!/bin/bash
URL="$1"

if [ -n "$URL" ]; then
    # Launched by browser (link provided)
    distrobox enter dorico-box -- bash -c "export WINEPREFIX=\"\$HOME/dev/steinberg-on-linux/dorico-prefix\"; export PATH=\"/opt/wine-custom/bin:\$PATH\"; cd \"\$HOME/dev/steinberg-on-linux/dorico-prefix/drive_c/Program Files/Steinberg/Activation Manager\"; wine 'SteinbergActivationManager.exe' --redirect '$URL'"
else
    # Standard launch (no link)
    distrobox enter dorico-box -- bash -c "export WINEPREFIX=\"\$HOME/dev/steinberg-on-linux/dorico-prefix\"; export PATH=\"/opt/wine-custom/bin:\$PATH\"; cd \"\$HOME/dev/steinberg-on-linux/dorico-prefix/drive_c/Program Files/Steinberg/Activation Manager\"; wine 'SteinbergActivationManager.exe'"
fi