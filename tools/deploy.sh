#!/usr/bin/env bash
# Sync working tree to the Pi, build, and run.
# Usage:
#   ./tools/deploy.sh              # sync + incremental build + run
#   ./tools/deploy.sh --sync-only  # QML/Lua/asset-only changes: skip build
#   ./tools/deploy.sh --no-run     # sync + build, don't launch
set -euo pipefail

PI_HOST="raspi-3b-plus"
PI_DIR="dev/240-MP"

BUILD=1
RUN=1
for arg in "$@"; do
  case "$arg" in
    --sync-only) BUILD=0 ;;
    --no-run)    RUN=0 ;;
    *) echo "unknown flag: $arg"; exit 1 ;;
  esac
done

cd "$(git rev-parse --show-toplevel)"

echo "==> Syncing source to $PI_HOST:~/$PI_DIR ..."
rsync -az --delete \
  --exclude '.git/' \
  --exclude 'build/' \
  --exclude '.DS_Store' \
  ./ "$PI_HOST:$PI_DIR/"

if [ "$BUILD" = 1 ]; then
  echo "==> Building on the Pi (incremental, -j2)..."
  ssh "$PI_HOST" "cd $PI_DIR && cmake -B build -DCMAKE_CXX_COMPILER_LAUNCHER=ccache && cmake --build build -j2"
fi

if [ "$RUN" = 1 ]; then
  echo "==> Freeing the display: stopping the kiosk service (without its power-off)..."
  # The installed 240mp.service ends with `ExecStopPost=+systemctl poweroff` —
  # the kiosk powers the whole Pi off when the app exits (VCR-style). Stopping
  # it to free the display would therefore shut the Pi down mid-deploy. A
  # transient drop-in in /run clears ExecStopPost just for this boot; it lives
  # on tmpfs, so a reboot restores the normal power-off-on-exit behavior, and
  # the installed unit in /etc is never touched.
  ssh "$PI_HOST" '
    sudo mkdir -p /run/systemd/system/240mp.service.d
    printf "[Service]\nExecStopPost=\n" \
      | sudo tee /run/systemd/system/240mp.service.d/zz-deploy-no-poweroff.conf >/dev/null
    sudo systemctl daemon-reload
    sudo systemctl stop 240mp 2>/dev/null || true
  '

  echo "==> Launching dev build on the Pi (Ctrl-C here to stop it)..."
  # eglfs_kms drives /dev/dri/card0 directly (the deploy user is in the video
  # group); ALWAYS_SET_MODE matches the production service so the CRT lights up.
  ssh -t "$PI_HOST" "
    cd $PI_DIR
    APP_ROOT=\$PWD QT_QPA_PLATFORM=eglfs QT_QPA_EGLFS_ALWAYS_SET_MODE=1 ./build/240mp
  "

  echo '==> Dev build exited; the kiosk service is stopped (CRT is blank).'
  echo "    Restore the production app:  ssh $PI_HOST sudo systemctl start 240mp"
fi
