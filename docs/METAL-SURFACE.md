# Metal surface blockers (honest)

Goal: macOS (then Apple-mobile) Terminal paints via Zig **libghostty** Metal
(`ghostty_surface_*` / GhosttyLib renderer), not Wawona `GhosttyGpu` / TermGpu
atlas.

## What works today

| Piece | Owner | Status |
|-------|--------|--------|
| VT / cell buffer | upstream `libghostty-vt` via flake input `ghostty` + `Terminal` UniFFI | Shipping in `nix run .#terminal` |
| Glyph / GPU paint | Wawona `GhosttyGpuView` (CoreText stamp + MTL atlas) | **Interim.** Plan forbids more atlas patches |
| PTY / Machines chrome | Wawona L4 | Keep |
| Nix VT package | `nix build .#libghostty-vt` (re-export) | Green on Darwin |
| Nix Metal package | `nix build .#libghostty-macos` | **Fails closed** (intentional) |

## Measured inventory (2026-11-03)

| Attr / artifact | What it is | Metal? |
|-----------------|------------|--------|
| `wwn-ghostty#libghostty-vt` | Upstream VT staticlib (Zig 0.17, pin `521cf2c5`) | No |
| `wwn-ghostty#libghostty-macos` | Stub `runCommand` exit 1 | No |
| `wwn-ghostty#libghostty-macos-probe` | Zig GhosttyLib build attempt + log | Evidence only |
| `Terminal` `out/macos/libghostty.a` | Alias of `libwawona_terminal.a` (Rust UniFFI) | No (GhosttyGpu paints) |
| Ghostty `zig-out/*/libghostty.a` | Same Rust alias / mobile stubs | No |

Upstream `ghostty-org/ghostty` flake packages: **only** `libghostty-vt*`. No
`GhosttyLib` / Metal package.

## Hard blockers (exact)

1. **Upstream flake exports VT only.** Full `GhosttyLib` (`-Dapp-runtime=none`,
   `src/main_c.zig`) is a Zig step, not a flake package Wawona locks today.

2. **Darwin never builds GhosttyLib static into the install graph.** In
   `build.zig` when `app_runtime == .none` and `!emit_lib_vt`,
   `GhosttyLib.initStatic` is constructed, but install is gated:

   ```text
   // We shouldn't have this guard but we don't currently
   // build on macOS this way ironically so we need to fix that.
   if (!config.target.result.os.tag.isDarwin()) {
       lib_static.install("ghostty-internal.a");
   }
   ```

   Because nothing depends on `lib_static.step` on Darwin, Zig never compiles
   GhosttyLib. Measured 2026-11-03 (`nix build .#libghostty-macos-probe`):

   ```text
   EXIT=0
   --- zig-out (non-vt archives) ---
   zig-out/lib/libghostty-vt.a
   zig-out/lib/libghostty-vt.0.1.0.dylib
   --- zig-cache ghostty-internal ---
   (empty)
   PROBE_FAIL: no GhosttyLib static archive in zig-out (VT-only or Darwin skip-install).
   ```

   Log: `docs/evidence/libghostty-macos-probe-2026-11-03.log`.
   Darwin product path today is XCFramework / Xcode (`emit-xcframework`), not
   a lone `libghostty.a`.

3. **Full GhosttyLib rejects iOS.** `Config.zig`:

   ```text
   iOS is not a supported target for the full Ghostty build;
   only libghostty-vt supports iOS (-Demit-lib-vt)
   ```

   Wawona needs static archive at deployment target **13.0**. Published
   GhosttyKit (iOS 17) is forbidden.

4. **Zig pin / ABI split.** Terminal / libghostty-rs uses Zig **0.17** +
   Ghostty `521cf2c5` for VT. Rootshell Metal trees historically used Zig
   **0.16** + GhosttyKit. Do not mix VT and Metal objects from different Zig
   majors in one link.

5. **Name collision.** `scripts/build-static.sh` copies
   `libwawona_terminal.a` to `libghostty.a`. That is **not** Zig GhosttyLib.
   `nix build .#libghostty-macos` must never succeed by shipping that alias.

## Exact next Nix step

```bash
cd /Users/8amps/Wawona/Ghostty

# Fail closed product attr (expected exit 1 today):
nix build .#libghostty-macos

# Capture Zig GhosttyLib attempt + log under result/build.log:
nix build .#libghostty-macos-probe --keep-failed
# or after failure: read the keep-failed store path build.log
```

Minimal patch path (same commit as claiming green):

1. Upstream or Wawona patch: on Darwin, **attach** `lib_static.install(...)`
   (or `b.getInstallStep().dependOn(lib_static.step)`) when
   `-Dapp-runtime=none -Demit-xcframework=false`. Lifting the
   `!isDarwin()` guard is required so Zig actually compiles GhosttyLib.
2. `nix/libghostty-macos.nix`: real `stdenv.mkDerivation` (mirror
   `libghostty-vt.nix` flags minus `-Demit-lib-vt`), install `libghostty.a` +
   trimmed `ghostty_*` headers. Fail if GhosttyKit / iOS 17 markers appear.
3. Prove: `nm` Metal/renderer symbols; host MTKView / CAMetalLayer presents
   without `GhosttyGpuView`.
4. Wawona tip: lazy `-lghostty` + `-Wl,-u,_ghostty_surface_new` (or real
   GhosttyLib embed symbols). Replace `GhosttyGpuView`.
5. Separate iOS 13.0 recipe (upstream forbids full GhosttyLib on iOS today).
6. Delete GhosttyGpu atlas path (plan retire-termgpu).

Until step 4 is green: **TermGpu / GhosttyGpu still owns paint.**
`libghostty-macos fails closed`. Do not claim Metal libghostty is the product
path.

## Not this work

- Vision Pro / visionOS dogfood for Terminal
- `/Applications/Wawona.app` or host-cargo `/tmp` overlays
- Further GhosttyGpu UV/Y-flip atlas patches
- Treating Rust UniFFI `libghostty.a` alias as Metal done
