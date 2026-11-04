# Metal surface blockers (honest)

Goal: macOS (then Apple-mobile) Terminal paints via Zig **libghostty** Metal
(`ghostty_surface_*` / GhosttyLib renderer), not Wawona `GhosttyGpu` / TermGpu
atlas.

## What works today

| Piece | Owner | Status |
|-------|--------|--------|
| VT / cell buffer | upstream `libghostty-vt` via flake input `ghostty` + `Terminal` UniFFI | Shipping in `nix run .#terminal` |
| Glyph / GPU paint | `GhosttySurfaceHost`: Zig `ghostty_surface_draw` when `WAWONA_LINK_LIBGHOSTTY=1`; else `GhosttyGpuView` atlas | Zig path opt-in. Atlas **fallback**, not retired |
| PTY / Machines chrome | Wawona L4 | Keep |
| Nix VT package | `nix build .#libghostty-vt` (re-export) | Green on Darwin |
| Nix GhosttyLib static | `nix build .#libghostty-macos` | Green (~26 MiB `libghostty-internal.a`) |
| Link + draw proof | `nix build .#libghostty-macos-draw-proof` | Green: `ghostty_surface_new` + `draw` |

## Measured inventory

| Attr / artifact | What it is | Metal paint in Wawona UI? |
|-----------------|------------|---------------------------|
| `wwn-ghostty#libghostty-vt` | Upstream VT staticlib (Zig 0.17) | No |
| `wwn-ghostty#libghostty-macos` | GhosttyLib `ghostty-internal.a` (+ `libghostty.a` alias) | Tip `WAWONA_LINK_LIBGHOSTTY=1` → `GhosttySurfaceHost` Zig paint |
| `wwn-ghostty#libghostty-macos-draw-proof` | Separate ObjC binary links archive + draws | Proof only. Not tip |
| `wwn-ghostty#libghostty-macos-probe` | Same flags + `build.log` under `$out` | Evidence |
| `Terminal` `out/macos/libghostty.a` | Alias of `libwawona_terminal.a` (Rust UniFFI) | No (GhosttyGpu paints) |

## ABI rename (Phase 5 done)

| Role | Symbols | Archive |
|------|---------|---------|
| Rust VT (tip paint path) | `wwn_term_*` only | `libwawona_terminal.a` / in `libwawona.a` |
| Zig GhosttyLib (Metal) | `ghostty_surface_*` / `ghostty_init` | `libghostty-internal.a` |

Rust no longer exports `ghostty_surface_*`. Tip may dual-link Zig archive
(`WAWONA_LINK_LIBGHOSTTY=1`) without duplicate symbols. Phase 5 paint slice:

1. `GhosttySurfaceHost` + C bridge: `ghostty_app_new` + `nsview` +
   `ghostty_surface_draw` when flag on.
2. Flag off / archive missing: **GhosttyGpu** atlas fallback (not retired).
3. Gap: Zig surface owns its own shell PTY. Machines `wwn_term_*` feed is
   not yet the Zig paint source. Unified PTY remains follow-up.

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

1. **PTY unify.** Zig paint path runs GhosttyLib shell, not Machines `wwn_term_*` bytes.
2. **Full GhosttyLib rejects iOS** (`Config.zig`: only `-Demit-lib-vt`).
3. ~~Name collision~~ Phase 5: Rust VT is `wwn_term_*`. Alias `libghostty.a` still not Metal.
4. **GhosttyGpu not retired.** Default tip (flag off) still atlas.

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

Default tip (no flag): **GhosttyGpu owns paint.** Flag on: Zig
`GhosttySurfaceHost`. GhosttyGpu not retired.

## Not this work

- Vision Pro / visionOS dogfood for Terminal
- `/Applications/Wawona.app` or host-cargo `/tmp` overlays
- Further GhosttyGpu UV/Y-flip atlas patches
- Treating Rust UniFFI `libghostty.a` alias as Metal done
