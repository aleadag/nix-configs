{
  pkgs,
  lib,
  config,
  ...
}: {
  options.home-manager.editor.code-cursor.enable = lib.mkEnableOption "Enable code-cursor" // {
    default = config.home-manager.editor.enable;
  };

  config = lib.mkIf config.home-manager.editor.code-cursor.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.code-cursor;
      # Cannot set extension for now because of extensionDir is unknown!
      # extensions = with pkgs.vscode-extensions; [
      #   # General
      #   vscodevim.vim # Vim (https://marketplace.visualstudio.com/items?itemName=vscodevim.vim)
      #   arrterian.nix-env-selector # Nix Env Selector (https://marketplace.visualstudio.com/items?itemName=arrterian.nix-env-selector)
      #
      #   # Git
      #   github.vscode-pull-request-github # GitHub Pull Requests (https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-pull-request-github)
      #
      #   # Languages
      #
      #   # Frontend
      #
      #   # Themes
      #   catppuccin.catppuccin-vsc # Catppuccin theme (https://marketplace.visualstudio.com/items?itemName=Catppuccin.catppuccin-vsc)
      # ];
    };
  };
}
