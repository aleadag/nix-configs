{
  home = rec {
    username = "alexaw";
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  home-manager = {
    cli.pass.enable = false;
    dev.node.enable = false;
    desktop.mpv.enable = false;
    editor = {
      enable = false;
      neovim.enable = true;
    };
    gui.enable = false;
    mihomo.enable = false;
    openclaw = {
      enable = true;
      sopsFile = ./secrets.yaml;
    };
    syncthing.enable = false;
  };

  targets.genericLinux.enable = true;
}
