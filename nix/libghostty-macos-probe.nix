# Probe only. Captures whether upstream GhosttyLib (app-runtime=none,
# emit-lib-vt=false) emits an installable *non-VT* static archive on Darwin.
#
# Product path is packages.libghostty-macos (fails closed until this probe
# is green and Metal surface symbols exist). Do not treat Rust UniFFI
# alias or libghostty-vt.a as success.
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
  version = "0.1.1-probe";

  src = ghosttySrc;

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

  # Full GhosttyLib path. Disable VT-only mode, xcframework, app, docs.
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
      echo "--- zig-out (non-vt archives) ---"
      find zig-out -type f \( -name '*.a' -o -name '*.dylib' \) 2>/dev/null | head -80 || true
      echo "--- zig-cache ghostty-internal ---"
      find .zig-cache -name '*ghostty-internal*' 2>/dev/null | head -40 || true
      echo "--- zig-cache libghostty (exclude vt) ---"
      find .zig-cache -name 'libghostty*.a' ! -name '*vt*' 2>/dev/null | head -40 || true
    } | tee -a "$out/build.log"

    # Success only if a non-VT GhosttyLib archive lands in zig-out.
    # libghostty-vt.a always appears and must not count.
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
      echo "PROBE_FAIL: no GhosttyLib static archive in zig-out (VT-only or Darwin skip-install)." | tee -a "$out/build.log"
      echo "See docs/METAL-SURFACE.md: Darwin build.zig skips lib_static.install." | tee -a "$out/build.log"
      exit 1
    fi
    # Reject accidental VT rename
    if echo "$found" | grep -q 'vt'; then
      echo "PROBE_FAIL: matched VT archive $found" | tee -a "$out/build.log"
      exit 1
    fi
    echo "PROBE_OK: $found" | tee -a "$out/build.log"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/include"
    cp -f zig-out/lib/libghostty-internal.a "$out/lib/" 2>/dev/null || \
      cp -f zig-out/lib/libghostty.a "$out/lib/"
    runHook postInstall
  '';
})
