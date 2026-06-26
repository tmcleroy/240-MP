#!/usr/bin/env bash
# Make the Pi BOOT the dev build instead of the installed stable app, so a
# reboot autoruns whatever deploy.sh last built.
#
# It installs a persistent systemd drop-in that overrides the kiosk service's
# ExecStart to point at ~/dev/240-MP/build/240mp (with APP_ROOT). The base
# 240mp.service is left untouched — this is just an override layered on top.
#
# Usage:
#   ./tools/pi-dev-boot.sh on    # reboot autoruns the dev build (default)
#   ./tools/pi-dev-boot.sh off   # restore the stable /usr/local/bin/240mp
set -euo pipefail

PI_HOST="raspi-3b-plus"
PI_DIR="/home/tmcleroy/dev/240-MP"
DROPIN="/etc/systemd/system/240mp.service.d/dev-boot.conf"
MODE="${1:-on}"

case "$MODE" in
  on)
    # Empty ExecStart= first clears the base unit's value (systemd requires
    # that before a replacement); the second line is the dev binary.
    #
    # ExecStopPost= clears the kiosk's `systemctl poweroff` so a dev build that
    # exits or crashes leaves the Pi up and SSH-reachable (the stable kiosk
    # powers the whole Pi off on app exit — undesirable while developing).
    # `pi-dev-boot.sh off` removes this file and restores that behavior.
    ssh "$PI_HOST" "sudo mkdir -p $(dirname "$DROPIN") && sudo tee $DROPIN >/dev/null" <<EOF
[Service]
ExecStart=
ExecStart=$PI_DIR/build/240mp
Environment=APP_ROOT=$PI_DIR
WorkingDirectory=$PI_DIR
ExecStopPost=
EOF
    ssh "$PI_HOST" "sudo systemctl daemon-reload"
    echo "==> Boot now runs the dev build: $PI_DIR/build/240mp"
    echo "    Reboot (or 'ssh $PI_HOST sudo systemctl restart 240mp') to apply."
    ;;
  off)
    ssh "$PI_HOST" "sudo rm -f $DROPIN && sudo systemctl daemon-reload"
    echo "==> Restored stable boot: /usr/local/bin/240mp"
    ;;
  *)
    echo "usage: $0 [on|off]" >&2
    exit 1
    ;;
esac
