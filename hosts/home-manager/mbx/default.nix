{
  home = rec {
    username = "awang";
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";
  };

  home-manager = {
    cli.git.git-sync.enable = true;
    desktop.enable = true;
  };

  targets.genericLinux.enable = true;
}
