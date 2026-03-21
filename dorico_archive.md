# Steinberg Dorico on Linux - Archive (Bottles/Flatpak Attempt)

## Historical Baseline (The Bottles Method)
This document preserves the state of the initial attempt to get Dorico running via Bottles (Flatpak) on an immutable host. This method was eventually sidelined in favor of the Distrobox/Container approach.

### Setup at the Time
*   **Runner:** GE-Proton (e.g., `ge-proton10-33`).
*   **Bottle Type:** Gaming.
*   **Dependencies:** `dotnet48`, `vcredist2019`, and `allfonts`.
*   **Authentication Handoff:** Custom bash script tied to a `.desktop` file to catch `net-steinberg-sda://` links.

### The Original Handoff Code
**Bash Script (`~/.local/bin/steinberg-sda-handler.sh`)**
```bash
#!/bin/bash
if [ -z "$1" ]; then
    flatpak run --command=bottles-cli com.usebottles.bottles run -b "Steinberg" -p "Steinberg Download Assistant"
else
    flatpak run --command=bottles-cli com.usebottles.bottles shell -b "Steinberg" -i "\"C:\Program Files (x86)\Steinberg\Download Assistant\Steinberg Download Assistant.exe\" \"$1\""
fi
```

### Roadblocks & Findings
*   **Token Injection:** The `shell -i` method worked but caused deadlocks if the app wasn't already open in the Bottles GUI.
*   **The `--redirect` flag:** Originally abandoned in Bottles as it "did nothing" (it refocuses the window but didn't authenticate). *Note: We later found this was due to argument parsing issues.*
*   **Java 267 Error:** Fixed by manually creating `C:\Program Files\Steinberg\Install Assistant`.
*   **The Final Block:** SDA downloaded zips but failed to extract them, throwing `mscoree.dll` errors despite `.NET 4.8` being installed via Bottles.
