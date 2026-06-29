#!/bin/bash

# Torquio Mock App Wrapper for Desktop Handoff & Dock Grouping Testing
LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/torquio/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_handoff.log"

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
ARG_RECEIVED="$1"

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

# Display a persistent window so you can observe panel/dock behavior in real-time
MSG="Torquio Test Window is currently RUNNING.\n\nArgument received:\n${ARG_RECEIVED:-[Launched from Menu]}\n\nInspect your panel/dock now to verify icon grouping.\nClose this window when finished testing."

if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="Torquio Test Running Window" --text="$MSG" --width=400 2>/dev/null
elif command -v kdialog >/dev/null 2>&1; then
    kdialog --msgbox "$MSG" --title "Torquio Test Running Window" 2>/dev/null
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "Torquio Test Running" "$ARG_RECEIVED" 2>/dev/null
fi
