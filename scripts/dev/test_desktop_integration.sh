#!/bin/bash
set -e

# Torquio Desktop Integration Test Harness
# Tests exact WM_CLASS window grouping and MIME handling on Mint, Ubuntu, Vanilla GNOME, KDE, and Cosmic.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures/png"

WRAPPER_SCRIPT="$SCRIPT_DIR/test_app_wrapper.sh"
APPS_DIR="$HOME/.local/share/applications"
ICON_BASE="$HOME/.local/share/icons/hicolor"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
reset='\033[0m'

# Check for cleanup flag
if [ "$1" == "--clean" ] || [ "$1" == "clean" ]; then
    echo -e "${yellow}Cleaning up all Torquio Test harness artifacts...${reset}"
    rm -f "$APPS_DIR/Torquio-Test-Dorico.desktop"
    rm -f "$APPS_DIR/Torquio-Test-SDA.desktop"
    rm -f "$APPS_DIR/Steinberg Download Assistant.desktop"
    rm -f "$ICON_BASE/256x256/apps/torquio-test-dorico.png"
    rm -f "$ICON_BASE/256x256/apps/torquio-test-sda.png"
    rm -f "$ICON_BASE/256x256/apps/torquio-sda.png"
    
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
    fi
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f -t "$ICON_BASE" >/dev/null 2>&1 || true
    fi
    echo -e "${green}✓ All test artifacts removed successfully.${reset}"
    exit 0
fi

echo -e "${blue}====================================================${reset}"
echo -e "${blue} Torquio WM_CLASS & Dock Grouping Test Harness      ${reset}"
echo -e "${blue}====================================================${reset}"
echo "Running on Host OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2 2>/dev/null || echo "Linux")"
echo "Desktop Session:   ${XDG_CURRENT_DESKTOP:-$DESKTOP_SESSION} (${XDG_SESSION_TYPE:-x11})"
echo ""

# Step 1: Install Icons
echo -e "${yellow}[1/4] Installing test icons into hicolor theme...${reset}"
mkdir -p "$ICON_BASE/256x256/apps"

if [ -f "$FIXTURES_DIR/torquio-dorico.png" ]; then
    cp "$FIXTURES_DIR/torquio-dorico.png" "$ICON_BASE/256x256/apps/torquio-test-dorico.png"
    echo -e "  ${green}✓ Installed torquio-test-dorico.png${reset}"
fi
if [ -f "$FIXTURES_DIR/torquio-sda.png" ]; then
    cp "$FIXTURES_DIR/torquio-sda.png" "$ICON_BASE/256x256/apps/torquio-test-sda.png"
    cp "$FIXTURES_DIR/torquio-sda.png" "$ICON_BASE/256x256/apps/torquio-sda.png"
    echo -e "  ${green}✓ Installed torquio-test-sda.png${reset}"
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$ICON_BASE" >/dev/null 2>&1 || true
fi

# Step 2: Generate Launchers with Exact WM_CLASS Mapping
echo ""
echo -e "${yellow}[2/4] Generating launchers in ~/.local/share/applications/...${reset}"
mkdir -p "$APPS_DIR"

# 1. Torquio TEST Dorico
cat << EOF > "$APPS_DIR/Torquio-Test-Dorico.desktop"
[Desktop Entry]
Name=Torquio TEST Dorico
Comment=Test Launcher for Torquio Desktop Integration
Exec=$WRAPPER_SCRIPT "%F" "dorico6.exe"
Icon=torquio-test-dorico
Type=Application
Terminal=false
StartupWMClass=dorico6.exe
Categories=AudioVideo;Audio;
EOF
chmod +x "$APPS_DIR/Torquio-Test-Dorico.desktop"
echo -e "  ${green}✓ Created Torquio-Test-Dorico.desktop${reset}"

# 2. Steinberg Download Assistant (Standardized FreeDesktop Naming Test)
cat << EOF > "$APPS_DIR/Steinberg Download Assistant.desktop"
[Desktop Entry]
Name=Torquio TEST SDA
Comment=Test Launcher for Steinberg Download Assistant Window Grouping
Exec=$WRAPPER_SCRIPT "%u" "steinberg download assistant.exe"
Icon=torquio-test-sda
Type=Application
Terminal=false
StartupWMClass=steinberg download assistant.exe
Categories=AudioVideo;Audio;
MimeType=x-scheme-handler/net-torquio-test-sda;
EOF
chmod +x "$APPS_DIR/Steinberg Download Assistant.desktop"
echo -e "  ${green}✓ Created Steinberg Download Assistant.desktop${reset}"

# Refresh Desktop Database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
fi
touch "$APPS_DIR" >/dev/null 2>&1 || true

# Register Custom Test Protocol Handoff
if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default "Steinberg Download Assistant.desktop" x-scheme-handler/net-torquio-test-sda 2>/dev/null || true
    echo -e "  ${green}✓ Registered x-scheme-handler/net-torquio-test-sda -> Steinberg Download Assistant.desktop${reset}"
fi

# Step 3: Diagnostics & Syntax Validation
echo ""
echo -e "${yellow}[3/4] Running Diagnostics...${reset}"
if command -v desktop-file-validate >/dev/null 2>&1; then
    echo -n "Checking .desktop syntax validation: "
    ERRS=0
    for dt in "$APPS_DIR/Torquio-Test-Dorico.desktop" "$APPS_DIR/Steinberg Download Assistant.desktop"; do
        if ! desktop-file-validate "$dt" >/dev/null 2>&1; then
            ERRS=$((ERRS + 1))
            echo -e "\n  ${red}Syntax error in $(basename "$dt")${reset}"
        fi
    done
    [ $ERRS -eq 0 ] && echo -e "${green}PASS${reset}"
fi

MIME_STATUS=$(xdg-mime query default x-scheme-handler/net-torquio-test-sda 2>/dev/null || echo "")
echo -n "Checking Test MIME association: "
if [ "$MIME_STATUS" == "Steinberg Download Assistant.desktop" ]; then
    echo -e "${green}PASS (Associated with Steinberg Download Assistant.desktop)${reset}"
else
    echo -e "${red}FAIL (Current: '$MIME_STATUS')${reset}"
fi

# Step 4: Testing Instructions
echo ""
echo -e "${yellow}[4/4] How to verify panel/dock grouping on your test machine:${reset}"
echo -e "${blue}----------------------------------------------------${reset}"
echo -e "1. LAUNCH TEST APPS FROM MENU:"
echo -e "   - Search your menu for ${green}\"Torquio TEST\"${reset} and click to launch."
echo -e "   - Verify: Does a GUI test window open?"
echo -e "   - Verify: Check your panel (Mint) / side dock (Ubuntu). Does the running"
echo -e "     window group cleanly under the launcher icon with friendly name?"
echo ""
echo -e "2. TEST BROWSER HANDOFF:"
echo -e "   - Run: ${green}xdg-open 'net-torquio-test-sda://token=AUTH_SUCCESS_123'${reset}"
echo -e "   - Verify: Does the test window open and show the token?"
echo ""
echo -e "3. CLEANUP WHEN DONE:"
echo -e "   - Run: ${yellow}./scripts/dev/test_desktop_integration.sh --clean${reset}"
echo -e "${blue}----------------------------------------------------${reset}"
