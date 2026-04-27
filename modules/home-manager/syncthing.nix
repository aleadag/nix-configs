{
  config,
  lib,
  ...
}:
let
  cfg = config.home-manager.syncthing;
  inherit (config.home-manager) hostName;
in
{
  options.home-manager.syncthing = {
    enable = lib.mkEnableOption "Syncthing config";

    guiPort = lib.mkOption {
      type = lib.types.port;
      default = 8384;
      description = "Port for the Syncthing web UI on localhost.";
    };
  };

  config = lib.mkIf cfg.enable (
    let
      devices = {
        macmini53.id = "RCNNMVJ-B2NUZAH-FIZ5KFG-QJF2S2Q-YSDVOGF-7C62QUJ-4J7CYMY-EOCR5AB";
        mbx.id = "SBCCPEE-3TV6WBK-TBSXAQD-6JCZQ6E-JKUJ7OH-QZL462Y-GRAEYZE-FATVIQ2";
        pvg1.id = "L33VADA-RGQEHMK-F5EYEKX-L3RSW3O-IH2WCTQ-FX6FS5F-2A7GTMP-XY5A5QU";
        t0.id = "AULBO4N-7IFZFNV-4JAIL6G-5XL3KFY-WWR5BEH-UXOPALL-4XK5CE6-AORWDQL";
      };
      allDevices = builtins.attrNames devices;
      passDevices = [
        "mbx"
        "t0"
      ];
    in
    {
      services.syncthing = {
        enable = true;
        guiAddress = "127.0.0.1:${toString cfg.guiPort}";
        settings = {
          inherit devices;
          folders = {
            Sync = {
              path = "~/Sync";
              devices = allDevices;
              copyOwnershipFromParent = true;
            };
          }
          // lib.optionalAttrs (config.home-manager.cli.pass.enable && builtins.elem hostName passDevices) {
            Pass = {
              path = "~/Pass";
              devices = passDevices;
              copyOwnershipFromParent = true;
            };
          };
          options = {
            relaysEnabled = true;
            localAnnounceEnabled = true;
            # https://docs.syncthing.net/users/config.html#config-option-options.uraccepted
            urAccepted = -1;
          };
        };
      };
    }
  );
}
