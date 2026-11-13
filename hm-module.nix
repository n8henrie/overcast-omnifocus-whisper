flake:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  name = "overcast-omnifocus-whisper";
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
      default = "${config.home.homeDirectory}/git/${name}/stdout.log";
    };
    stderr = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/git/${name}/stderr.log";
    };
  };

  config.launchd.agents.${name} = {
    enable = true;
    config = {
      Label = "com.n8henrie.${name}";
      ProgramArguments = [
        (lib.getExe flake.outputs.packages.${pkgs.stdenv.hostPlatform.system}.${name})
      ];
      StartCalendarInterval = [ { inherit (cfg.schedule) Hour Minute; } ];
      StandardOutPath = cfg.stdout;
      StandardErrorPath = cfg.stderr;
    };
  };
}
