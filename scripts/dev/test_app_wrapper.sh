#!/bin/bash

# Torquio Mock App Wrapper with Custom WM_CLASS Window Spawning
LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/torquio/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_handoff.log"

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
ARG_RECEIVED="$1"
WM_CLASS_TO_SET="${2:-steinberg download assistant.exe}"

echo "[$TIMESTAMP] SUCCESS: Mock Handler invoked with argument: '$ARG_RECEIVED'" >> "$LOG_FILE"

# Display terminal confirmation if run from shell
if [ -t 1 ]; then
    echo ""
    echo -e "\033[1;32m====================================================\033[0m"
    echo -e "\033[1;32m [✓] TORQUIO TEST HANDLER SUCCESSFULLY INVOKED!      \033[0m"
    echo -e "\033[1;32m====================================================\033[0m"
    echo " Time:     $TIMESTAMP"
    echo " Received: ${ARG_RECEIVED:-[No arguments passed]}"
    echo " Logged:   $LOG_FILE"
    echo -e "\033[1;32m====================================================\033[0m"
    echo ""
fi

# Spawn a running GTK GUI Window with exact WM_CLASS set to test panel/dock grouping
python3 -c '
import sys
wm_class = sys.argv[1]
arg = sys.argv[2] if len(sys.argv) > 2 else ""

try:
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk, GLib
    
    GLib.set_prgname(wm_class)
    win = Gtk.Window(title="Torquio Test Window (" + wm_class + ")")
    win.set_default_size(420, 200)
    win.connect("destroy", Gtk.main_quit)
    
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
    box.set_margin_top(15)
    box.set_margin_bottom(15)
    box.set_margin_start(15)
    box.set_margin_end(15)
    
    lbl1 = Gtk.Label(label="<b>Torquio Test Window is RUNNING</b>")
    lbl1.set_use_markup(True)
    box.pack_start(lbl1, False, False, 0)
    
    lbl2 = Gtk.Label(label="WM_CLASS: " + wm_class + "\nArgument: " + (arg if arg else "[None]"))
    box.pack_start(lbl2, False, False, 0)
    
    lbl3 = Gtk.Label(label="Inspect your panel/dock now to verify icon grouping.\nClose this window when finished testing.")
    box.pack_start(lbl3, False, False, 0)
    
    win.add(box)
    win.show_all()
    Gtk.main()
except Exception as e:
    import subprocess
    msg = "Torquio Test Window Running\nWM_CLASS: " + wm_class + "\n\nInspect your panel/dock now."
    subprocess.run(["zenity", "--info", "--title=Torquio Test Window", "--text=" + msg, "--width=400"], stderr=subprocess.DEVNULL)
' "$WM_CLASS_TO_SET" "$ARG_RECEIVED"
