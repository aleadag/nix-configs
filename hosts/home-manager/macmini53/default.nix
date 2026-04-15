{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  home-manager = {
    hostName = "macmini53";
    desktop.enable = true;
    kanata.enable = false;
    mihomo.enable = false;
    openclaw = {
      enable = true;
      sopsFile = ./secrets.yaml;
    };
    syncthing.enable = true;
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
