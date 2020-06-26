let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    overlays = [
      (_: _: { inherit sources; })
    ];
  };
in
with pkgs;
mkShell {
  buildInputs = with nodePackages;
    [
      nodejs
      purescript bower pulp
      haskell.compiler.ghcjs86 closurecompiler
    ];
}
