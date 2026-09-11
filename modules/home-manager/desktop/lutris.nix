{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.desktop.lutris;
  isSupported = pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64;
in
{
  options.home-manager.desktop.lutris = {
    enable = lib.mkEnableOption "Lutris gaming platform";
  };

  config = lib.mkIf (cfg.enable && isSupported) {
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/lutris" = "net.lutris.Lutris.desktop";
    };

    programs.lutris = {
      enable = true;
      package = pkgs.lutris.override {
        extraLibraries = pkgs: [
          pkgs.gamemode.lib
        ];
      };
      winePackages = [ pkgs.wineWow64Packages.staging ];
      defaultWinePackage = pkgs.wineWow64Packages.staging;
      extraPackages = with pkgs; [
        cabextract
        gamemode
        gamescope
        mangohud
        p7zip
        procps
        unzip
        vulkan-tools
        winetricks
        zenity
      ];
      runners = {
        wine.settings = {
          system = {
            gamemode = false;
          };
        };
      };
    };
  };
}
