#!/usr/bin/env bash
# Download the newest VC3D Linux x86_64 AppImage from the ScrollPrize/villa
# GitHub releases into this folder (replacing any older one) and check its
# SHA-256 against the digest GitHub publishes for the release asset.
# Usage: ./fetch-appimage.sh            -> rolling "latest" release (newest build)
#        ./fetch-appimage.sh stable     -> "stable" release
set -euo pipefail
cd "$(dirname "$0")"
TAG="${1:-latest}"
JSON=$(curl -fsSL "https://api.github.com/repos/ScrollPrize/villa/releases/tags/${TAG}")
URL=$(printf '%s\n' "$JSON" | grep -o '"browser_download_url": *"[^"]*linux-x86_64\.AppImage"' \
      | head -n1 | sed 's/.*"\(https[^"]*\)"/\1/')
[ -n "$URL" ] || { echo "No linux-x86_64 AppImage found in release '$TAG'." >&2; exit 1; }
NAME=$(basename "$URL")
# The asset's "digest" field comes after its "name" field in the API response.
WANT=$(printf '%s\n' "$JSON" | awk -v n="$NAME" '
  /"name":/ { inasset = index($0, "\"" n "\"") > 0 }
  inasset && /"digest":/ { if (match($0, /sha256:[0-9a-f]+/)) { print substr($0, RSTART + 7, RLENGTH - 7); exit } }')
if [ -f "$NAME" ]; then echo "Already have $NAME"; else
  mkdir -p old-appimages
  for f in VC3D-*-linux-x86_64.AppImage; do [ -e "$f" ] && mv "$f" old-appimages/; done
  echo "Downloading $NAME ..."
  curl -fL --progress-bar -o "$NAME.part" "$URL" && mv "$NAME.part" "$NAME"
fi
GOT=$(shasum -a 256 "$NAME" | cut -d' ' -f1)
if [ -z "$WANT" ]; then
  echo "sha256 $GOT (GitHub published no digest to compare with)"
elif [ "$GOT" = "$WANT" ]; then
  echo "sha256 OK $GOT"
else
  echo "sha256 MISMATCH: got $GOT, release says $WANT" >&2
  mv "$NAME" "$NAME.bad"; exit 1
fi
