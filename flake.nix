{
  description = "mahatracker.org, built from Typst";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]
        (system: f nixpkgs.legacyPackages.${system});
      tools = pkgs: [ pkgs.typst pkgs.just ];
    in
    {
      # nix build  ->  result/index.html
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          name = "mahatracker-site";
          src = ./.;
          nativeBuildInputs = tools pkgs;
          buildPhase = ''
            export HOME=$TMPDIR
            just build
          '';
          installPhase = "cp -r _site $out";
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = tools pkgs; };
      });
    };
}
