{
  config,
  lib,
  ...
}:

{
  options.home-manager.desktop.chromium.enable = lib.mkEnableOption "Chromium config" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.chromium.enable {
    programs.chromium = {
      enable = true;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } # vimium-c
      ];
    };
  };
}
