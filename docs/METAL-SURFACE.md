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
| Nix GhosttyLib static | `nix build .#libghostty-macos` | Green (~26 MiB `libghostty-internal.a`) |
| Link + draw proof | `nix build .#libghostty-macos-draw-proof` | Green: `ghostty_surface_new` + `draw` |

## Measured inventory

| Attr / artifact | What it is | Metal paint in Wawona UI? |
|-----------------|------------|---------------------------|
| `wwn-ghostty#libghostty-vt` | Upstream VT staticlib (Zig 0.17) | No |
| `wwn-ghostty#libghostty-macos` | GhosttyLib `ghostty-internal.a` (+ `libghostty.a` alias) | Archive yes; **UI still GhosttyGpu** |
| `wwn-ghostty#libghostty-macos-draw-proof` | Separate ObjC binary links archive + draws | Proof only. Not tip |
| `wwn-ghostty#libghostty-macos-probe` | Same flags + `build.log` under `$out` | Evidence |
| `Terminal` `out/macos/libghostty.a` | Alias of `libwawona_terminal.a` (Rust UniFFI) | No (GhosttyGpu paints) |

## ABI gap (why tip cannot dual-link yet)

| Symbol | Rust Terminal (`libwawona_terminal.a`) | Zig GhosttyLib (`libghostty-internal.a`) |
|--------|----------------------------------------|------------------------------------------|
| `ghostty_surface_new` | `(u32 cols, u32 rows)` | `(ghostty_app_t, ghostty_surface_config_s*)` |
| `ghostty_surface_free` | free VT engine | free GhosttyLib surface |
| `ghostty_init` | no-op / VT | full GhosttyLib init |

Same C names. Different signatures. Linking both into `Wawona.app` = duplicate
symbol or wrong ABI at runtime. Product paint swap must:

1. Stop exporting Rust `ghostty_surface_*` (or rename to `wwn_term_*` only).
2. Host `ghostty_app_new` + runtime callbacks + `nsview` in surface config.
3. Call `ghostty_surface_draw` instead of `GhosttyGpuView` atlas.

Until then: tip keeps **GhosttyGpu** (fallback flag
`WAWONA_GHOSTTY_GPU=1` / default on). Draw proof stays a **separate** binary.

## Phase 5 patches (this repo)

1. **`nix/patches/darwin-install-ghostty-internal-static.patch`**
   Lift Darwin skip of `lib_static.install("ghostty-internal.a")` when
   `-Demit-xcframework=false -Demit-macos-app=false`.

2. **`nix/patches/prebuilt-metallib-option.patch`** + **`nix/prebuilt/Ghostty.metallib`**
   Nix sandbox cannot run MetalToolchain. `-Dprebuilt-metallib=true` copies
   `vendor/Ghostty.metallib`.

3. **`nix/patches/sdk14-kCVPixelFormatType_30RGB_r210.patch`**
   Nix `apple-sdk-14.4` lacks `kCVPixelFormatType_30RGB_r210`.

4. **`nix/draw-proof/main.m`** + **`nix/libghostty-macos-draw-proof.nix`**
   Link archive; create NSView; `surface_new` + `draw`.

## Remaining blockers (not Phase 5 product-done)

1. **Wawona tip still GhosttyGpu.** Archive links in draw-proof only.
2. **Full GhosttyLib rejects iOS** (`Config.zig`: only `-Demit-lib-vt`).
3. **Name collision** with Rust UniFFI `libghostty.a` alias.

## Prove (Phase 5 green)

```bash
cd /Users/8amps/Wawona/Ghostty
nix build .#libghostty-macos -L
ls -la result/lib/libghostty-internal.a
nm result/lib/libghostty-internal.a | rg 'T _ghostty_surface_draw' | head
nix build .#libghostty-macos-draw-proof -L
./result/bin/libghostty-macos-draw-proof
# expect: PASS libghostty-macos draw proof
nm -gU result/bin/libghostty-macos-draw-proof | rg 'ghostty_surface_(new|draw)'
```

Until Wawona tip swaps paint: **TermGpu / GhosttyGpu still owns paint.**

## Not this work

- Vision Pro / visionOS dogfood for Terminal
- `/Applications/Wawona.app` or host-cargo `/tmp` overlays
- Further GhosttyGpu UV/Y-flip atlas patches
- Treating Rust UniFFI `libghostty.a` alias as Metal done
