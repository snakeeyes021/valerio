#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

INITIAL_INSTALL=false
if [[ "$1" == "--initial" ]]; then
    INITIAL_INSTALL=true
fi

# Ensure hicolor icon theme subdirectories exist
HICOLOR_DIR="$HOME/.local/share/icons/hicolor"
for size in 16x16 22x22 24x24 32x32 48x48 64x64 128x128 256x256; do
    mkdir -p "$HICOLOR_DIR/$size/apps"
done
mkdir -p "$HOME/.local/share/applications"

update_host_icon_cache() {
    if command -v distrobox-host-exec >/dev/null 2>&1; then
        distrobox-host-exec gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" >/dev/null 2>&1 || true
        distrobox-host-exec touch "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
    elif command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" >/dev/null 2>&1 || true
        touch "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
    fi
}

install_multi_res_icons() {
    local source_dir="$1"
    local target_name="$2"

    python3 -c '
import os, sys, glob, struct, shutil
try:
    from PIL import Image
except ImportError:
    Image = None

tmp_dir = sys.argv[1]
icon_name = sys.argv[2]
hicolor_base = sys.argv[3]

target_sizes = [16, 22, 24, 32, 48, 64, 128, 256]
for s in target_sizes:
    os.makedirs(os.path.join(hicolor_base, f"{s}x{s}/apps"), exist_ok=True)

pngs = glob.glob(os.path.join(tmp_dir, "*.png"))
size_map = {}

def get_png_size(filepath):
    try:
        with open(filepath, "rb") as f:
            data = f.read(24)
            if data[:8] == b"\x89PNG\r\n\x1a\n" and data[12:16] == b"IHDR":
                return struct.unpack(">II", data[16:24])
    except Exception:
        pass
    return None

for p in pngs:
    dim = get_png_size(p)
    if dim and dim[0] == dim[1]:
        w = dim[0]
        if w in target_sizes:
            if w not in size_map or os.path.getsize(p) > os.path.getsize(size_map[w]):
                size_map[w] = p

for w, p in size_map.items():
    dest = os.path.join(hicolor_base, f"{w}x{w}/apps", f"{icon_name}.png")
    shutil.copy2(p, dest)

largest_size = max(size_map.keys()) if size_map else None
largest_path = size_map[largest_size] if largest_size else (max(pngs, key=os.path.getsize) if pngs else None)

if largest_path:
    dest_256 = os.path.join(hicolor_base, "256x256/apps", f"{icon_name}.png")
    if not os.path.exists(dest_256):
        shutil.copy2(largest_path, dest_256)

    for s in target_sizes:
        dest = os.path.join(hicolor_base, f"{s}x{s}/apps", f"{icon_name}.png")
        if not os.path.exists(dest):
            if Image:
                try:
                    im = Image.open(largest_path)
                    resample_filter = getattr(Image, "Resampling", Image).LANCZOS
                    im_resized = im.resize((s, s), resample_filter)
                    im_resized.save(dest)
                except Exception:
                    shutil.copy2(largest_path, dest)
            else:
                shutil.copy2(largest_path, dest)
' "$source_dir" "$target_name" "$HICOLOR_DIR"
}

