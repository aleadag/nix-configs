{
  config,
  lib,
  pkgs,
  sketchybar,
  ...
}:
let
  catppuccin = import ../catppuccin.nix;
in
pkgs.writeShellApplication {
  name = "skhd-mode-controller";
  runtimeInputs = [
    sketchybar
  ];
  text =
    # bash
    ''
      case "$1" in
      default)
        sketchybar  --bar           color=${catppuccin.frappe.base} \
                    --trigger mode_changed \
                    --set mode_indicator label="" \
                    --set system.yabai label.color=${catppuccin.frappe.text} \
                    --set front_app label.color=${catppuccin.frappe.text} \
                    --set mode_indicator drawing=off
        ;;
      stack)
        sketchybar  --bar           color=${catppuccin.frappe.teal} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${catppuccin.frappe.crust} \
                    --set front_app label.color=${catppuccin.frappe.crust} \
                    --set mode_indicator label="[STACK]"
        ;;
      display)
        sketchybar  --bar           color=${catppuccin.frappe.pink} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${catppuccin.frappe.crust} \
                    --set front_app label.color=${catppuccin.frappe.crust} \
                    --set mode_indicator label="[DISPLAY]"
        ;;
      window)
        sketchybar  --bar           color=${catppuccin.frappe.yellow} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${catppuccin.frappe.crust} \
                    --set front_app label.color=${catppuccin.frappe.crust} \
                    --set mode_indicator label="[WINDOW]"
        ;;
      resize)
        sketchybar  --bar           color=${catppuccin.frappe.green} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${catppuccin.frappe.crust} \
                    --set front_app label.color=${catppuccin.frappe.crust} \
                    --set mode_indicator label="[RESIZE]"
        ;;
      inst)
        sketchybar  --bar           color=${catppuccin.frappe.blue} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${catppuccin.frappe.crust} \
                    --set front_app label.color=${catppuccin.frappe.crust} \
                    --set mode_indicator label="[INSERT]"
        ;;
      reload)
        sketchybar  --bar           color=${catppuccin.frappe.red} \
                    --set system.yabai label.color=${catppuccin.frappe.crust} \
                    --set front_app label.color=${catppuccin.frappe.crust} \
                    --set mode_indicator drawing=on \
                    --set mode_indicator label="[RELOAD] 1:YABAI, 2:SKHD, 3:SKETCHYBAR, 0:ALL"
        ;;
      esac
    '';
}
