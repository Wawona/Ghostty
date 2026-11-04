# Metal surface blockers (honest)

Goal: macOS (then Apple-mobile) Terminal paints via Zig **libghostty** Metal
(`ghostty_surface_*`), not Wawona `GhosttyGpu` / TermGpu atlas.

## What works today

| Piece | Owner | Status |
|-------|--------|--------|
| VT / cell buffer | upstream `libghostty-vt` via flake input `ghostty` + `Terminal` UniFFI | Shipping in `nix run .#terminal` |
| Glyph / GPU paint | Wawona `GhosttyGpuView` (CoreText stamp + MTL atlas) | **Interim.** Plan forbids more atlas patches |
| PTY / Machines chrome | Wawona L4 | Keep |

## What is missing for product Metal

1. **Upstream flake exports VT only.**
   `ghostty-org/ghostty` flake packages are `libghostty-vt*`. Full
   `GhosttyLib` (runtime `none`, Metal internal embed API) is a Zig build
   step, not a flake package Wawona locks today.

2. **Rootshell GhosttyKit ≠ store input.**
   `vendor/rootshell/scripts/build-framework.sh` builds
   `GhosttyKit{AppStore,Standalone}.xcframework` with **Zig 0.16**,
   `-Dxcframework-target=rootshell_*`, iOS **17** platforms in Package.swift.
   Wawona forbids published GhosttyKit and the 17.0 floor. Need a **static
   archive** recipe at deployment target **13.0**, export `ghostty_*` only.

3. **Zig pin split.**
   Terminal / libghostty-rs pin uses Zig **0.17** + Ghostty commit
   `521cf2c5…` for VT. Rootshell Metal tree still expects Zig **0.16**.
   Metal scaffold must pick one tree and document it; do not mix VT and
   Metal objects from different Zig majors in one link.

4. **No Wawona host view yet.**
   `WWNTermSurface` / standalone still host `GhosttyGpuView`. Swap only after
   `libghostty.a` links and `ghostty_surface_*` draw/present works under
   AppKit.

## Exact next Nix step

From `Wawona/Ghostty` (this repo), on macOS:

```bash
# 1) Pin a Ghostty Zig tree that can emit GhosttyLib static (see Rootshell
#    build-framework flags; prefer archive, not xcframework).
# 2) Add nix/libghostty.nix that runs:
#      zig build -Doptimize=ReleaseFast   # GhosttyLib.initStatic path
#    install libghostty.a + ghostty.h (internal embed headers trimmed to
#    ghostty_*). Fail closed if GhosttyKit / iOS 17 markers appear.
# 3) packages.libghostty-macos = that derivation.
# 4) Wawona tip: OTHER_LDFLAGS lazy -lghostty + -Wl,-u,_ghostty_surface_new
#    (or equivalent). Replace GhosttyGpuView with MTKView / CAMetalLayer
#    attached to ghostty_surface.
# 5) Prove: nix run .#terminal (or tip Wawona) readable font, keys, resize.
# 6) Delete GhosttyGpu atlas path (plan retire-termgpu).
```

Until step 4 is green: **TermGpu / GhosttyGpu still owns paint.** Do not
claim Metal libghostty is the product path.

## Not this work

- Vision Pro / visionOS dogfood for Terminal
- `/Applications/Wawona.app` or host-cargo `/tmp` overlays
- Further GhosttyGpu UV/Y-flip atlas patches
