# Probe: GhosttyLib static on Darwin after Darwin install + prebuilt metallib.
# Captures build.log. Success = non-VT ghostty-internal.a in zig-out.
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
assert stdenv.hostPlatform.isDarwin;
stdenv.mkDerivation (finalAttrs: {
  pname = "libghostty-macos-probe";
  version = "0.1.4-probe";

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
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR" "$out"
    set +e
    zig build ''${zigBuildFlags[@]} 2>&1 | tee "$out/build.log"
    rc=''${PIPESTATUS[0]}
    set -e
    echo "EXIT=$rc" | tee -a "$out/build.log"
    {
      echo "--- zig-out archives ---"
      find zig-out -type f \( -name '*.a' -o -name '*.dylib' \) -exec ls -la {} \; 2>/dev/null | head -80 || true
      echo "--- zig-cache ghostty-internal ---"
      find .zig-cache -name '*ghostty-internal*' 2>/dev/null | head -40 || true
      echo "--- zig-cache libghostty (exclude vt) ---"
      find .zig-cache -name 'libghostty*.a' ! -name '*vt*' 2>/dev/null | head -40 || true
    } | tee -a "$out/build.log"

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
      echo "PROBE_FAIL: no GhosttyLib static archive in zig-out." | tee -a "$out/build.log"
      exit 1
    fi
    if echo "$found" | grep -q 'vt'; then
      echo "PROBE_FAIL: matched VT archive $found" | tee -a "$out/build.log"
      exit 1
    fi
    size=$(stat -f%z "$found" 2>/dev/null || stat -c%s "$found")
    echo "PROBE_OK: $found size=$size" | tee -a "$out/build.log"
    if test "$size" -lt 1000000; then
      echo "PROBE_FAIL: archive too small ($size bytes); likely incomplete." | tee -a "$out/build.log"
      exit 1
    fi
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/include"
    for cand in \
      zig-out/lib/libghostty-internal.a \
      zig-out/lib/libghostty.a \
      zig-out/lib/ghostty-internal.a
    do
      if test -f "$cand"; then
        cp -f "$cand" "$out/lib/libghostty-internal.a"
        break
      fi
    done
    test -f "$out/lib/libghostty-internal.a"
    if test -f zig-out/include/ghostty.h; then
      cp -f zig-out/include/ghostty.h "$out/include/"
    elif test -f include/ghostty.h; then
      cp -f include/ghostty.h "$out/include/"
    fi
    runHook postInstall
  '';
})
