{ config, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    theme = "Catppuccin-Frappe";
    settings = {
      adjust_column_width = -1;
      macos_option_as_alt = "yes";
      shell = "${config.programs.fish.package}/bin/fish";
    };
    shellIntegration.enableFishIntegration = true;
    keybindings = {
      "kitty_mod+enter" = "launch --cwd=current";
      "kitty_mod+t" = "new_tab_with_cwd";
    };
  };
}
