{ config, lib, pkgs, ... }:
{
  options.home-manager.gui.enable = lib.mkEnableOption "GUI related tools" // {
    default = true;
  };

  config = lib.mkIf config.home-manager.gui.enable {
    home.packages = with pkgs; [
      keepassxc
      anki-bin
    ];
  };
}
