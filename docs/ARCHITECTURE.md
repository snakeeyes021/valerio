# Steinberg Dorico on Linux - Active Blueprint (Container Method)

## The "jgke" Container Method (Current Work-in-Progress)
This is the active roadmap for building a reproducible, high-performance Steinberg environment on an immutable host using Distrobox and a custom-compiled Wine.

### Current Base Environment
*   **Container Host:** Distrobox (Ubuntu 24.04).
*   **Engine:** Docker.
*   **Custom Wine Build:** `zhiyi/wine` branch `bug-23698-react-native-20251217`.
    *   *Why:* Includes DirectComposition (`dcomp`) stubs required by Dorico 6.
    *   *Build Specifics:* Compiled with native `libicu-dev` support.
*   **Prefix Config:** Windows 10 (via Winetricks).
*   **Core Dependencies:** `d3dx9`, `msls31`, `allfonts`, `d3dcompiler_43`, `d3dcompiler_47`, `vcrun2019`, `dotnet48`, `wine-icu` (manual MSI).

### Permanent Infrastructure & Scripting
These scripts are currently sitting in the repository root and serve to preserve the environment variables and launch logic across reboots and different machines.

*   **`build_wine.sh`:** Automates the fetching of build-deps and the dual-architecture (32/64-bit) Wine compilation.
*   **`setup_prefix.sh`:** Automates the creation of the Wine prefix and the installation of initial Winetricks dependencies.
*   **`dorico.sh`:** Handles launching Dorico 6 with the correct `WINEPREFIX` and `PATH` inside the container.
*   **`sam.sh`:** Handles the Activation Manager, including the handoff logic for `net-steinberg-sam://` URL tokens using the `--redirect` flag.
*   **`install_noteperformer.sh`:** A generalized installer script that uses glob patterns (`NotePerformer-Installer-*.exe`) to handle the customer-specific personalized filenames used by NotePerformer.

## Installed Components & Working Features
*   **NotePerformer 5.1.2:** Successfully installed and verified running in Dorico. (Manual installation confirmed working under the `dcomp` Wine build).
