# Ghostty for Wawona

L3′ terminal grid. `github.com/Wawona/Ghostty`. Flake input name: `wwn-ghostty`.

Wawona does not own libghostty. Every product target gets **one** terminal
grid for the local shell, SSH, and Relay guest console. The grid is Ghostty
(Zig). Bytes come from `wawona-pty` or Relay `relay_copy_log`. Native hosts
(AppKit / UIKit / Compose / GTK / SpriteKit) own chrome only.

Canonical prose: Wawona RAG `ghostty-host.md`, rule `wawona-ghostty-host`.

## Zig stays

Zig OS tags Wawona needs:

| Zig OS | Product |
|---|---|
| `ios` | iOS and iPadOS. Deployment target **13.0**. Static archive. No product `.dylib`. |
| `tvos` | tvOS. Metal when bundled. |
| `visionos` | visionOS. Metal. |
| `watchos` | watchOS. Triple exists. **No** Metal. Software grid, SpriteKit present. |
| `macos` | macOS. Metal. |
| `linux` + Android ABI | Android and Linux. OpenGL. |

Do **not** rewrite libghostty to Rust while those triples emit objects.
Published GhosttyKit (minimum OS 17) is **not** an input. Do not rewrite
`LC_BUILD_VERSION`. Export `ghostty_*` only.

## Credits

- libghostty is Ghostty. Copyright (c) 2024 Mitchell Hashimoto, Ghostty
  contributors. MIT. https://github.com/ghostty-org/ghostty
- iOS embed starting point: Rootshell. Copyright (c) 2026 Rootshell LLC,
  Kit Knox. MIT. Port ideas here; do not link Rootshell as a product dep.
- Toolbar keys: `ToolbarKeys`. Relay stays the VM engine.

## Layout (scaffold)

```text
Ghostty/
  flake.nix           # wwn-ghostty. Re-exports upstream libghostty-vt today.
  docs/METAL-SURFACE.md
  upstream/           # local ghostty-org/ghostty checkout (gitignored / submodule)
```

**Today:** product VT path still goes through Wawona `Terminal` + flake input
`ghostty` (`libghostty-vt`) + native Metal atlas (`GhosttyGpu`). That atlas
is **interim**. Product paint goal is Zig **libghostty** surface (Rootshell
`ghostty_surface_*` / Metal), not TermGpu/GhosttyGpu stamp.

**Next:** Nix-build static `libghostty.a` (full surface, not VT-only) per ABI.
See `docs/METAL-SURFACE.md`.

## Nix

```bash
nix build .#libghostty-vt
# Metal / full surface packages: not green yet (see docs/METAL-SURFACE.md)
```

Wawona consumes this as `inputs.wwn-ghostty` once packages land. Until then
Wawona also keeps `inputs.ghostty` (upstream) for Terminal VT.
