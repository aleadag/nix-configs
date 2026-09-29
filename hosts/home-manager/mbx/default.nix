{
  home.stateVersion = "26.11";

  home-manager = {
    hostName = "mbx";
    desktop.enable = true;
    syncthing.enable = true;
    window-manager.enable = true;
  };

  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };
}
