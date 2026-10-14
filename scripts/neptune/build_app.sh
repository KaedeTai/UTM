#!/bin/bash
# Build UTM.app and sign it with an Apple Development identity of your own team.
#
# Why a real team: the sandboxed QEMURenderServer creates POSIX shared memory for
# Neptune/virgl contexts, and inside the App Sandbox shm names must carry the app-group
# prefix ("<TEAM>.com.utmapp.UTM"). An ad-hoc signed build has no app group, so the
# render context fails to initialise and the guest shows "Display output is not active".
#
# Usage: TEAM=XXXXXXXXXX IDENT="Apple Development: you@example.com (YYYYYYYYYY)" \
#        [ARCHS="arm64 x86_64"] [OUT=out-neptune] scripts/neptune/build_app.sh
set -e
: "${TEAM:?set TEAM to your Apple team id}"
: "${IDENT:?set IDENT to your codesign identity}"
ARCHS="${ARCHS:-arm64}"
GROUP="$TEAM.com.utmapp.UTM"
cd "$(dirname "$0")/../.."
OUT="$(mkdir -p "${OUT:-out-neptune}" && cd "${OUT:-out-neptune}" && pwd)"
rm -rf "$OUT/UTM.xcarchive" "$OUT/app" "$OUT/ent"; mkdir -p "$OUT/ent" "$OUT/app"
[ -n "$VENV" ] && export PATH="$VENV/bin:$PATH"
./scripts/build_utm.sh -t "$TEAM" -k macosx -s macOS -a "$ARCHS" -o "$OUT/UTM"
APP="$OUT/app/UTM.app"
cp -a "$OUT/UTM.xcarchive/Products/Applications/UTM.app" "$APP"
for pair in "UTM:Platform/macOS/macOS-unsigned.entitlements" "QEMUHelper:QEMUHelper/QEMUHelper-unsigned.entitlements" \
            "QEMULauncher:QEMULauncher/QEMULauncher-unsigned.entitlements" "QEMURenderServer:QEMURenderServer/QEMURenderServer-unsigned.entitlements" \
            "utmctl:utmctl/utmctl-unsigned.entitlements"; do
  n=${pair%%:*}; f=${pair#*:}
  sed -e "s/\$(TeamIdentifierPrefix)\$(PRODUCT_BUNDLE_PREFIX:default=com.utmapp).UTM/$GROUP/g" \
      -e 's/\$(PRODUCT_BUNDLE_PREFIX:default=com.utmapp)/com.utmapp/g' "$f" > "$OUT/ent/$n.entitlements"
done
sign() { codesign --force --sign "$IDENT" --timestamp=none "$@"; }
H="$APP/Contents/XPCServices/QEMUHelper.xpc/Contents/MacOS"
# D3DMetal.framework (if bundled) keeps the signature it was installed with
find "$APP" -type d -path '*/Frameworks/*.framework' -not -name D3DMetal.framework -exec codesign --force --sign "$IDENT" --timestamp=none {} \;
sign --options runtime --entitlements "$OUT/ent/QEMULauncher.entitlements" "$H/QEMULauncher.app/Contents/MacOS/QEMULauncher"
sign --options runtime --entitlements "$OUT/ent/QEMULauncher.entitlements" "$H/QEMULauncher.app"
sign --options runtime --entitlements "$OUT/ent/QEMURenderServer.entitlements" "$H/QEMURenderServer.app/Contents/MacOS/QEMURenderServer"
sign --options runtime --entitlements "$OUT/ent/QEMURenderServer.entitlements" "$H/QEMURenderServer.app"
sign --options runtime --entitlements "$OUT/ent/QEMUHelper.entitlements" "$APP/Contents/XPCServices/QEMUHelper.xpc"
sign --options runtime --entitlements "$OUT/ent/utmctl.entitlements" "$APP/Contents/MacOS/utmctl"
sign --options runtime --entitlements "$OUT/ent/UTM.entitlements" "$APP"
codesign --verify --deep --strict "$APP"
echo "Built and signed: $APP"
