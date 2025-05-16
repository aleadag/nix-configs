{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";
  };

  home-manager = {
    editor = {
      enable = false;
      neovim.enable = true;
    };
    gui.enable = false;
  };

  targets.genericLinux.enable = true;
}
