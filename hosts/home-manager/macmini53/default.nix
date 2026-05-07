{ config, lib, ... }:

{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  home-manager = {
    hostName = "macmini53";
    desktop.enable = true;
    dev.enable = false;
    kanata.enable = false;
    mihomo.enable = false;
    cc-connect = {
      enable = true;
      environmentFiles = [ config.sops.templates.cc-connect-env.path ];
      settings = {
        log.level = "info";
        projects = [
          {
            name = "lifewiki";
            agent = {
              type = "codex";
              options = {
                work_dir = "${config.home.homeDirectory}/Sync/Lifewiki";
                mode = "suggest";
              };
            };
            platforms = [
              {
                type = "feishu";
                options = {
                  app_id = "\${CC_CONNECT_FEISHU_APP_ID}";
                  app_secret = "\${CC_CONNECT_FEISHU_APP_SECRET}";
                };
              }
            ];
          }
        ];
      };
    };
    syncthing.enable = true;
    window-manager = {
      default.terminal = lib.getExe config.programs.kitty.package;
      enable = true;
      x11.enable = false;
    };
  };

  sops = {
    secrets = {
      "openclaw/feishu/main/app_id".sopsFile = ./secrets.yaml;
      "openclaw/feishu/main/app_secret".sopsFile = ./secrets.yaml;
    };

    templates.cc-connect-env.content = ''
      CC_CONNECT_FEISHU_APP_ID=${config.sops.placeholder."openclaw/feishu/main/app_id"}
      CC_CONNECT_FEISHU_APP_SECRET=${config.sops.placeholder."openclaw/feishu/main/app_secret"}
    '';
  };

  systemd.user.services.cc-connect.Unit = {
    Requires = [ "sops-nix.service" ];
    After = [ "sops-nix.service" ];
  };

  stylix.targets = {
    eog.enable = false;
    gnome.enable = false;
    gnome-text-editor.enable = false;
    gtk.enable = false;
  };

  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };
}
