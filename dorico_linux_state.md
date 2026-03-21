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

## To-Do List (Tech Debt & Polish)
*   **High-DPI / 4K Scaling:** Wine isn't scaling automatically on 4K screens. We need to investigate Wine DPI registry keys or a dynamic DPI switcher alias.
*   **VSTAudioEngine6.exe Crash:** The audio engine crashes cleanly upon closing Dorico. Need to investigate if this is a Pipewire/ASIO routing issue or a Wine teardown bug.
*   **Install NotePerformer:** Add the NotePerformer installation to the standard reproducible deployment script.
*   **Visual Glitches / GE-Proton Experiment:** The current `zhiyi/wine` build has transparent text in SDA and font ugliness. Create an experimental Git branch to try patching `dcomp` directly onto an *optimal* version of GE-Proton.
*   **GNOME / Adwaita Theming:** Investigate applying a Windows `.msstyles` theme to make Wine scrollbars and menus match GNOME/Adwaita natively.
*   **Desktop Shortcut Cleanup (UX/UI):** Distrobox auto-exported `.desktop` files with proper icons, conflicting with our custom manual ones. Use the current "messy" state of this machine as a diagnostic baseline to merge the "Nice Icon" with the "Functional Link Handler."
*   **Automate Wine-ICU Installation:** Add the silent download and installation of the `72.1` MSI to the build script.
*   **Version Manifest Generation:** Programmatically extract and record the exact version numbers of every piece of installed Steinberg software to create a reproducible manifest.
*   **"License Eater" Bug:** Figure out a backup strategy for the prefix to avoid SAM invalidating the license if the virtual hardware fingerprint changes.

## Reproducibility Artifacts (Hashes)
*   **Wine Repository (`zhiyi/wine`):** Commit `ae88a705b5aa544cc60153d48c1ca8849f32ee14`.
*   **Winetricks:** Version `20260125-next` (SHA256: `8f07319f32e96a7ad92f786bf8ee2e00d3c65f82debd33b6884e681b825ae67a`).
