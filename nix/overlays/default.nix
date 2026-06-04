# Keep this up to date with cabal.project
let
  tree-sitter-simple-repo = {
    url = "https://github.com/josephsumabat/tree-sitter-simple";
    sha256 = "sha256-Taje8q2fYZzA68sSt8f9/oCDdYjTWegfoYusQtmrz8A=";
    rev = "64f8a19b7e65a4a572770a92085f872caf212833";
    fetchSubmodules = true;
  };

in
  ghcVersion:
  self: super: {
    ghcVersion = ghcVersion;

    all-cabal-hashes =
        # Update revision to match required hackage
        super.fetchurl {
          url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/59b02844f778d7cc71d2a62ee05c37e17b396051.tar.gz";
          sha256 = "sha256-NUuQW59vzpXufNpAq4qwx5R0/2TwgDgtapjDSdIybhQ=";
    };

    haskellPackages = super.haskell.packages.${self.ghcVersion}.override {
      overrides = haskellSelf: haskellSuper: {
        tree-sitter-haskell =
          haskellSuper.callCabal2nix
          "tree-sitter-haskell" "${(super.fetchgit tree-sitter-simple-repo)}/tree-sitter-haskell" {};

        tree-sitter-simple =
          haskellSuper.callCabal2nix
          "tree-sitter-simple" "${(super.fetchgit tree-sitter-simple-repo)}/tree-sitter-simple" {};

        tree-sitter-ast =
          haskellSuper.callCabal2nix
          "tree-sitter-ast" "${(super.fetchgit tree-sitter-simple-repo)}/tree-sitter-ast" {};

        haskell-ast =
          self.haskellPackages.callCabal2nix
          "haskell-ast" "${(super.fetchgit tree-sitter-simple-repo)}/haskell-ast" {};

        text-range =
          haskellSuper.callCabal2nix
          "text-range" "${(super.fetchgit tree-sitter-simple-repo)}/text-range" {};

        tasty-expect = haskellSuper.callCabal2nix "tasty-expect" (super.fetchgit {
          url = "https://github.com/oberblastmeister/tasty-expect.git";
          sha256 = "sha256-KxunyEutnwLeynUimiIkRe5w/3IdmbD/9hGVi68UVfU=";
          rev = "ec14d702660c79a907e9c45812958cd0df0f036f";
        }) {};

      }
      # GHC 9.12+: nixpkgs already ships compatible versions (hiedb 0.7, lsp 2.7.0.1,
      # lsp-types 2.3.0.1, text-rope 0.3), so we use those defaults rather than the
      # older Hackage pins below, which do not build against GHC 9.12.
      // (if super.lib.hasPrefix "ghc912" self.ghcVersion
          then {
            hiedb = self.haskell.lib.dontCheck haskellSuper.hiedb;
            lsp = self.haskell.lib.doJailbreak haskellSuper.lsp;
            lsp-types = self.haskell.lib.doJailbreak haskellSuper.lsp-types;
            # optics 0.4.2.1's test suite fails to build on GHC 9.12 (3
            # AffineTraversal property tests); the library itself is fine.
            optics = self.haskell.lib.dontCheck haskellSuper.optics;
          }
          else {
            hiedb = self.haskell.lib.dontCheck (haskellSuper.callHackage "hiedb" "0.6.0.1" {});
            text-rope = haskellSuper.callHackage "text-rope" "0.3" {};

            lsp-types = self.haskell.lib.doJailbreak (haskellSuper.callHackage "lsp-types" "2.3.0.0" {});
            lsp = self.haskell.lib.doJailbreak (haskellSuper.callHackage "lsp" "2.7.0.0" {});
          });
    };
  }
