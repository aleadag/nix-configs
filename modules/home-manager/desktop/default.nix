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
    ./ghostty
    ./im.nix
    ./kitty.nix
    ./mpv
    ./obsidian
    ./wechat
    ./wps.nix
  ];

  options.home-manager.desktop = {
    enable = lib.mkEnableOption "desktop config";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        audacious
        feishu
        libreoffice-fresh
        (mcomix.override {
          unrarSupport = true;
        })
      ]
      ++ (lib.optionals stdenv.hostPlatform.isLinux [
        telegram-desktop
      ]);
  };
}
