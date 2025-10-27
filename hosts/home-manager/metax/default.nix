{ lib, ... }:
{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };

  home-manager = {
    dev.enable = true;
    editor = {
      enable = false;
      neovim.enable = true;
    };
    gui.enable = false;
  };

  # Disable dconf since we don't have GUI and it requires D-Bus
  dconf.enable = lib.mkForce false;

  targets.genericLinux.enable = true;
}
