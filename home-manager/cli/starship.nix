{ config, flake, lib, ... }:
{
  options.home-manager.cli.starship.enable = lib.mkEnableOption "Starship config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.starship.enable {
    programs.starship = {
      enable = true;

      settings = {
        # Other config here
        format = "$all"; # Remove this line to disable the default prompt format
        palette = "catppuccin_${config.home-manager.desktop.theme.flavor}";
        directory = {
          truncation_length = 4;
          style = "bold lavender";
        };
        # displays the exit code of the previous command
        status.disabled = false;
      } // builtins.fromTOML (builtins.readFile
        "${flake.inputs.catppuccin-starship}/themes/${config.home-manager.desktop.theme.flavor}.toml");
    };
  };
}
