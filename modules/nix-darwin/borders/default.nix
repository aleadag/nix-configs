{
  config,
  lib,
  ...
}:
let
  cfg = config.nix-darwin.borders;
in
{
  options.nix-darwin.borders.enable = lib.mkEnableOption "borders config" // {
    default = config.nix-darwin.yabai.enable;
  };

  config = lib.mkIf cfg.enable {
    services.jankyborders = {
      enable = true;
      style = "round";
      width = 6.0;
      hidpi = false;
    };
  };
}
