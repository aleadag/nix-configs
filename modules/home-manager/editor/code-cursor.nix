{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.home-manager.editor.code-cursor.enable = lib.mkEnableOption "Enable code-cursor" // {
    default = config.home-manager.editor.enable;
  };

  config = lib.mkIf config.home-manager.editor.code-cursor.enable {
    home.packages = [ pkgs.code-cursor ];

    # Waiting for PR to be merged:
    # https://github.com/nix-community/home-manager/pull/6417
    # programs.vscode = {
    #   enable = true;
    #   package = pkgs.code-cursor;
    #   extensions = with pkgs.vscode-extensions; [
    #     # General
    #     vscodevim.vim # Vim (https://marketplace.visualstudio.com/items?itemName=vscodevim.vim)
    #     arrterian.nix-env-selector # Nix Env Selector (https://marketplace.visualstudio.com/items?itemName=arrterian.nix-env-selector)
    #
    #     # Git
    #     github.vscode-pull-request-github # GitHub Pull Requests (https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-pull-request-github)
    #
    #     # Languages
    #
    #     # Frontend
    #
    #     # Themes
    #     catppuccin.catppuccin-vsc # Catppuccin theme (https://marketplace.visualstudio.com/items?itemName=Catppuccin.catppuccin-vsc)
    #   ];
    # };
  };
}
