#!/bin/bash

# Torquio Mock App Wrapper for Desktop Handoff Testing
LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/torquio/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_handoff.log"

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
ARG_RECEIVED="$1"

echo "[$TIMESTAMP] SUCCESS: Mock Handler invoked with argument: '$ARG_RECEIVED'" >> "$LOG_FILE"

# Display terminal confirmation
echo ""
echo -e "\033[1;32m====================================================\033[0m"
echo -e "\033[1;32m [✓] TORQUIO TEST HANDLER SUCCESSFULLY INVOKED!      \033[0m"
echo -e "\033[1;32m====================================================\033[0m"
echo " Time:     $TIMESTAMP"
echo " Received: ${ARG_RECEIVED:-[No arguments passed]}"
echo " Logged:   $LOG_FILE"
echo -e "\033[1;32m====================================================\033[0m"
echo ""

# Display Desktop GUI Notification if available
MSG="Torquio Test Handler Triggered Successfully!\n\nReceived Argument:\n${ARG_RECEIVED:-[None]}"
if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="Torquio Test Handoff Success" --text="$MSG" --width=350 2>/dev/null &
elif command -v kdialog >/dev/null 2>&1; then
    kdialog --msgbox "$MSG" --title "Torquio Test Handoff Success" 2>/dev/null &
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "Torquio Test Handoff Success" "$ARG_RECEIVED" 2>/dev/null &
fi
