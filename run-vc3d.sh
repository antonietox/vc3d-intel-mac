#!/usr/bin/env bash
# Start VC3D in Docker and show it on this Mac through XQuartz.
# Quitting VC3D (File > Quit or closing the main window) stops and removes the container.
#
#   ./run-vc3d.sh                    # GUI, 3 GB chunk cache
#   VC3D_CACHE_GB=2 ./run-vc3d.sh    # smaller cache (Macs with 8 GB RAM)
#   VC3D_DATA=~/scrolls ./run-vc3d.sh   # folder visible inside VC3D as /data
#   ./run-vc3d.sh list               # list the bundled vc_* command-line tools
#   ./run-vc3d.sh vc_render_tifxyz --help
set -euo pipefail
IMAGE="${VC3D_IMAGE:-vc3d-intel-mac}"
CACHE_GB="${VC3D_CACHE_GB:-3}"
DATA_DIR="${VC3D_DATA:-$HOME/vc3d-data}"
export PATH="/opt/X11/bin:/usr/local/bin:$PATH"

die() { echo "ERROR: $*" >&2; exit 1; }

docker info >/dev/null 2>&1 || die "Docker is not running. Start Docker Desktop and try again."
docker image inspect "$IMAGE" >/dev/null 2>&1 || die "Image '$IMAGE' not found. Run: docker build -t $IMAGE ."

# Command-line tools need no display.
if [ $# -gt 0 ] && [ "$1" != "VC3D" ]; then
  exec docker run --rm -v "$DATA_DIR:/data" "$IMAGE" "$@"
fi

[ -d /Applications/Utilities/XQuartz.app ] || die "XQuartz not found. Install it: brew install --cask xquartz"
if [ "$(defaults read org.xquartz.X11 nolisten_tcp 2>/dev/null || echo 1)" != "0" ]; then
  die "XQuartz does not accept network clients yet.
  XQuartz > Settings > Security > tick 'Allow connections from network clients',
  then quit XQuartz (Cmd-Q), log out and back in, and run this script again."
fi

open -a XQuartz
for _ in $(seq 1 20); do DISPLAY=:0 xhost >/dev/null 2>&1 && break; sleep 0.5; done
DISPLAY=:0 xhost +localhost >/dev/null || die "Could not talk to XQuartz (xhost failed)."

# A VC3D container left over from an earlier run blocks the name "vc3d".
state=$(docker inspect -f '{{.State.Running}}' vc3d 2>/dev/null || echo none)
[ "$state" = "true" ] && die "VC3D is already running (container 'vc3d'). Quit it first, or: docker stop vc3d"
[ "$state" = "false" ] && docker rm vc3d >/dev/null

mkdir -p "$DATA_DIR"
echo "Starting VC3D (cache ${CACHE_GB} GB, /data = $DATA_DIR) ..."
docker run --rm --name vc3d \
  -e DISPLAY=host.docker.internal:0 \
  --ulimit nofile=750000:750000 \
  -v vc3d-home:/root/.VC3D \
  -v "$DATA_DIR:/data" \
  "$IMAGE" VC3D --cache-size "$CACHE_GB" "${@:2}"
