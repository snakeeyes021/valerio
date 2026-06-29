#!/bin/bash
set -e

# Torquio State-Agnostic Desktop Integration Test Harness
# This test harness is completely independent of whether a real or partial Torquio installation exists.
# It creates isolated, uniquely-named test applications ("Torquio TEST Dorico", "Torquio TEST SDA")
# so you can verify menu discovery, icon rendering, and MIME handoffs without clashing with existing files.

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
    rm -f "$ICON_BASE/256x256/apps/torquio-test-dorico.png"
    rm -f "$ICON_BASE/256x256/apps/torquio-test-sda.png"
    
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
echo -e "${blue} Torquio State-Agnostic Desktop Test Harness        ${reset}"
echo -e "${blue}====================================================${reset}"
echo "Running on Host OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2 2>/dev/null || echo "Linux")"
echo "Desktop Session:   ${XDG_CURRENT_DESKTOP:-$DESKTOP_SESSION} (${XDG_SESSION_TYPE:-x11})"
echo ""

# Step 1: Install Unique Test Icons
echo -e "${yellow}[1/4] Installing unique test icons into hicolor theme...${reset}"
mkdir -p "$ICON_BASE/256x256/apps"

if [ -f "$FIXTURES_DIR/torquio-dorico.png" ]; then
    cp "$FIXTURES_DIR/torquio-dorico.png" "$ICON_BASE/256x256/apps/torquio-test-dorico.png"
    echo -e "  ${green}✓ Installed torquio-test-dorico.png${reset}"
fi
if [ -f "$FIXTURES_DIR/torquio-sda.png" ]; then
    cp "$FIXTURES_DIR/torquio-sda.png" "$ICON_BASE/256x256/apps/torquio-test-sda.png"
    echo -e "  ${green}✓ Installed torquio-test-sda.png${reset}"
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$ICON_BASE" >/dev/null 2>&1 || true
fi

# Step 2: Generate Unique Test Desktop Entries & MIME Handlers
echo ""
echo -e "${yellow}[2/4] Generating unique test launchers in ~/.local/share/applications/...${reset}"
mkdir -p "$APPS_DIR"

# 1. Torquio TEST Dorico
cat << EOF > "$APPS_DIR/Torquio-Test-Dorico.desktop"
[Desktop Entry]
Name=Torquio TEST Dorico
Comment=Test Launcher for Torquio Desktop Integration
Exec=$WRAPPER_SCRIPT %F
Icon=torquio-test-dorico
Type=Application
Terminal=false
StartupWMClass=torquiotestdorico.exe
Categories=AudioVideo;Audio;
EOF
chmod +x "$APPS_DIR/Torquio-Test-Dorico.desktop"
echo -e "  ${green}✓ Created Torquio-Test-Dorico.desktop${reset}"

# 2. Torquio TEST SDA
cat << EOF > "$APPS_DIR/Torquio-Test-SDA.desktop"
[Desktop Entry]
Name=Torquio TEST SDA
Comment=Test Launcher for Torquio Browser Token Handoff
Exec=$WRAPPER_SCRIPT %u
Icon=torquio-test-sda
Type=Application
Terminal=false
StartupWMClass=torquiotestsda.exe
Categories=AudioVideo;Audio;
MimeType=x-scheme-handler/net-torquio-test-sda;
EOF
chmod +x "$APPS_DIR/Torquio-Test-SDA.desktop"
echo -e "  ${green}✓ Created Torquio-Test-SDA.desktop${reset}"

# Refresh Desktop Database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
fi
touch "$APPS_DIR" >/dev/null 2>&1 || true

# Register Custom Test Protocol Handoff
if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default Torquio-Test-SDA.desktop x-scheme-handler/net-torquio-test-sda 2>/dev/null || true
    echo -e "  ${green}✓ Registered x-scheme-handler/net-torquio-test-sda -> Torquio-Test-SDA.desktop${reset}"
fi

# Step 3: Diagnostics & Syntax Validation
echo ""
echo -e "${yellow}[3/4] Running Diagnostics...${reset}"
if command -v desktop-file-validate >/dev/null 2>&1; then
    echo -n "Checking .desktop syntax validation: "
    ERRS=0
    for dt in "$APPS_DIR/Torquio-Test-Dorico.desktop" "$APPS_DIR/Torquio-Test-SDA.desktop"; do
        if ! desktop-file-validate "$dt" >/dev/null 2>&1; then
            ERRS=$((ERRS + 1))
            echo -e "\n  ${red}Syntax error in $(basename "$dt")${reset}"
        fi
    done
    [ $ERRS -eq 0 ] && echo -e "${green}PASS${reset}"
fi

MIME_STATUS=$(xdg-mime query default x-scheme-handler/net-torquio-test-sda 2>/dev/null || echo "")
echo -n "Checking Test MIME association: "
if [ "$MIME_STATUS" == "Torquio-Test-SDA.desktop" ]; then
    echo -e "${green}PASS (Associated with Torquio-Test-SDA.desktop)${reset}"
else
    echo -e "${red}FAIL (Current: '$MIME_STATUS')${reset}"
fi

# Step 4: Testing Instructions
echo ""
echo -e "${yellow}[4/4] How to verify on your test machine:${reset}"
echo -e "${blue}----------------------------------------------------${reset}"
echo -e "1. SEARCH APP MENU:"
echo -e "   - Open your Start Menu (Mint) or App Grid (Ubuntu) and search for:"
echo -e "     ${green}\"Torquio TEST\"${reset}"
echo -e "   - Verify: Do both test apps appear cleanly with their icons?"
echo ""
echo -e "2. TEST BROWSER HANDOFF:"
echo -e "   - Run this command in terminal to test the URL handoff:"
echo -e "     ${green}xdg-open 'net-torquio-test-sda://token=AUTH_SUCCESS_123'${reset}"
echo -e "   - Verify: Does a GUI dialog or terminal box appear confirming receipt?"
echo -e "   - Log location: ${yellow}~/.local/share/torquio/logs/test_handoff.log${reset}"
echo ""
echo -e "3. CLEANUP WHEN DONE:"
echo -e "   - Run: ${yellow}./scripts/dev/test_desktop_integration.sh --clean${reset}"
echo -e "${blue}----------------------------------------------------${reset}"
