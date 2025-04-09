{
  home = rec {
    username = "alexander";
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";
  };
  home-manager.cli.git.git-sync.enable = true;
}
