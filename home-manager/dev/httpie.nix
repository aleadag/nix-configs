{ config, lib, pkgs, ... }:
{
  options.home-manager.dev.httpie.enable = lib.mkEnableOption "Httpie config" // {
    default = config.home-manager.dev.enable;
  };

  config = lib.mkIf config.home-manager.dev.httpie.enable {
    home.packages = with pkgs; [ httpie ];

    xdg.configFile."httpie/config.json".text =
      let configData = { default_options = [ "--style=paraiso-dark" ]; };
      in
      builtins.toJSON (configData);
  };
}
