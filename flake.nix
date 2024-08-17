{
  description = "Basic template for nix + rust";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    { self, nixpkgs }:
    let
      name = "overcast-omnifocus-whisper";
      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      eachSystem =
        with nixpkgs.lib;
        f: foldAttrs mergeAttrs { } (map (s: mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
    in
    eachSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          default = self.packages.${system}.${name};
          ${name} = (pkgs.writeScriptBin name (builtins.readFile ./${name}.js)).overrideAttrs (old: {
            buildCommand =
              old.buildCommand
              + ''
                substituteInPlace $target \
                  --replace-fail "\''${pwd}/run.sh" ${
                    self.outputs.packages.${system}.run-whisper
                  }/bin/overcast-omnifocus-whisper-run.sh

                eval "$checkPhase"
              '';
          });
          run-whisper = pkgs.writeShellApplication {
            name = "overcast-omnifocus-whisper-run.sh";
            runtimeInputs = with pkgs; [
              curl
              cacert
              ffmpeg
              libxml2
              self.outputs.packages.${system}.whisper
            ];
            text = builtins.readFile ./run.sh;
          };

          whisper = pkgs.callPackage ./whisper { };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.${name}}/bin/${name}";
        };
      }
    );
}
