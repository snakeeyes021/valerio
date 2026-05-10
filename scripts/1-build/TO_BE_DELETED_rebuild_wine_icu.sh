#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# We already installed libicu-dev:i386 and libicu-dev via apt
echo "Recompiling Wine with native ICU support..."
cd "$VALERIO_BUILD_DIR"

cd wine64
../wine-source/configure --enable-win64
make -j$(nproc)

cd ../wine32
PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig ../wine-source/configure --with-wine64=../wine64
make -j$(nproc)

echo "Installing locally to /opt/wine-custom..."
sudo make install prefix=/opt/wine-custom
cd ../wine64 && sudo make install prefix=/opt/wine-custom

echo "Done rebuilding Wine with ICU!"