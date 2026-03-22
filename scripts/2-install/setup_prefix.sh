#!/bin/bash
set -e

export WINEPREFIX="$HOME/dev/steinberg-on-linux/dorico-prefix"
export WINE="/opt/wine-custom/bin/wine"
export WINESERVER="/opt/wine-custom/bin/wineserver"
export PATH="/opt/wine-custom/bin:$PATH"

echo "Initializing Wine prefix..."
wineboot -u

echo "Installing winetricks dependencies (this may pop up some windows, please click through them if needed)..."
winetricks -q d3dx9 msls31 allfonts d3dcompiler_43 d3dcompiler_47 vcrun2019 dotnet48 win10

echo "Extracting MediaBay..."
cd "$HOME/dev/steinberg-on-linux"
unzip -o MediaBay_Installer_win64.zip -d MediaBay_extracted
rm -f "MediaBay_extracted/MediaBay 1.3.60/Additional Content/Installer Data/preinstall.ps1"

echo "Done with winetricks and MediaBay extraction!"