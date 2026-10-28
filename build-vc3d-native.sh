#!/usr/bin/env bash
# Native VC3D build for Intel (x86_64) macOS, using a conda-forge environment
# instead of Homebrew (Homebrew no longer ships Intel bottles).
#
# Usage: ./build-vc3d-native.sh configure | build | all
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV="$BASE/env"
SRC="$BASE/villa/volume-cartographer"
BUILD="$BASE/build"

# Only conda + system tools on PATH (no Homebrew in the loop).
export PATH="$ENV/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export SDKROOT="$(xcrun --show-sdk-path)"
export CONDA_BUILD_SYSROOT="$SDKROOT"
export MACOSX_DEPLOYMENT_TARGET=13.3
export PKG_CONFIG_PATH="$ENV/lib/pkgconfig:$ENV/share/pkgconfig"
export CMAKE_PREFIX_PATH="$ENV"

CC="$ENV/bin/x86_64-apple-darwin13.4.0-clang"
CXX="$ENV/bin/x86_64-apple-darwin13.4.0-clang++"

configure() {
  cmake -G Ninja -S "$SRC" -B "$BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_OSX_SYSROOT="$SDKROOT" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.3 \
    -DCMAKE_PREFIX_PATH="$ENV" \
    -DCMAKE_FIND_FRAMEWORK=LAST \
    -DVC_BUILD_FLATBOI=OFF \
    -DVC_TESTING=OFF \
    -DVC_MACOS_MIN_VERSION_OVERRIDE=13.3
}

package() {
  # Self-contained VC3D.app via villa's official MacPackaging.cmake (macdeployqt,
  # install-name rewrite, ad-hoc signing), driven by CPack.
  mkdir -p "$BASE/dist"
  (cd "$BUILD" && cpack --config CPackConfig.cmake -B "$BASE/dist")
  # CPack's DMG also carries a loose bin/ with four tools that are already in the
  # bundle but still point at the build environment. Rebuild the DMG with only
  # VC3D.app + an Applications link.
  local staged name
  staged="$(ls -d "$BASE"/dist/_CPack_Packages/Darwin/DragNDrop/*/ALL_IN_ONE)"
  name="$(basename "$(dirname "$staged")")"
  rm -rf "$BASE/dist/stage" && mkdir -p "$BASE/dist/stage"
  ditto "$staged/VC3D.app" "$BASE/dist/stage/VC3D.app"
  ln -s /Applications "$BASE/dist/stage/Applications"
  # VC3D is GPL-3.0: ship its license, notice and where the source lives.
  cp "$SRC/LICENSE" "$BASE/dist/stage/LICENSE (VC3D, GPL-3.0).txt"
  cp "$SRC/NOTICE" "$BASE/dist/stage/NOTICE (VC3D).txt"
  cat > "$BASE/dist/stage/Source code.txt" <<SRCEOF
VC3D source: https://github.com/ScrollPrize/villa (volume-cartographer),
commit $(git -C "$BASE/villa" rev-parse HEAD)

Build recipe and the small patch applied for this Intel-mac build:
https://github.com/antonietox/vc3d-intel-mac

Bundled third-party libraries come from conda-forge (https://conda-forge.org)
and keep their own licenses.
SRCEOF
  hdiutil create -volname VC3D -srcfolder "$BASE/dist/stage" -fs HFS+ \
    -format UDZO -imagekey zlib-level=9 -ov "$BASE/dist/$name.dmg"
  echo "DMG: $BASE/dist/$name.dmg"
}

build() {
  cmake --build "$BUILD" -j "${JOBS:-$(sysctl -n hw.ncpu)}"
}

case "${1:-all}" in
  configure) configure ;;
  build) build ;;
  package) package ;;
  all) configure && build && package ;;
  *) echo "usage: $0 configure|build|package|all" >&2; exit 2 ;;
esac
