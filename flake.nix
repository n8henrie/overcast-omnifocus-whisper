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
              ffmpeg
              libxml2
              self.outputs.packages.${system}.whisper
            ];
            text = ''
              # shellcheck disable=1091
              source ${pkgs.cacert}/nix-support/setup-hook

              ${builtins.readFile ./run.sh}
            '';
          };

          whisper = pkgs.callPackage ./whisper { };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.${name}}/bin/${name}";
        };
      }
    )
    // {
      homeManagerModules.default =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          cfg = config.services.${name};
        in
        {
          options.services.${name} = with lib; {
            enable = mkEnableOption name;
            schedule = mkOption {
              type =
                with types;
                submodule {
                  options = {
                    Hour = mkOption {
                      type = ints.between 0 23;
                      description = "Hour of day to run";
                      default = 1;
                    };
                    Minute = mkOption {
                      type = ints.between 0 59;
                      description = "Minute of the hour to run";
                      default = 5;
                    };
                  };
                };
              default = { };
            };
            stdout = mkOption {
              type = types.str;
              default = "${config.homeDirectory}/git/${name}/stdout.log";
            };
            stderr = mkOption {
              type = types.str;
              default = "${config.homeDirectory}/git/${name}/stderr.log";
            };
          };

          config = {
            launchd.agents.${name} = {
              enable = true;
              config = {
                Label = "com.n8henrie.${name}";
                ProgramArguments = [ "${self.outputs.packages.${pkgs.system}.${name}}/bin/${name}" ];
                StartCalendarInterval = [ { inherit (cfg.schedule) Hour Minute; } ];
                StandardOutPath = cfg.stdout;
                StandardErrorPath = cfg.stderr;
              };
            };
          };
        };
    };
}
