# Prebuilt Ghostty.metallib

Nix Darwin sandbox cannot run Apple MetalToolchain (cryptex under
`/private/var/run/com.apple.security.cryptexd`). Upstream `MetallibStep`
calls `/usr/bin/xcrun metal`, which fails with `tool 'metal' not found`.

`Ghostty.metallib` is compiled from upstream
`src/renderer/shaders/shaders.metal` (pin in `flake.lock`) on a host with
MetalToolchain installed, then copied into `vendor/` by the Nix recipe with
`-Dprebuilt-metallib=true`.

## Regenerate (host, once MetalToolchain is installed)

```bash
xcodebuild -downloadComponent MetalToolchain
SRC=$(nix eval --raw .#packages.aarch64-darwin.libghostty-macos.src)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun -sdk macosx metal -c "$SRC/src/renderer/shaders/shaders.metal" \
  -o /tmp/Ghostty.ir -mmacos-version-min=13.0.0
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun -sdk macosx metallib /tmp/Ghostty.ir -o nix/prebuilt/Ghostty.metallib
```

Re-run when bumping the Ghostty input if shaders change.
