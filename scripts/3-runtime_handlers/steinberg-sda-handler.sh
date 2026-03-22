#!/bin/bash
URL="$1"

if [ -n "$URL" ]; then
    # Launched by browser (link provided) - pass the URL directly without --redirect
    distrobox enter dorico-box -- bash -c "export WINEPREFIX=\"\$HOME/dev/steinberg-on-linux/dorico-prefix\"; export PATH=\"/opt/wine-custom/bin:\$PATH\"; wine 'C:\\Program Files (x86)\\Steinberg\\Download Assistant\\Steinberg Download Assistant.exe' '$URL'"
else
    # Standard launch (no link)
    distrobox enter dorico-box -- bash -c "export WINEPREFIX=\"\$HOME/dev/steinberg-on-linux/dorico-prefix\"; export PATH=\"/opt/wine-custom/bin:\$PATH\"; wine 'C:\\Program Files (x86)\\Steinberg\\Download Assistant\\Steinberg Download Assistant.exe'"
fi
