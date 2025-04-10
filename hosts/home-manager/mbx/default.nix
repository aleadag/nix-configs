{
  home-manager = {
    cli.git.git-sync.enable = true;
    desktop = {
      enable = true;
      x11.enable = false;
    };
  };

  targets.genericLinux.enable = true;
}
