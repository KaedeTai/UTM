#!/bin/bash
# Pack arm64 + x86_64 sysroots into a universal one, add D3DMetal, then build a universal app.
# D3DMetal (Apple Game Porting Toolkit) enables Direct3D 12. It is NOT redistributable:
# install it into the universal sysroot yourself first, e.g.
#   ./scripts/install_d3dmetal.sh sysroot-macOS-arm64_x86_64 <Evaluation environment ...dmg>
# and keep a copy, because pack_dependencies.sh recreates the Frameworks directory.
# Usage: D3DMETAL_FRAMEWORK=/path/to/D3DMetal.framework TEAM=... IDENT=... scripts/neptune/build_universal.sh
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE/../.."
[ -n "$VENV" ] && export PATH="$VENV/bin:$PATH"
./scripts/pack_dependencies.sh . macos arm64 x86_64
if [ -n "$D3DMETAL_FRAMEWORK" ]; then
  rm -rf sysroot-macOS-arm64_x86_64/Frameworks/D3DMetal.framework
  ditto "$D3DMETAL_FRAMEWORK" sysroot-macOS-arm64_x86_64/Frameworks/D3DMetal.framework
else
  echo "warning: D3DMETAL_FRAMEWORK not set; building without Direct3D 12 (DXMT / D3D11 only)" >&2
fi
ARCHS="arm64 x86_64" OUT="${OUT:-out-neptune-universal}" exec "$HERE/build_app.sh"
