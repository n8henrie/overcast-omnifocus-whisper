{
  description = "Basic template for nix + rust";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      name = "overcast-omnifocus-whisper";
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        default = self.packages.${system}.${name};
        ${name} = pkgs.callPackage ./package.nix {
          inherit (self.outputs.packages.${system}) whisper;
        } "overcast-omnifocus-whisper";
        whisper = pkgs.callPackage ./whisper/package.nix { };
      };

      apps.${system}.default = {
        type = "app";
        program = nixpkgs.lib.getExe self.packages.${system}.${name};
        meta.description = "run ${name}";
      };

      checks.${system} = self.packages.${system} // {
        lint =
          pkgs.runCommand "check-${name}"
            {
              src = nixpkgs.lib.cleanSource ./.;
              nativeBuildInputs = with pkgs; [
                deadnix
                nixfmt
                statix
              ];
            }
            ''
              deadnix .
              statix check
              find . -name '*.nix' -exec nixfmt --check {} +
              touch $out
            '';
      };

      homeManagerModules.default = import ./hm-module.nix self;
    };
}
