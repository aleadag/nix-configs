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
      feishuAccounts = [
        "main"
        "aurora"
        "ticos"
        "zsflow"
      ];
      agents = [
        {
          id = "main";
          feishuAccount = "main";
        }
        {
          id = "aurora";
          feishuAccount = "aurora";
        }
        {
          id = "ticos";
          feishuAccount = "ticos";
        }
        {
          id = "zsflow";
          feishuAccount = "zsflow";
        }
      ];
    };
    syncthing.enable = true;
  };

  stylix.targets = {
    eog.enable = false;
    gnome.enable = false;
    gnome-text-editor.enable = false;
    gtk.enable = false;
  };

  targets.genericLinux.enable = true;
}
