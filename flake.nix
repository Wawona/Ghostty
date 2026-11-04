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
      in
      {
        packages = {
          default = libghosttyVt;
          # Available today: VT archive only (no Metal paint).
          libghostty-vt = libghosttyVt;
          # Planned: full surface staticlib for macOS / ios / …
          # libghostty-macos = …;  see docs/METAL-SURFACE.md
        };

        # Fail closed until Metal recipe exists. Agents must not invent a
        # stub .a and call GhosttyGpu retired.
        checks.metal-surface-doc = pkgs.runCommand "wwn-ghostty-metal-doc" { } ''
          test -f ${./docs/METAL-SURFACE.md}
          grep -q 'TermGpu / GhosttyGpu still owns paint' ${./docs/METAL-SURFACE.md}
          touch $out
        '';
      }
    );
}
