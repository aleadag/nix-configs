{ config, lib, ... }:

{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "26.11";
  };

  home-manager = {
    hostName = "macmini53";
    desktop.enable = true;
    dev.enable = false;
    kanata.enable = false;
    mihomo.enable = false;
    syncthing.enable = true;
    window-manager = {
      default.terminal = lib.getExe config.programs.kitty.package;
      enable = true;
    };
  };

  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };
}
