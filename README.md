# Wawona Ghostty (libghostty)

L3′ terminal **grid** for Wawona Terminal. Flake input: `wwn-ghostty`.

**Wawona Terminal** = Wawona native UI chrome (windows, PTY, Machines,
ToolbarKeys) + **Rust libghostty** grid. One surface for local shell, SSH,
and the Relay guest console on macOS, iOS, iPadOS, tvOS, watchOS, visionOS,
Android, and Linux.

## Product shape

| Item | Rule |
|------|------|
| Language | **Rust** (`staticlib` `libghostty.a`) |
| Exports | `ghostty_*` only (C ABI for Swift / JNI / GTK) |
| VT | `wawona-terminal` (`github.com/Wawona/Terminal`) |
| Apple-mobile min OS | **13.0** |
| Store IPA | No product `.dylib`. No published GhosttyKit (iOS 17) |
| watchOS | Software cells → SpriteKit (no Metal) |
| Android / Linux | Host OpenGL / GTK paints cells |

Zig upstream under `upstream/` is reference-only (Rootshell / Ghostty MIT).
Product paint path is this Rust crate. Do not link Zig objects into Wawona.

## Build

```bash
./scripts/build-static.sh macos
./scripts/build-static.sh ios
./scripts/build-static.sh ios-sim
# also: tvos, visionos, watchos, android, linux, linux-x86_64, macos-x86_64
```

Outputs: `zig-out/<abi>/libghostty.a` + `include/ghostty.h` (path kept for
Wawona staging; artifact is Rust).

## Credits

- Name and terminal-host role inspired by Ghostty. Copyright (c) 2024
  Mitchell Hashimoto, Ghostty contributors. MIT.
- iOS embed UX starting point: Rootshell. Copyright (c) 2026 Rootshell LLC,
  Kit Knox. MIT.
- VT screen: `github.com/Wawona/Terminal` (MIT).

Toolbar keys: `github.com/Wawona/ToolbarKeys`. Relay stays the VM engine.

## Hard rejects

- Linking published GhosttyKit XCFramework into store IPA
- Raising Wawona's iOS floor for this archive
- Shipping a product Ghostty `.dylib` on Apple-mobile
- A second permanent VT paint engine beside this grid (no TermGpu atlas)
