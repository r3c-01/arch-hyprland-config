#!/bin/sh
# Bring an existing Control Center to the monitor page, or open it there.
cc="$HOME/.config/quickshell-control"
if qs -p "$cc" ipc call barSystemMonitor open >/dev/null 2>&1; then
    exit 0
fi
QS_START_MONITOR=1 exec qs -p "$cc"
