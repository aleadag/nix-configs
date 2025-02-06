{
  config,
  flake,
  lib,
  ...
}:

{
  options.home-manager.darwin.bing-wallpaper.enable = lib.mkEnableOption "Bing wallpaper config" // {
    default = config.home-manager.darwin.enable;
  };

  config = lib.mkIf config.home-manager.darwin.bing-wallpaper.enable {
    launchd.agents."bing-wallpaper" = {
      enable = true;
      config = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "${builtins.getAttr "bing-wallpaper-mac" flake.inputs}/bing-wallpaper.sh -r UHD"
        ];
        OnDemand = true;
        RunAtLoad = true;
        StartInterval = 1800;
      };
    };
  };
}
