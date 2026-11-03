# Apple native UI for Wawona Terminal

SwiftUI / UIKit / AppKit views. They call UniFFI `GhosttySurface` /
`TerminalSession` (libghostty-rs). They do not own the VT.

Wawona copies `Terminal/` into `.nix-deps/ghostty/Terminal` (same pattern as
ToolbarKeys `Keyboard/`).
