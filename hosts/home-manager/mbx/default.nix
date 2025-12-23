{
  home.stateVersion = "25.05";

  home-manager = {
    desktop.enable = true;
    syncthing.enable = true;
    window-manager.enable = true;
  };

  targets.genericLinux.enable = true;
}
