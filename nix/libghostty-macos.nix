# Product static GhosttyLib for macOS (Metal surface goal).
#
# Builds full GhosttyLib (`-Dapp-runtime=none -Demit-lib-vt=false`) with:
# 1. Darwin install of ghostty-internal.a when XCFramework/app emit off
# 2. Prebuilt vendor/Ghostty.metallib (MetalToolchain not in Nix sandbox)
#
# Paint still owned by GhosttyGpu until Wawona swaps the present path
# (docs/METAL-SURFACE.md). This package only proves Zig GhosttyLib links.
{
  lib,
  stdenv,
  zig_0_17,
  pkg-config,
  git,
  xcbuild,
  darwin,
  ghosttySrc,
  callPackage,
}:
assert lib.assertMsg stdenv.hostPlatform.isDarwin
  "libghostty-macos is Darwin-only";
stdenv.mkDerivation (finalAttrs: {
  pname = "libghostty-macos";
  version = "0.1.4-macos";

  src = ghosttySrc;

  patches = [
    ./patches/darwin-install-ghostty-internal-static.patch
    ./patches/prebuilt-metallib-option.patch
    ./patches/sdk14-kCVPixelFormatType_30RGB_r210.patch
  ];

  postPatch = ''
    mkdir -p vendor
    cp -f ${./prebuilt/Ghostty.metallib} vendor/Ghostty.metallib
  '';

  deps = callPackage (ghosttySrc + "/build.zig.zon.nix") {
    name = "${finalAttrs.pname}-cache-${finalAttrs.version}";
  };

  nativeBuildInputs = [
    zig_0_17
    pkg-config
    git
    xcbuild
    darwin.cctools
  ];

  dontConfigure = true;
  dontSetZigDefaultFlags = true;
  doCheck = false;

  zigBuildFlags = [
    "--system"
    "${finalAttrs.deps}"
    "-Dcpu=baseline"
    "-Doptimize=ReleaseFast"
    "-Dapp-runtime=none"
    "-Demit-lib-vt=false"
    "-Demit-xcframework=false"
    "-Demit-macos-app=false"
    "-Demit-docs=false"
    "-Demit-helpgen=false"
    "-Dprebuilt-metallib=true"
  ];

  buildPhase = ''
    runHook preBuild
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR"
    zig build ''${zigBuildFlags[@]}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/include" "$out/share"
    found=""
    for cand in \
      zig-out/lib/libghostty-internal.a \
      zig-out/lib/libghostty.a \
      zig-out/lib/ghostty-internal.a
    do
      if test -f "$cand"; then
        found="$cand"
        break
      fi
    done
    if test -z "$found"; then
      echo "libghostty-macos: no GhosttyLib archive in zig-out" >&2
      find zig-out -type f 2>/dev/null | head -80 >&2 || true
      exit 1
    fi
    if echo "$found" | grep -q 'vt'; then
      echo "libghostty-macos: refusing VT archive $found" >&2
      exit 1
    fi
    size=$(stat -f%z "$found" 2>/dev/null || stat -c%s "$found")
    if test "$size" -lt 1000000; then
      echo "libghostty-macos: archive too small ($size): $found" >&2
      exit 1
    fi
    cp -f "$found" "$out/lib/libghostty-internal.a"
    ln -sf libghostty-internal.a "$out/lib/libghostty.a"
    if test -f zig-out/include/ghostty.h; then
      cp -f zig-out/include/ghostty.h "$out/include/"
    elif test -f include/ghostty.h; then
      cp -f include/ghostty.h "$out/include/"
    fi
    {
      echo "libghostty-macos"
      echo "archive=$found"
      echo "size=$size"
      echo "note=Zig GhosttyLib static. GhosttyGpu still owns Wawona paint until surface swap."
    } > "$out/share/libghostty-macos.txt"
    runHook postInstall
  '';

  meta = {
    description = "GhosttyLib static archive for macOS (Wawona Metal path)";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
})
