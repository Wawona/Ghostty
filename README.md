# libghostty-rs (Wawona Terminal grid)

L3′ flake input: `wwn-ghostty`.

**Wawona Terminal** = **UniFFI Rust (`libghostty-rs`)** + **native UI** on every
host (same split as Wawona domain UniFFI and `ToolbarKeys`).

| Layer | Owner |
|-------|--------|
| Grid / VT / session | Rust UniFFI (`GhosttySurface` / `TerminalSession`) |
| Paint + chrome | Native UI: AppKit, UIKit, SwiftUI, WatchKit/SpriteKit, Jetpack Compose, GTK |
| Bytes | `wawona-pty` / Relay |
| Toolbar keys | `github.com/Wawona/ToolbarKeys` (separate UniFFI) |

## Layout (ToolbarKeys twin)

```text
Ghostty/                    # this repo (product name + packaging)
  include/ghostty.h         # optional C ABI (same Term; not the product contract)
  scripts/build-static.sh
Terminal/                   # sibling: rust crate + native UI trees
  src/                      # UniFFI libghostty-rs (screen + GhosttySurface)
  apple/Terminal/           # SwiftUI / UIKit / AppKit views
  android/…/WawonaTerminalText.kt
```

Wawona stages `apple/Terminal` into `.nix-deps` the same way it stages
`ToolbarKeys/apple/Keyboard`.

## Product contract

1. Rust owns cells, feed, reply, title, paste, pointer, kitty placements.
2. Hosts call **UniFFI** (`GhosttySurface` / `TerminalSession.lines()`).
3. Each OS paints with its native framework. No second VT in Swift/Kotlin.
4. Apple-mobile: static archive, deployment target **13.0**. No GhosttyKit.
5. No product `.dylib` in store IPA.

## Credits

- Name/role: Ghostty MIT (Mitchell Hashimoto et al.)
- iOS embed UX start: Rootshell MIT (Kit Knox)
- VT: this org’s Rust (`Wawona/Terminal`)

Zig under `upstream/` is reference-only. Not the product link line.
