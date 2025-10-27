{ lib, ... }:
{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";

    # Set XDG_RUNTIME_DIR for systemd user services in SSH sessions
    sessionVariables = {
      XDG_RUNTIME_DIR = "/run/user/1001";
    };
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
