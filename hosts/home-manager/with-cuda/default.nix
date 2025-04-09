{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "24.05";
  };

  home-manager = {
    desktop = {
      nixgl.enable = true;
      theme.enable = true;
    };
    editor = {
      enable = false;
      neovim.enable = true;
    };
    gui.enable = false;
  };

  targets.genericLinux.enable = true;
}
