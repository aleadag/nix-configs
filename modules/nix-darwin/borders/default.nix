{
  config,
  lib,
  ...
}:
let
  cfg = config.nix-darwin.borders;
  catppuccin = import ../shared/catppuccin.nix;
in
{
  options.nix-darwin.borders.enable = lib.mkEnableOption "borders config" // {
    default = config.nix-darwin.yabai.enable;
  };

  config = lib.mkIf cfg.enable {
    services.jankyborders = {
      enable = true;
      active_color = catppuccin.frappe.mauve;
      inactive_color = catppuccin.frappe.surface1;
      style = "round";
      width = 6.0;
      hidpi = false;
    };
  };
}
