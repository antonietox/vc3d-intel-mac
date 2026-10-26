#!/usr/bin/env bash
# Download the newest VC3D Linux x86_64 AppImage from the ScrollPrize/villa
# GitHub releases into this folder (replacing any older one) and print its SHA-256.
# Usage: ./fetch-appimage.sh            -> rolling "latest" release (newest build)
#        ./fetch-appimage.sh stable     -> "stable" release
set -euo pipefail
cd "$(dirname "$0")"
TAG="${1:-latest}"
API="https://api.github.com/repos/ScrollPrize/villa/releases/tags/${TAG}"
URL=$(curl -fsSL "$API" | grep -o '"browser_download_url": *"[^"]*linux-x86_64\.AppImage"' \
      | head -n1 | sed 's/.*"\(https[^"]*\)"/\1/')
[ -n "$URL" ] || { echo "No linux-x86_64 AppImage found in release '$TAG'." >&2; exit 1; }
NAME=$(basename "$URL")
if [ -f "$NAME" ]; then echo "Already have $NAME"; else
  mkdir -p old-appimages
  for f in VC3D-*-linux-x86_64.AppImage; do [ -e "$f" ] && mv "$f" old-appimages/; done
  echo "Downloading $NAME ..."
  curl -fL --progress-bar -o "$NAME.part" "$URL" && mv "$NAME.part" "$NAME"
fi
shasum -a 256 "$NAME"
