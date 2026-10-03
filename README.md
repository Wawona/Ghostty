# Ghostty for Wawona

L3′ terminal host. `github.com/Wawona/Ghostty`. Flake input name, when the
Zig tree lands: `wwn-ghostty`.

Wawona does not own libghostty. Every product target gets one terminal grid
for the local shell, SSH, and Relay guest console. The grid is Ghostty.
The bytes come from `wawona-pty` or from Relay `relay_copy_log`.

## Zig stays

Zig 0.16 already names the OS tags Wawona needs:

| Zig OS | Product |
|---|---|
| `ios` | iOS and iPadOS. Deployment target 13.0. Static archive. No product `.dylib`. |
| `tvos` | tvOS. Metal. |
| `visionos` | visionOS. Metal. |
| `watchos` | watchOS. The triple exists. Metal does not. Software grid, SpriteKit present. |
| `macos` | macOS. Metal. |
| `linux` + Android ABI | Android and Linux. OpenGL renderer. Not Metal. |

Do not rewrite libghostty to Rust to reach those tags. A rewrite starts only
if a Zig target triple cannot produce an object file for that OS. The
watchOS limit is the missing Metal framework, not the compiler.

Published GhosttyKit (minimum OS 17) is not an input. Do not rewrite
`LC_BUILD_VERSION` to pretend a 17.0 archive is 13.0.

## What this repo will contain

The Zig libghostty build, the iOS 13 metallib literals, and the static
archive that exports `ghostty_*` only. Rootshell remains the reference for
the iOS Metal host. It is not the Wawona product.

This repository is the boundary. The patched Zig tree moves here after the
iOS 13 archive links. Until then, do not vendor a second copy under `Wawona/`.

## Hosts

Each UI kit owns the view. Ghostty owns the grid. ToolbarKeys owns the keys
above the software keyboard. Relay stays the VM engine.
