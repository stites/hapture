let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    overlays = [
      (_: _: { inherit sources; })
    ];
  };
in
pkgs.mkShell {
  buildInputs = with pkgs.nodePackages; [ pkgs.nodejs pkgs.purescript bower pulp ];
}
