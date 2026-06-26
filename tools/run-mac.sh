#!/usr/bin/env bash
# Build and run 240-MP locally on macOS — the fast inner loop.
# Usage:
#   ./tools/run-mac.sh             # build (incremental) + run
#   ./tools/run-mac.sh --run-only  # QML/Lua/asset-only changes: skip the build
#   ./tools/run-mac.sh --no-run    # build, don't launch
set -euo pipefail

BUILD=1
RUN=1
for arg in "$@"; do
  case "$arg" in
    --run-only) BUILD=0 ;;
    --no-run)   RUN=0 ;;
    *) echo "unknown flag: $arg"; exit 1 ;;
  esac
done

cd "$(git rev-parse --show-toplevel)"

if [ "$BUILD" = 1 ]; then
  # First build (no CMake cache yet) needs Homebrew's Qt on the prefix path;
  # after that the cache remembers it and an incremental build is enough.
  if [ ! -f build/CMakeCache.txt ]; then
    echo "==> First build: configuring CMake against Homebrew Qt..."
    cmake -B build -DCMAKE_PREFIX_PATH="$(brew --prefix qt)" .
  fi
  echo "==> Building (incremental)..."
  cmake --build build
fi

if [ "$RUN" = 1 ]; then
  # QML/views/modules/Lua/assets load from disk at runtime via APP_ROOT, so a
  # --run-only relaunch picks those up with no rebuild.
  echo "==> Launching 240-MP (Ctrl-C here, or Cmd-Q, to quit)..."
  APP_ROOT="$PWD" ./build/240mp.app/Contents/MacOS/240mp
fi
