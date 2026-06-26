#!/usr/bin/env bash
# One-time setup of the Pi for building 240-MP from source.
# Run from the Mac: ./tools/pi-setup.sh
set -euo pipefail

PI_HOST="raspi-3b-plus"

ssh "$PI_HOST" 'bash -s' <<'EOF'
set -euo pipefail

echo "==> Installing build dependencies (per BUILDING.md)..."
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake rsync ccache \
  qt6-base-dev qt6-declarative-dev \
  qml6-module-qtquick qml6-module-qtquick-controls \
  qml6-module-qtquick-window \
  libqt6svg6 qt6-svg-dev qt6-svg-plugins qt6-wayland \
  libdrm-dev libxkbcommon-dev libssl-dev \
  libsdl2-dev \
  mpv

echo "==> Ensuring at least 1GB swap for compiling..."
if [ -f /etc/dphys-swapfile ]; then
  current=$(grep -E '^CONF_SWAPSIZE=' /etc/dphys-swapfile | cut -d= -f2)
  if [ "${current:-0}" -lt 1024 ]; then
    sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
    sudo systemctl restart dphys-swapfile
    echo "    swap increased to 1GB"
  else
    echo "    swap already ${current}MB - ok"
  fi
fi

mkdir -p ~/dev/240-MP
echo "==> Pi ready. Dev source dir: ~/dev/240-MP"
EOF
