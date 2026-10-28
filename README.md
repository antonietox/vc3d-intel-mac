# VC3D for Intel Macs

A **native** build of **VC3D (Volume Cartographer 3D)**, the [Vesuvius Challenge](https://scrollprize.org) segmentation and annotation viewer, for **Intel (x86_64) Macs**, packaged as a normal drag-to-Applications DMG.

VC3D's official macOS builds are Apple Silicon only. This repo builds the current [villa](https://github.com/ScrollPrize/villa) source on an Intel Mac and packages it with villa's own `MacPackaging.cmake`. No Docker, no XQuartz, no emulation.

![VC3D running natively on an Intel Mac](docs/native-catalog.png)

## Install

1. Download `VC3D-…-macos-x86_64.dmg` from [Releases](../../releases).
2. Open it and drag **VC3D** into **Applications**.
3. First launch: the app is ad-hoc signed, not notarized, so macOS blocks it once.
   - Double-click VC3D, close the warning, then go to **System Settings → Privacy & Security** and click **Open Anyway**.
   - Or, in Terminal: `xattr -dr com.apple.quarantine /Applications/VC3D.app`

The **Open Data Catalog** opens. Type a sample ID (e.g. `1447`), select it and press **Open Sample**. Data streams from the public S3 bucket.

![PHerc1447 opened from S3 in the native build](docs/native-pherc1447.png)

The 51 command-line tools (`vc_render_tifxyz`, `vc_tifxyz2obj`, …) are inside the app:

```bash
/Applications/VC3D.app/Contents/MacOS/vc_render_tifxyz --help
```

### Requirements

- Intel Mac with **AVX2** (Haswell, 2013, or newer)
- **macOS 13.3** (Ventura) or newer

### Recommended settings (VC3D → Settings)

- **RAM cache size:** VC3D defaults to 10 GB. On a 16 GB Mac use about 6 GB; on 8 GB use 2–3 GB.
- **Remote cache path:** downloaded chunks go to `~/.VC3D/remote_cache` by default. If your internal disk is small, point it to an external drive and set a maximum size. Restart VC3D after changing it. macOS then asks once whether VC3D may access files on a removable volume: click **Allow**.

## Tested on

| | |
|---|---|
| Mac | MacBook Pro 15" 2018 (MacBookPro15,1), Intel Core i7-8750H, 16 GB RAM |
| macOS | 15.7.9 Sequoia |
| VC3D | villa `7154682` (2026-10-28) |

Open Data Catalog loads the live sample list; PHerc1447 opens from S3; pan and zoom are smooth.

## Build it yourself

About 45 minutes on the test machine (≈6 min environment, ≈31 min compile, ≈5 min packaging). Needs Xcode Command Line Tools (`xcode-select --install`) and ~6 GB of disk.

**Why not villa's `build_macos.sh`?** It works on Intel in principle, but it takes every dependency from Homebrew, and Homebrew no longer ships Intel bottles: LLVM, Flang, Qt, OpenCV, Boost and GCC would all compile from source (10+ hours). conda-forge still publishes current `osx-64` binaries, so this build uses them.

```bash
git clone https://github.com/antonietox/vc3d-intel-mac && cd vc3d-intel-mac

# 1. micromamba + build environment (≈2.2 GB, conda-forge only)
curl -Ls https://micro.mamba.pm/api/micromamba/osx-64/latest | tar -xj bin/micromamba
MAMBA_ROOT_PREFIX=$PWD/mamba ./bin/micromamba create -y -p $PWD/env -f environment.yml

# 2. villa source (only the folders VC3D needs) + the two small patches
git clone --depth 1 --filter=blob:none --sparse https://github.com/ScrollPrize/villa.git
git -C villa sparse-checkout set volume-cartographer vc_object_store
git -C villa apply ../patches/intel-mac-conda.patch

# 3. configure, compile, package
JOBS=6 ./build-vc3d-native.sh all
# → dist/VC3D-<commit>-<date>-macos-x86_64.dmg
```

`JOBS=6` keeps a 16 GB machine responsive; raise it if you have more RAM.

### What differs from the official macOS build

| | Official (`build_macos.sh`) | This build |
|---|---|---|
| Dependencies | Homebrew | conda-forge (`environment.yml`) |
| Compiler | Homebrew LLVM + lld | conda-forge clang 21 + ld64 |
| `flatboi` | built (needs Fortran, PaStiX) | off, as on Windows |
| `LSMinimumSystemVersion` | build host's macOS | 13.3 (what the dependencies need) |
| DMG contents | `VC3D.app` + loose `bin/` | `VC3D.app` only (the four `bin/` tools are already inside the app) |

The patch (`patches/intel-mac-conda.patch`) only:
- guards two `OpenMP::` alias targets that a conda dependency config already defines;
- adds a `VC_MACOS_MIN_VERSION_OVERRIDE` option to `MacPackaging.cmake`;
- skips the per-file signature of the main `VC3D` executable, which the bundle-level signature covers anyway. On x86_64 the linker doesn't ad-hoc sign the `vc_*` tools (arm64's does), so signing `VC3D` first fails with "code object is not signed at all".

### Known issues

- Panel tab labels at the bottom of the main window are cut off (`ne P`, `er C`…). This happens in the native build too, so it comes from VC3D itself, not from this packaging.
- `libopencv` on conda-forge doesn't pin its abseil version; `environment.yml` pins it (see the comment there).

## Previous version

Until October 2026 this repo ran the Linux AppImage in Docker + XQuartz. That approach is in the git history (`77e9ff5`) if you need it.

## License

MIT for the scripts in this repo. VC3D itself is licensed by its authors; see [villa](https://github.com/ScrollPrize/villa).

Written and tested by Michele Brusemini, with help from an AI assistant.
