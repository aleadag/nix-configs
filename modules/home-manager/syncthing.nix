{
  config,
  flake,
  lib,
  ...
}:
let
  cfg = config.home-manager.syncthing;
in
{
  options.home-manager.syncthing.enable = lib.mkEnableOption "Syncthing config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable (
    let
      devices = {
        mbx = {
          id = "SBCCPEE-3TV6WBK-TBSXAQD-6JCZQ6E-JKUJ7OH-QZL462Y-GRAEYZE-FATVIQ2";
        };
      };
      allDevices = builtins.attrNames devices;
    in
    {
      services.syncthing = {
        enable = true;
        settings = {
          inherit devices;
          folders = {
            sync = {
              path = "~/sync";
              devices = allDevices;
              ignorePerms = true;
              copyOwnershipFromParent = true;
            };
          };
          options = {
            relaysEnabled = true;
            localAnnounceEnabled = true;
          };
        };
      };
    }
  );
}
