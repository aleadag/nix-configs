{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.home-manager.cli.starship.enable = lib.mkEnableOption "Starship config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.starship.enable {
    programs.starship = {
      enable = true;

      settings = {
        add_newline = false;

        custom.jj = {
          description = "Show Jujutsu info";
          when = "jj-starship detect";
          shell = [ (lib.getExe pkgs.jj-starship) ];
          format = "$output ";
        };
      };
    };
  };
}
