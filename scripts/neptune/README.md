# UTM + Neptune (Direct3D 11/12 for Windows ARM guests) — build notes

This branch builds UTM with the newest Neptune host stack so a Windows 11 ARM guest gets
hardware Direct3D through `virtio-gpu-gl-pci,blob=true,venus=true,neptune=true`.

## What is changed on this branch

* `patches/sources` – newer host pieces:
  * virglrenderer `678274064c2c` (Neptune wire protocol v2)
  * DXMT `917b721c0f91` (D3D11 → Metal, native arm64)
  * d3dmetal-native `c31fbbf68890` (glue for Apple's D3DMetal, enables D3D12)
* `QEMURenderServer` gets `LSBackgroundOnly = YES`. Every Neptune context is a separate
  render-server worker process; without this flag each one shows up in the Dock and is
  reported as "Not Responding" because it never runs an AppKit event loop.
* `scripts/neptune/` – helper scripts (below).

QEMU: use `utmapp/qemu` branch `utm-edition` (tested at 88e5ee7).

## Build

```sh
# 1. dependencies (repeat with x86_64 if you want D3D12 via D3DMetal, which is x86_64-only)
scripts/neptune/build_deps.sh arm64  ~/src/qemu
scripts/neptune/build_deps.sh x86_64 ~/src/qemu        # optional

# 2a. arm64 app (D3D11 via DXMT only)
TEAM=XXXXXXXXXX IDENT="Apple Development: you@example.com (YYYYYYYYYY)" scripts/neptune/build_app.sh

# 2b. or universal app with D3DMetal (D3D11 + D3D12)
#     install D3DMetal from Apple's "Evaluation environment for Windows games" dmg yourself;
#     it is licensed for evaluation only and must not be redistributed.
./scripts/install_d3dmetal.sh sysroot-macOS-arm64_x86_64 ~/Downloads/Evaluation_environment_for_Windows_games_*.dmg
ditto sysroot-macOS-arm64_x86_64/Frameworks/D3DMetal.framework ~/D3DMetal-utm.framework
D3DMETAL_FRAMEWORK=~/D3DMetal-utm.framework TEAM=... IDENT=... scripts/neptune/build_universal.sh
```

The app must be signed with a real Apple Development identity (any free/paid team): the
sandboxed render server needs the `<TEAM>.com.utmapp.UTM` app group for its shared memory.
Ad-hoc builds start the VM but the guest display stays at "Display output is not active".

In the VM settings pick the virtio-gpu-gl display; "DirectX Driver" chooses DXMT or D3DMetal
(default: D3DMetal when bundled).

## Windows guest driver

Build the viogpu3d KMD + Neptune UMD (ARM64X) from `osy/kvm-guest-drivers-windows` and
`osy/virtio-win-mesa` (`staging/neptune`), test-sign it, and install with test signing enabled
(Secure Boot off). The UMD version must equal the INF `DriverVer`.

## Known issues

* Occasional `hvf_vcpu_exec` assertion in QEMU under heavy load (not investigated yet).
* Some newer optional DXMT exports (e.g. `dxmt_shared_handle_close`) are not used by the UMD yet.
