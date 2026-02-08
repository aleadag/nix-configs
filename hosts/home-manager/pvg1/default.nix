{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };

  home-manager = {
    dev.enable = true;
    editor = {
      enable = false;
      neovim.enable = true;
    };
    gui.enable = false;
    nix.niks3.gc.enable = true;
  };

  targets.genericLinux.enable = true;
}
