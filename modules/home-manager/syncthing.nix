{
  config,
  lib,
  ...
}:
let
  cfg = config.home-manager.syncthing;
in
{
  options.home-manager.syncthing.enable = lib.mkEnableOption "Syncthing config";

  config = lib.mkIf cfg.enable (
    let
      devices = {
        mbx.id = "SBCCPEE-3TV6WBK-TBSXAQD-6JCZQ6E-JKUJ7OH-QZL462Y-GRAEYZE-FATVIQ2";
        pvg1.id = "L33VADA-RGQEHMK-F5EYEKX-L3RSW3O-IH2WCTQ-FX6FS5F-2A7GTMP-XY5A5QU";
        t0.id = "AULBO4N-7IFZFNV-4JAIL6G-5XL3KFY-WWR5BEH-UXOPALL-4XK5CE6-AORWDQL";
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
              ignorePatterns = [
                ".obsidian"
                ".DS_Store"
              ];
              ignorePerms = true;
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
