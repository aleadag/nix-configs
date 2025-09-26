{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop;
in
{
  imports = [
    ./chromium.nix
    ./firefox.nix
    ./fonts
    ./im.nix
    ./kitty.nix
    ./mpv
    ./nixgl.nix
  ];

  options.home-manager.desktop = {
    enable = lib.mkEnableOption "desktop config";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      android-file-transfer
      audacious
      libreoffice-fresh
      (mcomix.override {
        unrarSupport = true;
        pdfSupport = false;
      })
      wechat-uos
    ];
  };
}
