{
  flake,
  lib,
  options,
  pkgs,
  ...
}:
{
  config = {
    stylix = {
      enable = true;
      base16Scheme = "${flake.inputs.tinted-schemes}/base16/catppuccin-frappe.yaml";
      polarity = "dark";

      # Wallpaper configuration
      image = "${pkgs.pop-wallpapers}/share/backgrounds/pop/jasper-van-der-meij-97274-edit.jpg";

      # Font configuration
      fonts = rec {
        monospace = {
          package = pkgs.nerd-fonts.hack;
          name = "Hack Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.roboto;
          name = "Roboto";
        };
        serif = sansSerif;
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };
    }
    // lib.optionalAttrs (options ? stylix.homeManagerIntegration) {
      # NixOS-specific: disable home-manager integration
      homeManagerIntegration.autoImport = false;
    };
  };
}
