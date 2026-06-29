#!/bin/bash

# Torquio Window Class Identifier Tool
# Use this script on Linux Mint or Ubuntu to identify the exact StartupWMClass of any running window.

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
reset='\033[0m'

echo -e "${blue}====================================================${reset}"
echo -e "${blue} Torquio Window Class Detector (StartupWMClass)    ${reset}"
echo -e "${blue}====================================================${reset}"
echo ""

if command -v xprop >/dev/null 2>&1; then
    echo -e "${yellow}Instructions:${reset}"
    echo "1. Your cursor will turn into a crosshair."
    echo "2. Click on the running application window (e.g. real SDA or Dorico)."
    echo ""
    read -p "Press [Enter] to activate crosshair target..." temp
    
    echo ""
    echo -e "${yellow}Click on the window now...${reset}"
    WM_OUTPUT=$(xprop WM_CLASS 2>/dev/null || true)
    
    echo ""
    if [ -n "$WM_OUTPUT" ]; then
        echo -e "${green}Captured Window Class Data:${reset}"
        echo "  $WM_OUTPUT"
        echo ""
        
        # Parse out class strings
        CLASSES=$(echo "$WM_OUTPUT" | grep -o '"[^"]*"' | tr -d '"')
        echo -e "${blue}Recommended StartupWMClass entries for your .desktop file:${reset}"
        for c in $CLASSES; do
            echo -e "  ${green}StartupWMClass=$c${reset}"
        done
    else
        echo -e "${red}Could not capture window class or cancelled.${reset}"
    fi
else
    echo -e "${red}Error: 'xprop' utility not found on this system.${reset}"
    echo "Install xprop via your package manager (e.g. sudo apt install x11-utils)."
fi
echo ""
