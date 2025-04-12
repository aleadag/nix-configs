{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.home-manager.cli.starship.enable = lib.mkEnableOption "Starship config" // {
    default = (pkgs.stdenv.hostPlatform.system != "aarch64-linux") && config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.starship.enable {
    programs.starship = {
      enable = true;

      settings = {
        # Other config here
        format = "$all"; # Remove this line to disable the default prompt format
        directory = {
          truncation_length = 4;
          style = "bold lavender";
        };
        # displays the exit code of the previous command
        status.disabled = false;
      };
    };
  };
}
