{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  home-manager = {
    hostName = "macmini53";
    desktop.enable = true;
    mihomo.enable = false;
    syncthing.enable = false;
    window-manager = {
      enable = true;
      x11.enable = false;
    };
  };

  stylix.targets = {
    eog.enable = false;
    gnome.enable = false;
    gnome-text-editor.enable = false;
    gtk.enable = false;
  };

  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };
}
