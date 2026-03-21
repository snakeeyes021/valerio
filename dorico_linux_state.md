# Steinberg Dorico on Linux - State Digest

## Where We Are (Current Baseline)
We are attempting to get Dorico 4 (and potentially 5/6) running on Linux using Bottles (Flatpak). 
So far, we have successfully managed to install the **Steinberg Download Assistant (SDA)** and get past its browser-based authentication loop.

### Working Setup
*   **Runner:** GE-Proton (e.g., `ge-proton10-33`).
*   **Bottle Type:** Gaming.
*   **Dependencies Installed:** `dotnet48`, `vcredist2019`, and `allfonts`. (These were installed using the Bottles built-in dependency manager).
*   **Authentication Handoff:** We use a custom bash script tied to a `.desktop` file to catch `net-steinberg-sda://` links from the browser and pass the token back into the bottle.

### The Token Handoff Code
**Bash Script (`~/.local/bin/steinberg-sda-handler.sh`)**
```bash
#!/bin/bash
if [ -z "$1" ]; then
    flatpak run --command=bottles-cli com.usebottles.bottles run -b "Steinberg" -p "Steinberg Download Assistant"
else
    flatpak run --command=bottles-cli com.usebottles.bottles shell -b "Steinberg" -i "\"C:\Program Files (x86)\Steinberg\Download Assistant\Steinberg Download Assistant.exe\" \"$1\""
fi
```
*(Make sure to `chmod +x` this script)*

**.desktop File Modifications**
Find the generated `.desktop` file in `~/.local/share/applications/` and edit the `Exec` line, plus add the `MimeType` at the end:
```ini
Exec=bash -c '"$HOME/.local/bin/steinberg-sda-handler.sh" "%u"'
MimeType=x-scheme-handler/net-steinberg-sda;
```
Then run:
`update-desktop-database ~/.local/share/applications`
`xdg-mime default [YOUR_DESKTOP_FILENAME].desktop x-scheme-handler/net-steinberg-sda`

## What Works & Workarounds
*   **Token Injection:** The `shell -i` method successfully passes the token back to SDA.
    *   *Quirk/Workaround:* This currently **only** works if you initially launched SDA via the "Play" button in the Bottles GUI. Launching from the system `.desktop` shortcut causes a deadlock/freeze when the token is injected.
*   **Java 267 Error (`CreateProcess error=267`):** The SDA Java wrapper crashes looking for a working directory that doesn't exist.
    *   *Workaround:* Manually create `C:\Program Files\Steinberg\Install Assistant` inside the prefix.
    *   *Note:* We suspect this is treating a symptom of a prior silent failure where the runner failed to execute the sub-installer meant to create this folder.

## What Doesn't Work (Current Roadblock)
*   **Extraction/Installation:** The SDA can download the zips but fails to extract and install them, eventually throwing an `mscoree.dll` error.

## What We Tried & Abandoned
*   **The `--redirect` flag:** A forum post suggested passing the URL token to the `.exe` via `--redirect`. We tried this in our bash script instead of `shell -i`, but it resulted in "no action" (it just refocused the window without authenticating). We reverted back to `shell -i`.

## Pending Tests (What We Are Planning Next)
*   **The `mscoree.dll` issue:** Since this is a core .NET file, we suspect that `.NET 4.8` (installed via the Bottles UI) might not be overriding properly. We are considering nuking the bottle and testing the installation of `dotnet48` via **Winetricks** instead to see if it fixes the extraction crash. We haven't actually tested this yet.

## To-Do List (Tech Debt)
*   **Desktop Shortcut Cleanup (UX/UI):** Distrobox auto-exported `.desktop` files with proper icons, conflicting with our custom manual ones. We need to use the current "messy" state of this machine as a diagnostic baseline to determine exactly which `.desktop` file holds the "Nice Icon" vs the "Functional Link Handler" so we can merge them properly, while suppressing the export of unnecessary background Steinberg utilities.
*   **High-DPI / 4K Scaling:** Wine isn't scaling automatically on 4K screens. We need to investigate Wine DPI registry keys or a dynamic DPI switcher alias.
*   **VSTAudioEngine6.exe Crash:** The audio engine crashes cleanly upon closing Dorico. Need to investigate if this is a Pipewire/ASIO routing issue or a Wine teardown bug.
*   **Install NotePerformer:** Add the NotePerformer installation to the standard reproducible deployment script.
*   **Visual Glitches / GE-Proton Experiment:** The current `zhiyi/wine` build has transparent text in SDA and font ugliness. We should create an experimental Git branch to try patching `dcomp` directly onto an *optimal* version of GE-Proton (Current/RC/Matching) to see if we get the best of both worlds.
*   **GNOME / Adwaita Theming:** Investigate applying a Windows `.msstyles` theme (or Wine theming equivalent) to make Wine scrollbars and menus match GNOME/Adwaita natively. (KDE users could get Breeze or default).
*   **Automate Wine-ICU Installation:** Wine 9.x+ prompts for a `wine-icu` package. We need to add the silent download and installation of the `wine-icu` MSI to our container build script so the user isn't prompted.
*   **Version Manifest Generation:** Once a working state is confirmed, programmatically extract and record the exact version numbers of every piece of installed Steinberg software (SDA, MediaBay, Dorico, HALion, etc.) to create a fully reproducible manifest.
*   **SAM Link Handler:** Once Dorico is installed, replicate the SDA token-catching bash script for the Steinberg Activation Manager (`net-steinberg-sam://`).
*   **"License Eater" Bug:** Figure out a backup strategy (e.g., copying the prefix). Bottles stopping/restarting processes causes the virtual hardware fingerprint to change, making SAM invalidate the license.
*   **Mono Audio Bug:** Dorico currently outputs sound only to one channel. Needs routing/Pipewire fixes.
*   **NotePerformer UI:** Fix graphical glitches in the NotePerformer VST window.

## Looking Forward: The "jgke" Container Method
A user on the forums recently managed to get **Dorico 6** fully working. 
*   **The Secret:** Dorico 6 requires the DirectComposition (`dcomp`) API. Upstream Wine doesn't support this yet. The user compiled a custom Wine branch (`bug-23698-react-native-20251217`) that includes `dcomp` stubs.
*   **Our Plan for This:** Rather than trying to cram this into Flatpak Bottles or messing with our immutable host, we would use **Distrobox/DistroShelf**.
    *   Create a mutable container (Arch or Ubuntu).
    *   Install build dependencies and compile the custom Wine branch inside it.
    *   Install the Steinberg suite inside the container.
    *   Export the app shortcut to the host desktop (`distrobox-export --app`).
    *   *Benefit:* This gives near-native performance, direct access to the host's Pipewire (essential for low latency), and avoids Flatpak sandboxing issues.

## Reproducibility Artifacts (jgke Container Method)
To ensure we can always rebuild this exact working state, we have locked in the following hashes from our initial successful build:
*   **Custom Wine Repository (`zhiyi/wine`):** Branch `bug-23698-react-native-20251217` checked out at commit `ae88a705b5aa544cc60153d48c1ca8849f32ee14`.
*   **Winetricks:** Version `20260125-next` (SHA256: `8f07319f32e96a7ad92f786bf8ee2e00d3c65f82debd33b6884e681b825ae67a`).