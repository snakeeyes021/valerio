#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

export WINEPREFIX="$TORQUIO_PREFIX_DIR"
export WINE="$WINE_CUSTOM_BIN/wine"
export WINESERVER="$WINE_CUSTOM_BIN/wineserver"
export PATH="$WINE_CUSTOM_BIN:$PATH"

# Suppress Wine Mono, Gecko installer prompts, and prevent winemenubuilder pollution
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};mscoree=d;mshtml=d"

if [ -d "$WINEPREFIX" ] && [ -f "$WINEPREFIX/.torquio_core_installed" ]; then
    echo "Wine prefix already initialized with core dependencies. Skipping baseline setup."
    exit 0
fi

echo "Initializing Wine prefix at $WINEPREFIX..."
wineboot -u

echo "Installing winetricks dependencies (this may pop up some windows, please click through them if needed)..."

# Array of packages to install
PACKAGES=("d3dx9" "msls31" "allfonts" "d3dcompiler_43" "d3dcompiler_47" "vcrun2019" "dotnet48" "win10")

for pkg in "${PACKAGES[@]}"; do
    MARKER_FILE="$WINEPREFIX/.torquio_wt_${pkg}_installed"
    
    if [ -f "$MARKER_FILE" ]; then
        echo "Package $pkg already installed successfully. Skipping."
        continue
    fi

    echo "Attempting to install: $pkg"
    MAX_RETRIES=5
    RETRY_COUNT=0
    SUCCESS=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        # Run winetricks for the specific package
        # We disable 'set -e' temporarily so a failing winetricks command doesn't crash the script
        set +e
        winetricks -q "$pkg"
        WT_STATUS=$?
        set -e
        
        if [ $WT_STATUS -eq 0 ]; then
            echo "Successfully installed: $pkg"
            touch "$MARKER_FILE"
            SUCCESS=1
            break
        else
            echo "WARNING: winetricks failed to install $pkg (Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)."
            
            # Wipe the cache for the failed package to handle broken fallback HTML downloads
            if [ "$pkg" == "allfonts" ]; then
                # allfonts touches many cache directories, safest to wipe the whole winetricks cache
                # except for packages we know we already installed. Since we are in the middle of
                # an install process, wiping the cache is safe.
                echo "Wiping winetricks cache due to 'allfonts' failure..."
                rm -rf ~/.cache/winetricks/*
            else
                echo "Wiping cache for $pkg..."
                rm -rf ~/.cache/winetricks/"$pkg"
            fi

            RETRY_COUNT=$((RETRY_COUNT + 1))
            
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo "Waiting 30 seconds before retrying..."
                sleep 30
            fi
        fi
    done

    if [ $SUCCESS -eq 0 ]; then
        echo "======================================================================"
        echo "ERROR: Failed to install winetricks package: $pkg after $MAX_RETRIES attempts."
        echo "This is frequently caused by a transient issue with the SourceForge or Wayback Machine servers."
        echo ""
        echo "If your internet connection is working correctly for other tasks, the problem"
        echo "is likely not on your end. Please wait a few minutes and re-run the master"
        echo "installer orchestrator script."
        echo ""
        echo "NOTE: You DO NOT need to delete your existing prefix or start from scratch."
        echo "The script will automatically resume from this exact point when you run it again."
        echo "======================================================================"
        exit 1
    fi
done

echo "Configuring Keyboard Focus Loss Mitigation & Accessibility Registry Overrides..."
# FocusOnClick forces window focus acquisition upon mouse click, preventing focus loss in modals
wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v FocusOnClick /t REG_SZ /d Y /f
wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v UseTakeFocus /t REG_SZ /d N /f

# Force client-side font anti-aliasing and XRender overrides in Wine X11 Driver
wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v ClientSideWithRender /t REG_SZ /d Y /f
wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v ClientSideAntiAliasWithRender /t REG_SZ /d Y /f
wine reg add "HKCU\\Software\\Wine\\X11 Driver" /v ClientSideWithCore /t REG_SZ /d Y /f

# Enable Font Smoothing (ClearType) and subpixel rendering parameters
wine reg add "HKCU\\Control Panel\\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f
wine reg add "HKCU\\Control Panel\\Desktop" /v FontSmoothingGamma /t REG_DWORD /d 1400 /f
wine reg add "HKCU\\Control Panel\\Desktop" /v FontSmoothingOrientation /t REG_DWORD /d 1 /f
wine reg add "HKCU\\Control Panel\\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f

# Customize key repeat speed to mitigate Auto-Repeat Lag Bug
wine reg add "HKCU\\Control Panel\\Accessibility\\Keyboard Response" /v AutoRepeatDelay /t REG_SZ /d "250" /f
wine reg add "HKCU\\Control Panel\\Accessibility\\Keyboard Response" /v AutoRepeatRate /t REG_SZ /d "30" /f
wine reg add "HKCU\\Control Panel\\Accessibility\\Keyboard Response" /v Flags /t REG_SZ /d "126" /f

echo "Downloading and installing wine-icu (required for Dorico)..."
ICU_VERSION="72.1"
ICU_X86_URL="https://gitlab.winehq.org/api/v4/projects/2302/packages/generic/wine-icu/$ICU_VERSION/wine-icu-$ICU_VERSION-x86.msi"
ICU_X64_URL="https://gitlab.winehq.org/api/v4/projects/2302/packages/generic/wine-icu/$ICU_VERSION/wine-icu-$ICU_VERSION-x86_64.msi"

mkdir -p "$TORQUIO_CACHE_DIR/icu"
wget -q --show-progress "$ICU_X86_URL" -O "$TORQUIO_CACHE_DIR/icu/wine-icu-x86.msi"
wget -q --show-progress "$ICU_X64_URL" -O "$TORQUIO_CACHE_DIR/icu/wine-icu-x64.msi"

echo "Installing ICU x86..."
wine msiexec /i "$TORQUIO_CACHE_DIR/icu/wine-icu-x86.msi" /qn
echo "Installing ICU x64..."
wine msiexec /i "$TORQUIO_CACHE_DIR/icu/wine-icu-x64.msi" /qn

# Drop a marker file to indicate the prefix setup completed successfully
touch "$WINEPREFIX/.torquio_core_installed"
echo "Done with winetricks, ICU, and registry optimization!"