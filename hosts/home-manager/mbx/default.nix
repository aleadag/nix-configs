{
  home.stateVersion = "26.05";

  home-manager = {
    hostName = "mbx";
    desktop.enable = true;
    syncthing.enable = true;
    window-manager.enable = true;
    window-manager.x11.enable = false;
  };

  targets.genericLinux.enable = true;
}
