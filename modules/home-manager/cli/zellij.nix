{ config, lib, ... }:
{

  options.home-manager.cli.zellij.enable = lib.mkEnableOption "Zellij config" // {
    default = false; # config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.zellij.enable {
    programs.zellij = {
      enable = true;
    };

    # NOTE: the module only supports YAML config which is deprecated
    home.file.zellij = {
      target = ".config/zellij/config.kdl";
      text = # kdl
        ''
          simplified_ui true
          default_layout "compact"
        '';
    };
  };
}
