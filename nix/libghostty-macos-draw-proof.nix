# Link + one draw of Zig GhosttyLib against an NSView.
# Separate binary: cannot dual-link into Wawona tip with Rust
# libwawona_terminal.a (same `ghostty_surface_*` names, different ABI).
{
  lib,
  stdenv,
  libghosttyMacos,
  zlib,
  bzip2,
}:
assert lib.assertMsg stdenv.hostPlatform.isDarwin
  "libghostty-macos-draw-proof is Darwin-only";
stdenv.mkDerivation {
  pname = "libghostty-macos-draw-proof";
  version = libghosttyMacos.version or "0.1.4-macos";

  dontUnpack = true;

  buildInputs = [
    libghosttyMacos
    zlib
    bzip2
  ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $TMPDIR/bin
    $CC -ObjC -fobjc-arc -o $TMPDIR/bin/libghostty-macos-draw-proof \
      ${./draw-proof/main.m} \
      -I${libghosttyMacos}/include \
      ${libghosttyMacos}/lib/libghostty-internal.a \
      -framework Foundation -framework AppKit -framework Metal -framework MetalKit \
      -framework QuartzCore -framework CoreText -framework CoreGraphics \
      -framework CoreFoundation -framework IOKit -framework Security \
      -framework UniformTypeIdentifiers -framework CoreVideo -framework CoreImage \
      -framework Carbon -framework GameController -framework IOSurface \
      -framework SystemConfiguration -framework Network \
      -lc++ -lz -lbz2
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share
    cp -f $TMPDIR/bin/libghostty-macos-draw-proof $out/bin/
    {
      echo "libghostty-macos-draw-proof"
      echo "linked=${libghosttyMacos}"
      echo "note=Calls ghostty_surface_new + ghostty_surface_draw. Product tip still GhosttyGpu."
    } > $out/share/libghostty-macos-draw-proof.txt
    # Fail closed: binary must export draw (write nm out first; avoid SIGPIPE).
    nm -gU $out/bin/libghostty-macos-draw-proof > $TMPDIR/syms.txt
    grep 'T _ghostty_surface_draw' $TMPDIR/syms.txt
    grep 'T _ghostty_surface_new' $TMPDIR/syms.txt
    grep 'T _ghostty_app_new' $TMPDIR/syms.txt
    runHook postInstall
  '';

  meta = {
    description = "Link + draw proof for wwn-ghostty#libghostty-macos";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "libghostty-macos-draw-proof";
  };
}
