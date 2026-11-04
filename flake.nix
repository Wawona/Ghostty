{
  description = "Wawona Ghostty L3′ (wwn-ghostty). Zig libghostty static archives.";

  nixConfig = {
    extra-substituters = [ "https://ghostty.cachix.org" ];
    extra-trusted-public-keys = [
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Upstream Ghostty. Same pin Wawona Terminal uses for libghostty-vt.
    # Full Metal libghostty is a separate recipe (docs/METAL-SURFACE.md).
    ghostty.url = "github:ghostty-org/ghostty/521cf2c5d30bd48028ca61546c64e7913764073d";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ghostty,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        libghosttyVt = ghostty.packages.${system}.libghostty-vt;
        # Same locked Ghostty tree as inputs.ghostty (full source, not vt fileset).
        ghosttySrc =
          let
            lock = builtins.fromJSON (builtins.readFile ./flake.lock);
            g = lock.nodes.ghostty.locked;
          in
          builtins.fetchTree {
            type = g.type;
            owner = g.owner;
            repo = g.repo;
            rev = g.rev;
          };
        libghosttyMacos =
          if pkgs.stdenv.hostPlatform.isDarwin then
            pkgs.callPackage ./nix/libghostty-macos.nix {
              inherit ghosttySrc;
            }
          else
            null;
        libghosttyMacosProbe =
          if pkgs.stdenv.hostPlatform.isDarwin then
            pkgs.callPackage ./nix/libghostty-macos-probe.nix {
              inherit ghosttySrc;
            }
          else
            null;
        libghosttyMacosDrawProof =
          if pkgs.stdenv.hostPlatform.isDarwin then
            pkgs.callPackage ./nix/libghostty-macos-draw-proof.nix {
              libghosttyMacos = libghosttyMacos;
            }
          else
            null;
      in
      {
        packages = {
          default = libghosttyVt;
          # Available today: VT archive only (no Metal paint).
          libghostty-vt = libghosttyVt;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          # Real GhosttyLib static (Darwin install patch). Paint still GhosttyGpu.
          libghostty-macos = libghosttyMacos;
          # Zig probe: same flags + build.log under $out.
          libghostty-macos-probe = libghosttyMacosProbe;
          # Link + ghostty_surface_draw against NSView. Separate from tip.
          libghostty-macos-draw-proof = libghosttyMacosDrawProof;
        };

        apps = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          libghostty-macos-draw-proof = {
            type = "app";
            program = "${libghosttyMacosDrawProof}/bin/libghostty-macos-draw-proof";
          };
        };

        # Doc + patch + prebuilt metallib + draw-proof source. GhosttyGpu still paint.
        checks.metal-surface-doc = pkgs.runCommand "wwn-ghostty-metal-doc" { } ''
          test -f ${./docs/METAL-SURFACE.md}
          grep -q 'TermGpu / GhosttyGpu still owns paint' ${./docs/METAL-SURFACE.md}
          grep -q 'ABI gap' ${./docs/METAL-SURFACE.md}
          test -f ${./nix/libghostty-macos.nix}
          test -f ${./nix/libghostty-macos-draw-proof.nix}
          test -f ${./nix/draw-proof/main.m}
          test -f ${./nix/patches/darwin-install-ghostty-internal-static.patch}
          test -f ${./nix/patches/prebuilt-metallib-option.patch}
          test -f ${./nix/patches/sdk14-kCVPixelFormatType_30RGB_r210.patch}
          test -f ${./nix/prebuilt/Ghostty.metallib}
          grep -q 'lib_static.install("ghostty-internal.a")' \
            ${./nix/patches/darwin-install-ghostty-internal-static.patch}
          grep -q 'prebuilt-metallib' ${./nix/patches/prebuilt-metallib-option.patch}
          grep -q '30RGB_r210' ${./nix/patches/sdk14-kCVPixelFormatType_30RGB_r210.patch}
          touch $out
        '';
      }
    );
}
