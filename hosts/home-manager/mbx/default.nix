{
  home.stateVersion = "25.05";

  home-manager = {
    cli.git.git-sync.enable = true;
    desktop.enable = true;
    window-manager.enable = true;
  };

  targets.genericLinux.enable = true;
}