extract_icon() {
    local primary_path="$1"
    local search_pattern="$2"
    local icon_name="$3"
    local extract_project="$4"
    local project_res_id="$5"
    local desktop_name="$6"
    local exe_path=""

    # 1. Try the hardcoded primary path
    if [ -f "$primary_path" ]; then
        exe_path="$primary_path"
    else
        if [ "$INITIAL_INSTALL" = "false" ]; then
            echo "Warning: Hardcoded path not found for $icon_name."
            echo "Initiating fallback search using pattern: $search_pattern..."
        fi
        
        # 2. Fallback search in Program Files and Program Files (x86)
        exe_path=$(find "$TORQUIO_PREFIX_DIR/drive_c/Program Files" "$TORQUIO_PREFIX_DIR/drive_c/Program Files (x86)" -type f -iname "$search_pattern" 2>/dev/null | head -n 1)
        
        if [ -z "$exe_path" ]; then
            if [ "$INITIAL_INSTALL" = "true" ]; then
                echo "Info: $icon_name is not yet installed in the Wine prefix. The launcher and icon will be automatically registered when installed via the Download Assistant."
            else
                echo "Error: Could not locate executable for $icon_name even with fallback search. Skipping."
            fi
            return
        fi
        
        if [ "$INITIAL_INSTALL" = "false" ]; then
            echo "Found fallback executable at: $exe_path"
        fi
    fi
    
    echo "Extracting icons from $exe_path to $icon_name..."
    local tmp_dir=$(mktemp -d)
    
    # Extract all icon resources (group 14)
    wrestool -x -t 14 "$exe_path" -o "$tmp_dir/" 2>/dev/null || true
    
    # Check if anything was extracted
    local ico_file=$(ls "$tmp_dir"/*.ico 2>/dev/null | head -n 1)
    
    if [ -n "$ico_file" ]; then
        # Extract all sizes from the .ico to PNGs
        icotool -x "$ico_file" -o "$tmp_dir/" 2>/dev/null || true
        install_multi_res_icons "$tmp_dir" "$icon_name"
        echo "Successfully installed multi-resolution icons for ${icon_name}"
    else
        echo "No ICO resource found in $exe_path"
    fi
    
    # --- Precision Project Icon Extraction ---
    if [ "$extract_project" == "true" ] && [ -n "$project_res_id" ]; then
        echo "Extracting project icon (ID: $project_res_id) from $exe_path to ${icon_name}-project..."
        local proj_tmp=$(mktemp -d)
        
        # Extract ONLY the specific resource ID
        wrestool -x -t 14 -n "$project_res_id" "$exe_path" -o "$proj_tmp/" 2>/dev/null || true
        
        local proj_ico=$(ls "$proj_tmp"/*.ico 2>/dev/null | head -n 1)
        
        if [ -n "$proj_ico" ]; then
            icotool -x "$proj_ico" -o "$proj_tmp/" 2>/dev/null || true
            install_multi_res_icons "$proj_tmp" "${icon_name}-project"
            echo "Successfully installed multi-resolution icons for ${icon_name}-project"
        else
            echo "No ICO resource found for ID $project_res_id in $exe_path"
        fi
        rm -rf "$proj_tmp"
    fi
    # ----------------------------------------------
    
    rm -rf "$tmp_dir"
    
    # --- Update Host Icon Cache BEFORE Desktop Launcher Registration ---
    update_host_icon_cache
    
    # --- Dynamic Desktop Launcher Registration ---
    if [ -n "$desktop_name" ] && [ -f "$SCRIPT_DIR/../../desktop_stubs/$desktop_name" ]; then
        echo "Registering desktop launcher: $desktop_name..."
        local exe_filename=$(basename "$exe_path")
        sed -e "s|\$HOME|$HOME|g" -e "s|^StartupWMClass=.*|StartupWMClass=$exe_filename|g" "$SCRIPT_DIR/../../desktop_stubs/$desktop_name" > "$HOME/.local/share/applications/$desktop_name"
        
        # Update desktop database for the new launcher
        if command -v distrobox-host-exec >/dev/null 2>&1; then
            distrobox-host-exec update-desktop-database "$HOME/.local/share/applications/" >/dev/null 2>&1 || true
        elif command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$HOME/.local/share/applications/" >/dev/null 2>&1 || true
        fi
    fi
}

echo "Extracting Torquio icons and registering launchers..."

# Dorico
# Variations: dorico.exe, dorico6.exe, Dorico 6.exe
extract_icon \
    "$TORQUIO_PREFIX_DIR/drive_c/Program Files/Steinberg/Dorico6/Dorico6.exe" \
    "*dorico*.exe" \
    "torquio-dorico" \
    "true" \
    "1" \
    "Dorico.desktop"

# SDA
# Variations: Steinberg Download Assistant.exe, SteinbergDownloadAssistant.exe, SDA.exe
extract_icon \
    "$TORQUIO_PREFIX_DIR/drive_c/Program Files (x86)/Steinberg/Download Assistant/Steinberg Download Assistant.exe" \
    "*download*assistant*.exe" \
    "torquio-sda" \
    "false" \
    "" \
    "steinberg-sda-handler.desktop"

# SAM
# Variations: Steinberg Activation Manager.exe, SteinbergActivationManager.exe, SAM.exe
extract_icon \
    "$TORQUIO_PREFIX_DIR/drive_c/Program Files/Steinberg/Activation Manager/SteinbergActivationManager.exe" \
    "*activation*manager*.exe" \
    "torquio-sam" \
    "false" \
    "" \
    "Steinberg Activation Manager.desktop"

# Update icon cache
if command -v distrobox-host-exec >/dev/null 2>&1; then
    distrobox-host-exec gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" >/dev/null 2>&1 || true
elif command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor/" >/dev/null 2>&1 || true
fi

# Force the desktop environment to reload desktop entries to resolve the newly extracted icons
echo "Refreshing desktop database and application launchers..."
if command -v distrobox-host-exec >/dev/null 2>&1; then
    distrobox-host-exec update-desktop-database "$HOME/.local/share/applications/" >/dev/null 2>&1 || true
elif command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications/" >/dev/null 2>&1 || true
fi
touch "$HOME/.local/share/applications" >/dev/null 2>&1 || true
if [ -d "$HOME/.local/share/applications" ]; then
    touch "$HOME/.local/share/applications/"*.desktop >/dev/null 2>&1 || true
fi

echo "Icon extraction complete."
