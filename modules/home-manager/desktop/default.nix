{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  cfg = config.home-manager.desktop;
in
{
  imports = [
    ./chromium.nix
    ./firefox.nix
    ./im.nix
    ./kitty.nix
    ./mpv
    ./nixgl.nix
    ./xterm.nix
  ];

  options.home-manager.desktop = {
    enable = lib.mkEnableOption "desktop config" // {
      default = osConfig.nixos.desktop.enable or false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      android-file-transfer
      audacious
      # if installed by yay, fcitx5 doesn't work!
      code-cursor
      libreoffice-fresh
      (mcomix.override {
        unrarSupport = true;
        pdfSupport = false;
      })
      wechat-uos
    ];
  };
}
