# Product static GhosttyLib for macOS (Metal surface goal).
#
# FAIL CLOSED until GhosttyLib emits an installable libghostty.a that
# exports Metal surface draw/present (not VT-only, not Rust UniFFI alias).
#
# Measured blockers (2026-11-03, Ghostty 521cf2c5, Zig 0.17):
# 1. Upstream flake packages only libghostty-vt*.
# 2. build.zig GhosttyLib.initStatic runs for -Dapp-runtime=none, but
#    Darwin skips install ("we don't currently build on macOS this way").
# 3. Full GhosttyLib rejects iOS (Config.zig: only -Demit-lib-vt).
# 4. Terminal/scripts/build-static.sh "libghostty.a" is libwawona_terminal.a
#    (Rust UniFFI + GhosttyGpu atlas). Not this package.
#
# Minimal patch path (do not claim green until proven):
# A. Darwin: install lib_static output in build.zig when app_runtime=none
#    (same as non-Darwin ghostty-internal.a path), OR add -Demit-lib-static.
# B. Prove nm shows Metal/renderer symbols + a host can present without
#    GhosttyGpuView.
# C. Separate iOS 13.0 static recipe (upstream forbids full GhosttyLib on
#    iOS; needs Rootshell-style embed port or VT+host Metal until then).
#
# Probe: nix build .#libghostty-macos-probe (captures zig log under $out).
{
  lib,
  stdenv,
  runCommand,
}:
assert lib.assertMsg stdenv.hostPlatform.isDarwin
  "libghostty-macos is Darwin-only";
runCommand "libghostty-macos-unimplemented" { } ''
  cat >&2 <<'EOF'
  wwn-ghostty: packages.libghostty-macos fails closed.

  Metal GhosttyLib static archive is not a Nix package yet.
  GhosttyGpu / TermGpu atlas still owns paint (docs/METAL-SURFACE.md).

  Do not alias Terminal libwawona_terminal.a as this attr.
  Next: nix build .#libghostty-macos-probe for the exact zig log, then
  patch upstream install-on-Darwin (METAL-SURFACE.md minimal patch path).
  EOF
  exit 1
''
