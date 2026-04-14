{
  config,
  lib,
  ...
}:
let
  cfg = config.home-manager.syncthing;
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
        alexaw.id = "TODO-REPLACE-WITH-ALEXAW-SYNCTHING-DEVICE-ID";
        mbx.id = "SBCCPEE-3TV6WBK-TBSXAQD-6JCZQ6E-JKUJ7OH-QZL462Y-GRAEYZE-FATVIQ2";
        pvg1.id = "L33VADA-RGQEHMK-F5EYEKX-L3RSW3O-IH2WCTQ-FX6FS5F-2A7GTMP-XY5A5QU";
        t0.id = "AULBO4N-7IFZFNV-4JAIL6G-5XL3KFY-WWR5BEH-UXOPALL-4XK5CE6-AORWDQL";
      };
      syncDevices = [
        "mbx"
        "pvg1"
        "t0"
      ];
      lifewikiDevices = syncDevices ++ [ "alexaw" ];
    in
    {
      services.syncthing = {
        enable = true;
        guiAddress = "127.0.0.1:${toString cfg.guiPort}";
        settings = {
          inherit devices;
          folders = {
            sync = {
              path = "~/sync";
              devices = syncDevices;
              copyOwnershipFromParent = true;
            };
            lifewiki = {
              path = "~/Lifewiki";
              devices = lifewikiDevices;
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
