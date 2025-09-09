{
  pkgs,
  ...
}:
let
  catppuccin = import ../shared/catppuccin.nix;
in
pkgs.writeShellApplication {
  name = "skhd-mode-controller";
  text =
    # bash
    ''
      case "$1" in
      default)
        sketchybar  --bar           color=${catppuccin.frappe.base} \
                    --trigger mode_changed \
                    --set mode_indicator label="" \
                    --set mode_indicator drawing=off
        ;;
      resize)
        sketchybar  --bar           color=${catppuccin.frappe.green} \
                    --set mode_indicator drawing=on \
                    --set mode_indicator label="[RESIZE] HJKL:resize, arrows:move, space/esc:exit"
        ;;
      power)
        sketchybar  --bar           color=${catppuccin.frappe.red} \
                    --set mode_indicator drawing=on \
                    --set mode_indicator label="[POWER] L:lock, E:logout, S:suspend, H:hibernate, shift+R:reboot, shift+S:shutdown"
        ;;
      reload)
        sketchybar  --bar           color=${catppuccin.frappe.blue} \
                    --set mode_indicator drawing=on \
                    --set mode_indicator label="[RELOAD] 0:all, 1:yabai, 2:skhd, 3:sketchybar"
        ;;
      esac
    '';
}
