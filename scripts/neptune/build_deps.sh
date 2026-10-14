#!/bin/bash
# Build the macOS dependency sysroot (QEMU, virglrenderer + Neptune, DXMT, ...) for one arch.
# Usage: scripts/neptune/build_deps.sh <arm64|x86_64> [path/to/utm-edition/qemu]
# Homebrew prerequisites: bison, llvm, spirv-llvm-translator, libxrandr, meson, ninja, pkg-config,
# and a python venv with setuptools + distlib on PATH (set VENV=...).
# GNU gawk/awk from Homebrew must NOT be first on PATH (breaks libpng's build); put a
# directory of Homebrew tool symlinks without gawk/awk in TOOLBIN if you need one.
set -e
ARCH="${1:?arch (arm64 or x86_64)}"
QEMU_SRC="${2:-}"
cd "$(dirname "$0")/../.."
P="/usr/bin:/bin:/usr/sbin:/sbin"
[ -n "$TOOLBIN" ] && P="$TOOLBIN:$P" || P="$P:/opt/homebrew/bin"
P="/opt/homebrew/opt/bison/bin:$P"
[ -n "$VENV" ] && P="$VENV/bin:$P"
export PATH="$P"
unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS PKG_CONFIG_PATH CPATH LIBRARY_PATH
export NCPU="${NCPU:-$(sysctl -n hw.ncpu)}"
if [ -n "$QEMU_SRC" ]; then
  ./scripts/build_dependencies.sh -p macos -a "$ARCH" -q "$QEMU_SRC"
else
  ./scripts/build_dependencies.sh -p macos -a "$ARCH"
fi
