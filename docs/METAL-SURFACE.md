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
| Nix GhosttyLib static | `nix build .#libghostty-macos` | **Phase 5:** real archive (install + prebuilt metallib) |

## Measured inventory

| Attr / artifact | What it is | Metal paint in Wawona UI? |
|-----------------|------------|---------------------------|
| `wwn-ghostty#libghostty-vt` | Upstream VT staticlib (Zig 0.17) | No |
| `wwn-ghostty#libghostty-macos` | GhosttyLib `ghostty-internal.a` (+ `libghostty.a` alias) | Archive yes; **UI still GhosttyGpu** |
| `wwn-ghostty#libghostty-macos-probe` | Same flags + `build.log` under `$out` | Evidence |
| `Terminal` `out/macos/libghostty.a` | Alias of `libwawona_terminal.a` (Rust UniFFI) | No (GhosttyGpu paints) |

## Phase 5 patches (this repo)

1. **`nix/patches/darwin-install-ghostty-internal-static.patch`**
   Lift Darwin skip of `lib_static.install("ghostty-internal.a")` when
   `-Demit-xcframework=false -Demit-macos-app=false`. Without this, Zig never
   compiles GhosttyLib on Darwin (`app-runtime=none`).

2. **`nix/patches/prebuilt-metallib-option.patch`** + **`nix/prebuilt/Ghostty.metallib`**
   Nix sandbox cannot run MetalToolchain (`xcrun metal` → tool not found;
   cryptex). `-Dprebuilt-metallib=true` copies `vendor/Ghostty.metallib`.
   Regenerate: `nix/prebuilt/README.md` (needs
   `xcodebuild -downloadComponent MetalToolchain` on the host once).

3. **`nix/patches/sdk14-kCVPixelFormatType_30RGB_r210.patch`**
   Nix `apple-sdk-14.4` lacks `kCVPixelFormatType_30RGB_r210` (macOS 15+).
   Patch hardcodes FourCC `'r210'`.

## Remaining blockers (not Phase 5 done)

1. **Wawona UI still GhosttyGpu.** Do not claim Metal surface wired until tip
   links `-lghostty` / `ghostty_surface_*` and retires atlas paint.
2. **Full GhosttyLib rejects iOS** (`Config.zig`: only `-Demit-lib-vt`).
   Separate iOS 13.0 recipe later.
3. **Name collision.** Terminal `scripts/build-static.sh` `libghostty.a` is
   still Rust UniFFI alias. Product Zig archive is
   `wwn-ghostty#libghostty-macos`.

## Prove (Phase 5 green)

```bash
cd /Users/8amps/Wawona/Ghostty
nix build .#libghostty-macos -L
ls -la result/lib/libghostty-internal.a result/lib/libghostty.a
# Measured 2026-11-03: ~26 MiB stripped archive (pre-strip fat ~144 MiB).
# VT-only libghostty-vt.a is ~11 MiB. GhosttyLib is larger than VT-only.
nm result/lib/libghostty-internal.a | rg 'T _ghostty_' | head
```

Evidence: `docs/evidence/libghostty-macos-phase5-proof.txt`.

Until Wawona tip swaps paint: **TermGpu / GhosttyGpu still owns paint.**

## Not this work

- Vision Pro / visionOS dogfood for Terminal
- `/Applications/Wawona.app` or host-cargo `/tmp` overlays
- Further GhosttyGpu UV/Y-flip atlas patches
- Treating Rust UniFFI `libghostty.a` alias as Metal done
